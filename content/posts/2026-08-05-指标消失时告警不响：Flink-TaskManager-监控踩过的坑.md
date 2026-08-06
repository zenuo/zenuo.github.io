---
title: 🕳指标消失时告警不响：Flink TaskManager 监控踩过的坑
date: 2026-08-05T00:00:00+0800
tags: [tech]
---

Prometheus + Grafana 盯 Flink，常见做法是看 JobManager 上报的已注册 TaskManager 数：

```promql
sum by (app) (
  flink_jobmanager_numRegisteredTaskManagers{app=~"team-a-.*|stream-.*"}
)
```

告警意图很简单：某个作业的 TM 数小于 1 就响。你大概指望它覆盖两种情况——JobManager 还在但 TM 为 `0`，以及作业整挂、指标不再上报。

第一种好办。第二种很容易栽：线不是掉到 0，是直接断了。

## 现象

Dashboard 上某条 `app` 长时间稳在 `1`，某时刻后曲线戛然而止，后面一段一个点都没有。规则大致长这样：

| 步骤 | 配置 | 作用 |
|------|------|------|
| A | 上面那段 PromQL（Range） | 按 `app` 聚合 TM 数 |
| B | Reduce：`Last`，非数值换成 `0` | 取最近值 |
| C | Threshold：`IS BELOW 1` | 小于 1 就告 |

作业挂了，指标没了，告警却一声不吭。我第一次撞上这事，还以为是自己把阈值写反了。

## 消失 ≠ 变成 0

Grafana 的「非数值替换为 0」只管一件事：序列还在，个别点是 NaN 或 null。

进程没了之后，Prometheus 不再更新这条时间序列，查询结果里整条 series 都不存在。于是 Query A 对这个 `app` 返回空，Reduce 没有可归约的对象，Threshold 无从比较。多维告警下，这个维度往往直接从评估结果里消失，而不是变成「值为 0、正在告警」。

同一次查询里只要还有别的正常作业，「No data → Alerting」也帮不上忙——整次评估并不算无数据。

结论有点扎心：要告「挂掉」，必须在查询层把「指标缺失」显式变成 `0`（或别的可判定值）。光靠 Grafana 的空值替换不够。

## 临时方案：用历史标签补 0

```promql
sum by (app) (
  flink_jobmanager_numRegisteredTaskManagers{app=~"team-a-.*|stream-.*"}
)
or
(
  sum by (app) (
    flink_jobmanager_numRegisteredTaskManagers{app=~"team-a-.*|stream-.*"}
    offset 10m
  ) * 0
)
```

正常有 TM 时左侧有当前值；JM 在、TM = 0 时左侧就是 `0`，能告；刚挂、指标消失时左侧空，右侧用大约 10 分钟前还存在的 `app` 补出 `0`，也能告。

`offset` 比评估周期稍大一点就行，常见 `5m`～`15m`。后面照旧 Reduce `Last` + `IS BELOW 1`。

但这招有个讨厌的副作用：挂久了会「假恢复」。`offset` 窗口一过，左右两侧都查不到这个 `app`，维度再次消失，告警可能自己好了——作业其实还趴着。要一直告到真正起来，短 `offset` 撑不住。

## 更稳的做法：期望作业清单

告警维度应该由「期望在线的作业」决定，而不是「当前碰巧还在报数的作业」。

查询里可以直接写死：

```promql
sum by (app) (
  flink_jobmanager_numRegisteredTaskManagers{app=~"team-a-.*|stream-.*"}
)
or on (app)
(
  label_replace(vector(0), "app", "stream-order-job", "", "")
  or label_replace(vector(0), "app", "team-a-settle-job", "", "")
  or label_replace(vector(0), "app", "team-a-recommend-job", "", "")
  # 列出所有应在线的 app
)
```

左侧有值就正常；左侧空、右侧补 `0`，就会持续 `IS BELOW 1`；作业恢复后左侧回来，告警解除。记得：作业主动下线时从清单删掉，否则会一直误报。

清单变长之后，别继续往查询里堆。用 recording rule、textfile，或单独 exporter 产出：

```text
expected_flink_app{app="stream-order-job"} 1
expected_flink_app{app="team-a-settle-job"} 1
```

然后：

```promql
sum by (app) (
  flink_jobmanager_numRegisteredTaskManagers{app=~"team-a-.*|stream-.*"}
)
or on (app)
(expected_flink_app{app=~"team-a-.*|stream-.*"} * 0)
```

清单跟部署/发布对齐时，这是我见过最省心、也最能做到「告到恢复」的办法。

### 折中：用长窗口记住曾经出现过的 app

```promql
sum by (app) (
  flink_jobmanager_numRegisteredTaskManagers{app=~"team-a-.*|stream-.*"}
)
or
(
  sum by (app) (
    last_over_time(
      flink_jobmanager_numRegisteredTaskManagers{app=~"team-a-.*|stream-.*"}[7d]
    )
  ) * 0
)
```

在保留时间 ≥ 窗口的前提下，曾经报过、现在没了的 `app` 会以 `0` 继续参与告警。代价也很清楚：窗口一过仍会丢维度；从没上线过的作业记不住；窗口越大查询越贵。过渡期能用，别当最终答案。

## 两个容易误解的配置

**Reduce「非数值 → 0」** 解决的是空点，不是空序列。指标整段消失时它无效。

**No data = Alerting** 只在整次查询完全无数据时有用。多作业场景挂一个、活一堆，通常不会触发。

## 怎么选

| 目标 | 建议 |
|------|------|
| 先尽快盖住「刚挂掉」 | `or … offset … * 0` |
| 必须告到恢复 | 期望清单（`label_replace` / `expected_*`） |
| 过渡、能接受最长宕机窗口 | `last_over_time([Nd]) * 0` |
| 跑在 Kubernetes 上 | 另加 Deployment/Pod 存活告警，跟指标告警互补 |

Flink 作业挂掉后，相关指标经常是消失，不是置零。告警如果只写「当前值 < 1」，序列一缺失，这个维度根本进不了评估。想把「没有数据」变成可告警状态，就在 PromQL 里显式补零；还要持续告到恢复，就用期望作业清单把维度钉住——短时历史和 Grafana 空值替换，都只是权宜之计。
