---
title: "🔍如何比较两个Collection含有相同的元素——来自Apache Commons Collections的实现"
date: 2019-07-20T19:23:13+08:00
categories: ["tech"]
---

> 您可以在[org.apache.commons.collections4.CollectionUtils](https://github.com/apache/commons-collections/blob/master/src/main/java/org/apache/commons/collections4/CollectionUtils.java)查看源代码。

`Apache Commons Collections`中的`CollectionUtils#isEqualCollection(java.util.Collection<?>, java.util.Collection<?>)`方法（及其[重载](https://github.com/apache/commons-collections/blob/master/src/main/java/org/apache/commons/collections4/CollectionUtils.java#L595)），提供了比较两个Collection含有相同的元素的实现，其源代码如下：

```java
/**
 * Returns {@code true} iff the given {@link Collection}s contain
 * exactly the same elements with exactly the same cardinalities.
 * <p>
 * That is, iff the cardinality of <i>e</i> in <i>a</i> is
 * equal to the cardinality of <i>e</i> in <i>b</i>,
 * for each element <i>e</i> in <i>a</i> or <i>b</i>.
 * </p>
 *
 * @param a  the first collection, must not be null
 * @param b  the second collection, must not be null
 * @return <code>true</code> iff the collections contain the same elements with the same cardinalities.
 */
public static boolean isEqualCollection(final Collection<?> a, final Collection<?> b) {
    if(a.size() != b.size()) {
        return false;
    }
    final CardinalityHelper<Object> helper = new CardinalityHelper<>(a, b);
    if(helper.cardinalityA.size() != helper.cardinalityB.size()) {
        return false;
    }
    for( final Object obj : helper.cardinalityA.keySet()) {
        if(helper.freqA(obj) != helper.freqB(obj)) {
            return false;
        }
    }
    return true;
}
```

在比较大小之后，以两个集合实例为入参，创建了一个`CardinalityHelper`实例，其源代码如下：

```java
/**
 * Helper class to easily access cardinality properties of two collections.
 * @param <O>  the element type
 */
private static class CardinalityHelper<O> {

    /** Contains the cardinality for each object in collection A. */
    final Map<O, Integer> cardinalityA;

    /** Contains the cardinality for each object in collection B. */
    final Map<O, Integer> cardinalityB;

    /**
     * Create a new CardinalityHelper for two collections.
     * @param a  the first collection
     * @param b  the second collection
     */
    public CardinalityHelper(final Iterable<? extends O> a, final Iterable<? extends O> b) {
        cardinalityA = CollectionUtils.getCardinalityMap(a);
        cardinalityB = CollectionUtils.getCardinalityMap(b);
    }

    /**
     * Returns the maximum frequency of an object.
     * @param obj  the object
     * @return the maximum frequency of the object
     */
    public final int max(final Object obj) {
        return Math.max(freqA(obj), freqB(obj));
    }

    /**
     * Returns the minimum frequency of an object.
     * @param obj  the object
     * @return the minimum frequency of the object
     */
    public final int min(final Object obj) {
        return Math.min(freqA(obj), freqB(obj));
    }

    /**
     * Returns the frequency of this object in collection A.
     * @param obj  the object
     * @return the frequency of the object in collection A
     */
    public int freqA(final Object obj) {
        return getFreq(obj, cardinalityA);
    }

    /**
     * Returns the frequency of this object in collection B.
     * @param obj  the object
     * @return the frequency of the object in collection B
     */
    public int freqB(final Object obj) {
        return getFreq(obj, cardinalityB);
    }

    private int getFreq(final Object obj, final Map<?, Integer> freqMap) {
        final Integer count = freqMap.get(obj);
        if (count != null) {
            return count.intValue();
        }
        return 0;
    }
}
```

其构造方法内，调用`org.apache.commons.collections4.CollectionUtils#getCardinalityMap`，创建了两个集合的基数映射，其源代码如下：

```java
/**
 * Returns a {@link Map} mapping each unique element in the given
 * {@link Collection} to an {@link Integer} representing the number
 * of occurrences of that element in the {@link Collection}.
 * <p>
 * Only those elements present in the collection will appear as
 * keys in the map.
 * </p>
 *
 * @param <O>  the type of object in the returned {@link Map}. This is a super type of &lt;I&gt;.
 * @param coll  the collection to get the cardinality map for, must not be null
 * @return the populated cardinality map
 */
public static <O> Map<O, Integer> getCardinalityMap(final Iterable<? extends O> coll) {
    final Map<O, Integer> count = new HashMap<>();
    for (final O obj : coll) {
        final Integer c = count.get(obj);
        if (c == null) {
            count.put(obj, Integer.valueOf(1));
        } else {
            count.put(obj, Integer.valueOf(c.intValue() + 1));
        }
    }
    return count;
}
```

然后，遍历某个集合基数映射的键集合，比较其基数是否与另一个集合中相同；若存在某个键不同，则判定两个集合不含有相同的元素。
