---
layout: single
toc: true
---

## 1 思路

自定义一个拦截器，继承`org.apache.tomcat.jdbc.pool.interceptor.StatementCache`，重写其语句缓存方法`cacheStatement`，在此过程中打印带参数的SQL语句

## 2 实践

新建一个拦截器，继承`org.apache.tomcat.jdbc.pool.interceptor.StatementCache`，如下：

```java
@Slf4j
public class MyJdbcInterceptor extends StatementCache {

    /**
     * 重写cacheStatement方法，打印statementProxy
     */
    @Override
    public boolean cacheStatement(CachedStatement proxy) {
        log.info(proxy.getDelegate().toString()); //注意点1
        return super.cacheStatement(proxy);
    }
}
```

- 注意点1 - proxy.getDelegate().toString()即可打印带参数的SQL

在项目设置中设置监听器，在`application.properties`文件中添加：

```properties
spring.datasource.tomcat.jdbc-interceptors=org.cdjavaer.learning.mybatis.interceptor.MyJdbcInterceptor
```

## 3 参考

- http://wiki.jikexueyuan.com/project/tomcat/tomcat-jdbc-pool.html
- https://stackoverflow.com/questions/15527791/tomcat-connection-pooling-with-prepared-statement-cache
- http://tomcat.apache.org/tomcat-8.5-doc/jdbc-pool.html#org.apache.tomcat.jdbc.pool.interceptor.StatementCache
