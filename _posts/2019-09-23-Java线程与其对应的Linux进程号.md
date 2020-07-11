---
layout: post
---

## 1 ps -eLf

首先，在Linux下，我们可以用`ps -eLf`命令看到`java`的线程号：

```
$ ps -eLf | grep java | grep -v grep 
opt      10801     1 10801  0   23 Sep19 ?        00:00:00 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10806  0   23 Sep19 ?        00:00:02 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10807  0   23 Sep19 ?        00:00:25 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10808  0   23 Sep19 ?        00:00:00 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10809  0   23 Sep19 ?        00:00:27 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10810  0   23 Sep19 ?        00:00:00 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10811  0   23 Sep19 ?        00:00:51 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10812  0   23 Sep19 ?        00:00:00 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10813  0   23 Sep19 ?        00:00:16 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10814  0   23 Sep19 ?        00:00:00 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10815  0   23 Sep19 ?        00:00:00 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10816  0   23 Sep19 ?        00:00:00 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10817  0   23 Sep19 ?        00:00:20 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10818  0   23 Sep19 ?        00:00:06 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10819  0   23 Sep19 ?        00:00:02 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10820  0   23 Sep19 ?        00:00:00 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10821  0   23 Sep19 ?        00:04:35 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10822  0   23 Sep19 ?        00:00:00 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10825  0   23 Sep19 ?        00:00:00 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10828  0   23 Sep19 ?        00:00:11 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10830  0   23 Sep19 ?        00:00:20 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 10831  0   23 Sep19 ?        00:00:20 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
opt      10801     1 19608  0   23 21:49 ?        00:00:00 java -XX:+UseG1GC -XX:+UseStringDeduplication -Xms32m -Xmx32m -server -jar gogo.jar
```

## jstack

其次，我们可以使用`jstack`命令转储线程信息，也能得到java线程号：

```
"Reference Handler" #2 daemon prio=10 os_prio=0 cpu=30.65ms elapsed=339658.01s tid=0x00007fa6e0120000 nid=0x2a3e waiting on condition  [0x00007fa6c435b000]
   java.lang.Thread.State: RUNNABLE
	at java.lang.ref.Reference.waitForReferencePendingList(java.base@11.0.3/Native Method)
	at java.lang.ref.Reference.processPendingReferences(java.base@11.0.3/Reference.java:241)
	at java.lang.ref.Reference$ReferenceHandler.run(java.base@11.0.3/Reference.java:213)
```

其中的`nid=0x2a3e`的十进制为`10814`：

```
$ printf "%d\n" 0x2a3e
10814
```

## top -H -p

```
$ top -H -p 10801

top - 22:07:00 up 4 days, 26 min,  1 user,  load average: 0.00, 0.00, 0.00
Threads:  23 total,   0 running,  23 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem :  1025532 total,    87060 free,   309220 used,   629252 buff/cache
KiB Swap:   266236 total,   243336 free,    22900 used.   565344 avail Mem 

  PID USER      PR  NI    VIRT    RES    SHR S %CPU %MEM     TIME+ COMMAND                                                             
10801 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:00.00 java                                                                
10806 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:02.78 java                                                                
10807 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:26.07 GC Thread#0                                                         
10808 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:00.14 G1 Main Marker                                                      
10809 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:27.40 G1 Conc#0                                                           
10810 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:00.00 G1 Refine#0                                                         
10811 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:51.73 G1 Young RemSet                                                     
10812 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:00.02 StrDedup                                                            
10813 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:17.05 VM Thread                                                           
10814 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:00.02 Reference Handl                                                     
10815 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:00.02 Finalizer                                                           
10816 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:00.00 Signal Dispatch                                                     
10817 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:20.07 C2 CompilerThre                                                     
10818 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:06.41 C1 CompilerThre                                                     
10819 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:02.51 Sweeper thread                                                      
10820 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:00.00 Service Thread                                                      
10821 opt       20   0 2185948 187316  11692 S  0.0 18.3   4:36.19 VM Periodic Tas                                                     
10822 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:00.37 Common-Cleaner                                                      
10825 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:00.00 AsyncAppender-W                                                     
10828 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:11.31 nioEventLoopGro                                                     
10830 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:20.83 nioEventLoopGro                                                     
10831 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:20.76 nioEventLoopGro                                                     
19608 opt       20   0 2185948 187316  11692 S  0.0 18.3   0:00.00 Attach Listener
```

## 参考

- [How to find a Java thread running on Linux with ps -axl?](https://stackoverflow.com/questions/9934517/how-to-find-a-java-thread-running-on-linux-with-ps-axl)
- [rednaxelafx/PrintThreadIds.java](https://gist.github.com/rednaxelafx/843622)
