---
title: "关于Java语言的finally语句"
date: 2019-05-05T19:23:13+08:00
categories: ["tech"]
---

## 是否一定执行、执行时机

一切要从这道题目说起：

Java语言中的`finally`语句（块）一定会被执行吗？是在`try`语句返回**之前**还是**之后**执行？

由于对这个问题的一知半解，当时只回答了前半个问题`是的，一定会执行`，没有回答后半个问题；笔试结束后查资料...才发现事情没那么简单🤯

诚然，我的回答是**错误**的，以下两种情况的finally语句不会被执行：

1. `try`语句没有被执行；也说明了finally语句被执行的`必要非充分`条件是`对应try语句被执行`
2. `try`语句中有`停止JVM`的语句；

后半个问题的答案是`之前`，即在`try`语句`返回`之前执行，可通过一个简单的例子来说明：

```jshell
jshell> String test1() {
   ...>     System.out.println("return statement");
   ...>
   ...>     return "after return";
   ...> }
|  created method test1()

jshell> String test2() {
   ...>     try {
   ...>         System.out.println("try block");
   ...>
   ...>         return test1();
   ...>     } finally {
   ...>         System.out.println("finally block");
   ...>     }
   ...> }
|  created method test2()

jshell> test2()
try block
return statement
finally block
$1 ==> "after return"
```

更详细地说明：执行return语句**之后**，再执行`finally语句`，再**返回**调用者；

## 执行的影响

### finally语句中的return语句

```jshell
jshell> int test() {
   ...>     int b = 20;
   ...>     try {
   ...>         System.out.println("try block");
   ...> 
   ...>         return b += 80;
   ...>     } catch (Exception e) {
   ...> 
   ...>         System.out.println("catch block");
   ...>     } finally {
   ...> 
   ...>         System.out.println("finally block");
   ...> 
   ...>         if (b > 25) {
   ...>             System.out.println("b>25, b = " + b);
   ...>         }
   ...> 
   ...>         return 200;
   ...>     }
   ...> }
|  modified method test()

jshell> test()
try block
finally block
b>25, b = 100
$2 ==> 200
```

说明finally的return语句的值被**返回**给调用者，即finally块中的return语句会**覆盖**try块中的return返回；

## finally语句中对try语句返回值的修改

这里要分为两种情况，返回值是`基本类型`还是`引用类型`：

1. 若是**基本类型**，修改无效；
2. 若是**引用类型**，也要分为两种情况：
   1. 若是修改**引用**，则无效；
   2. 若是修改**被引用的对象的内容**，则有效；

通过两个例子来演示：

### 基本类型

```jshell
jshell> int test() {
   ...>     int b = 20;
   ...> 
   ...>     try {
   ...>         System.out.println("try block");
   ...> 
   ...>         return b += 80;
   ...>     } catch (Exception e) {
   ...>         System.out.println("catch block");
   ...>     } finally {
   ...>         System.out.println("finally block");
   ...> 
   ...>         if (b > 25) {
   ...>             System.out.println("b>25, b = " + b);
   ...>         }
   ...> 
   ...>         b = 150;
   ...>     }
   ...> 
   ...>     return 2000;
   ...> }
|  modified method test()

jshell> test()
try block
finally block
b>25, b = 100
$3 ==> 100
```

让我们来探究一下这个例子的[字节码](/attachment/finally-primitive-type-example.tgz)：

> 截图自[jclasslib](https://github.com/ingokegel/jclasslib)工具

![afcd7098269159ba07bf670a.png](assets/img/afcd7098269159ba07bf670a.png)

- `6-8`行，将**本地变量数组（local variable array）**的第`0`个值（即20）加80，并被压入**操作数栈**，保存在第`1`个int值中
- `19-22`行，将`150`压入操作数栈，保存在`本地变量数组的第0个值`中，将`本地变量数组的第1个值`即（100）压入操作数栈，返回

故而语句`b = 150;`并没有影响到返回值；

### 引用类型

```jshell
jshell> Map<String, String> test() {
   ...>     Map<String, String> map = new HashMap<String, String>();
   ...>     map.put("KEY", "INIT");
   ...>     try {
   ...>         map.put("KEY", "TRY");
   ...>         return map;
   ...>     } catch (Exception e) {
   ...>         map.put("KEY", "CATCH");
   ...>     } finally {
   ...>         map.put("KEY", "FINALLY");
   ...>         map = null;
   ...>     }
   ...>     return map;
   ...> }
|  replaced method test()

jshell> test()
$4 ==> {KEY=FINALLY}
```

这个例子的[字节码](/attachment/finally-reference-type-example.tgz)如图：

![2cb3134765477ad23e79d035.png](assets/img/2cb3134765477ad23e79d035.png)

与上同理。

## 参考

1. [istore_n](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.istore_n)
2. [Java finally语句到底是在return之前还是之后执行？](https://www.cnblogs.com/lanxuezaipiao/p/3440471.html)