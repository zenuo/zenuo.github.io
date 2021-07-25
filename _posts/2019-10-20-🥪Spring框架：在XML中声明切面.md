---
layout: post
---

**基于注解的配置**要优于**基于Java的配置**，**基于Java的配置**要优于**基于XML的配置**。但是，如果你需要声明切面，但是又不能为通知类添加注解的时候，那么就必须转向XML配置了。

在Spring的aop命名空间中，提供了多个元素用来在XML中声明切面，如表4.3所示。

|AOP配置元素|用途|
|---|---|
|<aop:advisor>|定义AOP通知器|
|<aop:after>|定义AOP后置通知（不管被通知的方法是否执行成功）|
|<aop:after-returning>|定义AOP返回通知|
|<aop:after-throwing>|定义AOP异常通知|
|<aop:around>|定义AOP环绕通知|
|<aop:aspect>|定义一个切面|
|<aop:aspectj-autoproxy>|启用@AspectJ注解驱动的切面|
|<aop:before>|定义一个AOP前置通知|
|<aop:config>|顶层的AOP配置元素。大多数的<aop:*>元素必须包含在<aop:config>元素内|
|<aop:declare-parents>|以透明的方式为被通知的对象引入额外的接口|
|<aop:pointcut>|定义一个切点|

我们已经看过了<aop:aspectj-autoproxy>元素，它能够自动代理AspectJ注解的通知类。aop命名空间的其他元素能够让我们直接在Spring配置中声明切面，而不需要使用注解。

例如，我们重新看一下Audience类，这一次我们将它所有的AspectJ注解全部移除掉：

```java
package concert;

public class Audience {

  public void silenceCellPhones() {
    System.out.println("Silencing cell phones");
  }

  public void takeSeats() {
    System.out.println("Taking seats");
  }

  public void applause() {
    System.out.println("CLAP CLAP CLAP!!!");
  }

  public void demandRefund() {
    System.out.println("Demanding a refund");
  }

}
```

正如你所看到的，Audience类并没有任何特别之处，它就是有几个方法的简单Java类。我们可以像其他类一样把它注册为Spring应用上下文中的bean。

尽管看起来并没有什么差别，但Audience已经具备了成为AOP通知的所有条件。我们再稍微帮助它一把，它就能够成为预期的通知了。

## 声明前置和后置通知

你可以再把那些AspectJ注解加回来，但这并不是本节的目的。相反，我们会使用Spring aop命名空间中的一些元素，将没有注解的Audience类转换为切面。下面的程序清单4.9展示了所需要的XML。

程序清单4.9　通过XML将无注解的Audience声明为切面

![0bdf4a86f55a35fe567044df.png](/assets/img/0bdf4a86f55a35fe567044df.png)

关于Spring AOP配置元素，第一个需要注意的事项是大多数的AOP配置元素必须在**`<aop:config>`**元素的上下文内使用。这条规则有几种例外场景，但是把bean声明为一个切面时，我们总是从**`<aop:config>`**元素开始配置的。

该切面应用了四个不同的通知。两个**`<aop:before>`**元素定义了匹配切点的方法执行之前调用前置通知方法—也就是Audience bean的takeSeats()和turnOffCellPhones()方法（由method属性所声明）。**`<aop:after-returning>`**元素定义了一个返回（after-returning）通知，在切点所匹配的方法调用之后再调用applaud()方法。同样，**`<aop:after-throwing>`**元素定义了异常（after-throwing）通知，如果所匹配的方法执行时抛出任何的异常，都将会调用demandRefund()方法。图4.8展示了通知逻辑如何织入到业务逻辑中。

![c07ca196e56e1e54c13f2a30.png](/assets/img/c07ca196e56e1e54c13f2a30.png)

图4.8　Audience切面包含四种通知，它们把通知逻辑织入进匹配切面切点的方法中

在所有的通知元素中，pointcut属性定义了通知所应用的切点，它的值是使用AspectJ切点表达式语法所定义的切点。

你或许注意到所有通知元素中的pointcut属性的值都是一样的，这是因为所有的通知都要应用到相同的切点上。

在基于AspectJ注解的通知中，当发现这种类型的重复时，我们使用@Pointcut注解消除了这些重复的内容。而在基于XML的切面声明中，我们需要使用**`<aop:pointcut>`**元素。如下的XML展现了如何将通用的切点表达式抽取到一个切点声明中，这样这个声明就能在所有的通知元素中使用了。

程序清单4.10　使用**`<aop:pointcut>`**定义命名切点

![1d655f90e5199b1b4ec38009.png](/assets/img/1d655f90e5199b1b4ec38009.png)

现在切点是在一个地方定义的，并且被多个通知元素所引用。**`<aop:pointcut>`**元素定义了一个id为performance的切点。同时修改所有的通知元素，用pointcut-ref属性来引用这个命名切点。

正如程序清单4.10所展示的，**`<aop:pointcut>`**元素所定义的切点可以被同一个**`<aop:aspect>`**元素之内的所有通知元素引用。如果想让定义的切点能够在多个切面使用，我们可以把**`<aop:pointcut>`**元素放在**`<aop:config>`**元素的范围内。

## 声明环绕通知

目前Audience的实现工作得非常棒，但是前置通知和后置通知有一些限制。具体来说，如果不使用成员变量存储信息的话，在前置通知和后置通知之间共享信息非常麻烦。

例如，假设除了进场关闭手机和表演结束后鼓掌，我们还希望观众确保一直关注演出，并报告每个参赛者表演了多长时间。使用前置通知和后置通知实现该功能的唯一方式是在前置通知中记录开始时间并在某个后置通知中报告表演耗费的时间。但这样的话我们必须在一个成员变量中保存开始时间。因为Audience是单例的，如果像这样保存状态的话，将会存在线程安全问题。

相对于前置通知和后置通知，环绕通知在这点上有明显的优势。使用环绕通知，我们可以完成前置通知和后置通知所实现的相同功能，而且只需要在一个方法中 实现。因为整个通知逻辑是在一个方法内实现的，所以不需要使用成员变量保存　状态。

例如，考虑程序清单4.11中新Audience类的watchPerformance()方法，它没有使用任何的注解。

程序清单4.11　watchPerformance()方法提供了AOP环绕通知

![a1f07e14453a179994e4aa71.png](/assets/img/a1f07e14453a179994e4aa71.png)

在观众切面中，watchPerformance()方法包含了之前四个通知方法的所有功能。不过，所有的功能都放在了这一个方法中，因此这个方法还要负责自身的异常处理。

声明环绕通知与声明其他类型的通知并没有太大区别。我们所需要做的仅仅是使用**`<aop:around>`**元素。

程序清单4.12　在XML中使用**`<aop:around>`**元素声明环绕通知

![28f709d2d7fd520b34d733b8.png](/assets/img/28f709d2d7fd520b34d733b8.png)

像其他通知的XML元素一样，**`<aop:around>`**指定了一个切点和一个通知方法的名字。在这里，我们使用跟之前一样的切点，但是为该切点所设置的method属性值为watchPerformance()方法。

## 为通知传递参数

在4.3.3小节中，我们使用@AspectJ注解创建了一个切面，这个切面能够记录CompactDisc上每个磁道播放的次数。现在，我们使用XML来配置切面，那就看一下如何完成这一相同的任务。

首先，我们要移除掉TrackCounter上所有的@AspectJ注解。

程序清单4.13　无注解的TrackCounter

![fa6ab086e42a46493032e6a6.png](/assets/img/fa6ab086e42a46493032e6a6.png)

去掉@AspectJ注解后，TrackCounter显得有些单薄了。现在，除非显式调用countTrack()方法，否则TrackCounter不会记录磁道播放的数量。但是，借助一点Spring XML配置，我们能够让TrackCounter重新变为切面。

如下的程序清单展现了完整的Spring配置，在这个配置中声明了TrackCounter bean和BlankDisc bean，并将TrackCounter转化为切面。

程序清单4.14　在XML中将TrackCounter配置为参数化的切面

![508ac4f4cd75fb215576bda8.png](/assets/img/508ac4f4cd75fb215576bda8.png)

可以看到，我们使用了和前面相同的aop命名空间XML元素，它们会将POJO声明为切面。唯一明显的差别在于切点表达式中包含了一个参数，这个参数会传递到通知方法中。如果你将这个表达式与程序清单4.6中的表达式进行对比会发现它们几乎是相同的。唯一的差别在于这里使用and关键字而不是“&&”（因为在XML中，“&”符号会被解析为实体的开始）。

我们通过练习已经使用Spring的aop命名空间声明了几个基本的切面，那么现在让我们看一下如何使用aop命名空间声明引入切面。

## 通过切面引入新的功能

在前面的4.3.4小节中，我向你展现了如何借助AspectJ的@DeclareParents注解为被通知的方法神奇地引入新的方法。但是AOP引入并不是AspectJ特有的。使用Spring aop命名空间中的**`<aop:declare-parents>`**元素，我们可以实现相同的功能。

如下的XML代码片段与之前基于AspectJ的引入功能是相同：

```xml
<aop:aspect>
  <aop:declare-parents
    types-matching="concert.Performance+"
    implement-interface="concert.Encoreable"
    default-impl="concert.DefaultEncoreable"
    />
</aop:aspect>
```

顾名思义，**`<aop:declare-parents>`**声明了此切面所通知的bean要在它的对象层次结构中拥有新的父类型。具体到本例中，类型匹配Performance接口（由types-matching属性指定）的那些bean在父类结构中会增加Encoreable接口（由implement-interface属性指定）。最后要解决的问题是Encoreable接口中的方法实现要来自于何处。

这里有两种方式标识所引入接口的实现。在本例中，我们使用default-impl属性用全限定类名来显式指定Encoreable的实现。或者，我们还可以使用delegate-ref属性来标识。

```xml
<aop:aspect>
  <aop:declare-parents
    types-matching="concert.Performance+"
    implement-interface="concert.Encoreable"
    delegate-ref="encoreableDelegate"
    />
</aop:aspect>
```

delegate-ref属性引用了一个Spring bean作为引入的委托。这需要在Spring上下文中存在一个ID为encoreableDelegate的bean。

```xml
<bean id="encoreableDelegate"
      class="concert.DefaultEncoreable" />
```

使用default-impl来直接标识委托和间接使用delegate-ref的区别在于后者是Spring bean，它本身可以被注入、通知或使用其他的Spring配置。