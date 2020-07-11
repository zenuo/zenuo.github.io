---
title: "Spring框架：注入AspectJ切面"
date: 2017-11-01T17:36:32+08:00
draft: false
---

虽然Spring AOP能够满足许多应用的切面需求，但是与AspectJ相比，Spring AOP 是一个功能**比较弱**的AOP解决方案。AspectJ提供了Spring AOP所不能支持的许多类型的切点。

例如，当我们需要在创建对象时应用通知，构造器切点就非常方便。不像某些其他面向对象语言中的构造器，Java构造器不同于其他的正常方法。这使得Spring基于代理的AOP无法把通知应用于对象的创建过程。

对于大部分功能来讲，AspectJ切面与Spring是相互独立的。虽然它们可以织入到任意的Java应用中，这也包括了Spring应用，但是在应用AspectJ切面时几乎不会涉及到Spring。

但是精心设计且有意义的切面很可能依赖其他类来完成它们的工作。如果在执行通知时，切面依赖于一个或多个类，我们可以在切面内部实例化这些协作的对象。但更好的方式是，我们可以借助Spring的依赖注入把bean装配进AspectJ切面中。

为了演示，我们为上面的演出创建一个新切面。具体来讲，我们以切面的方式创建一个评论员的角色，他会观看演出并且会在演出之后提供一些批评意见。下面的CriticAspect就是一个这样的切面。

程序清单4.15　使用AspectJ实现表演的评论员

![2aa7cca176af389c1e64e2d4.png](/assets/img/2aa7cca176af389c1e64e2d4.png)

CriticAspect的主要职责是在表演结束后为表演发表评论。程序清单4.15中的performance()切点匹配perform()方法。当它与afterReturning()通知一起配合使用时，我们可以让该切面在表演结束时起作用。

程序清单4.15有趣的地方在于并不是评论员自己发表评论，实际上，CriticAspect与一个CriticismEngine对象相协作，在表演结束时，调用该对象的getCriticism()方法来发表一个苛刻的评论。为了避免CriticAspect和CriticismEngine之间产生不必要的耦合，我们通过Setter依赖注入为CriticAspect设置CriticismEngine。图4.9展示了此关系。

![6a4ce40403bc2825b021edb9.png](/assets/img/6a4ce40403bc2825b021edb9.png)

图4.9　切面也需要注入。像其他的bean一样，Spring可以为AspectJ切面注入依赖

CriticismEngine自身是声明了一个简单getCriticism()方法的接口。程序清单4.16为CriticismEngine的实现。

程序清单4.16　要注入到CriticAspect中的CriticismEngine实现

```java
package com.springinaction.springidol;
public class CriticismEngineImpl implements CriticismEngine {
  public CriticismEngineImpl() {}

  public String getCriticism() {
    int i = (int) (Math.random() * criticismPool.length);
    return criticismPool[i];
  }

  // injected
  private String[] criticismPool;
  public void setCriticismPool(String[] criticismPool) {
    this.criticismPool = criticismPool;
  }
}
```

CriticismEngineImpl实现了CriticismEngine接口，通过从注入的评论池中随机选择一个苛刻的评论。这个类可以使用如下的XML声明为一个Spring bean。

```xml
<bean id="criticismEngine"
    class="com.springinaction.springidol.CriticismEngineImpl">
  <property name="criticisms">
    <list>
      <value>Worst performance ever!</value>
      <value>I laughed, I cried, then I realized I was at the
             wrong show.</value>
      <value>A must see show!</value>
    </list>
  </property>
</bean>
```

到目前为止，一切顺利。我们现在有了一个要赋予CriticAspect的Criticism-Engine实现。剩下的就是为CriticAspect装配CriticismEngineImple。

在展示如何实现注入之前，我们必须清楚AspectJ切面根本不需要Spring就可以织入到我们的应用中。如果想使用Spring的依赖注入为AspectJ切面注入协作者，那我们就需要在Spring配置中把切面声明为一个Spring配置中的**`<bean>`**。如下的**`<bean>`**声明会把criticismEnginebean注入到CriticAspect中：

```xml
<bean class="com.springinaction.springidol.CriticAspect"
    factory-method="aspectOf">
  <property name="criticismEngine" ref="criticismEngine" />
</bean>
```

很大程度上，**`<bean>`**的声明与我们在Spring中所看到的其他**`<bean>`**配置并没有太多的区别，但是最大的不同在于使用了factory-method属性。通常情况下，Spring bean由Spring容器初始化，但是AspectJ切面是由AspectJ在运行期创建的。等到Spring有机会为CriticAspect注入CriticismEngine时，CriticAspect已经被实例化了。

因为Spring不能负责创建CriticAspect，那就不能在 Spring中简单地把CriticAspect声明为一个bean。相反，我们需要一种方式为Spring获得已经由AspectJ创建的CriticAspect实例的句柄，从而可以注入CriticismEngine。幸好，所有的AspectJ切面都提供了一个静态的aspectOf()方法，该方法返回切面的一个单例。所以为了获得切面的实例，我们必须使用factory-method来调用asepctOf()方法而不是调用CriticAspect的构造器方法。

简而言之，Spring不能像之前那样使用**`<bean>`**声明来创建一个CriticAspect实例——它已经在运行时由AspectJ创建完成了。Spring需要通过aspectOf()工厂方法获得切面的引用，然后像**`<bean>`**元素规定的那样在该对象上执行依赖注入。