---
title: "Spring StateMachine踩坑"
date: 2022-05-14T19:23:13+08:00
categories: ["tech"]
---

最近做的客户管理项目，其中客户的开户、合同变更、合同续签功能涉及到走审批（基于公司采购的致远OA系统），业务上有这些需求：

1. 某个确定的功能（比如客户开户）由某些确定的状态、动作组成
2. 某些状态流转取决于审批结果是通过还是拒绝
3. 某个状态允许重新流转

为了实现这些需求，可以简单粗暴if-else硬编码来实现（画面太美），为了代码的可维护性，团队考虑引入某些开源框架来优化，先后调研了工作流框架Flowable、状态机框架[Spring StateMachine](https://docs.spring.io/spring-statemachine/docs/current/reference/)，基于学习成本和运维成本考虑，决定引入更加轻量的Spring StateMachine。如何快速入手可以参考官网，先介绍一下我们的实践的宏观结构。



