---
title: sed awk grep 入门
date: 2019-11-09 7:36:20
tags:
- Command
- Linux
categories:
- 学习笔记
---

### sed ###

#### 引言 ####

sed是<code>stream editor(流编辑器)</code>的缩写，是一个使用简单紧凑的编程语言来解析和转换文本的Unix实用程序。sed由贝尔实验室的Lee E. McMahon于1973年至1974年开发，并且现在大多数操作系统都可以使用。 
sed基于交互式编辑器ed（“editor”，1971）和早期qed（“quick editor”，1965-66）的脚本功能。sed是最早支持**正则表达式**的工具之一，至今仍然用于**文本处理**，特别是用于**替换**命令。
摘自[维基百科](https://zh.wikipedia.org/wiki/Sed)

----

#### 语法 ####

命令格式
>`sed [options] 'command' file(s)
>sed [options] -f scriptfile file(s)

- <code>sed</code>的简单使用，**单词替换**功能：将<code>hello</code>替换为<code>world</code>，<code>/hello/</code>表示匹配，<code>/world/</code>表示把匹配替换成<code>world</code>
```
docker@pureven:~$ cat input.txt                                                                                           
hello world
hello pureven
docker@pureven:~$                                                                                                         
docker@pureven:~$ sed 's/hello/world/' input.txt > output.txt
docker@pureven:~$ cat output.txt                                                                                          
world world
world pureven
docker@pureven:~$
```
从output.txt的内容即可发现，sed已将input.txt文件中的<code>hello</code>替换为<code>world</code>，如果不指定<code>inputfile</code>，sed将会过滤标准输入的内容。
一下命令是等效的：
```
docker@pureven:~$ sed 's/hello/world/' input.txt > output.txt
docker@pureven:~$ cat output.txt                                                                                          
world world
world pureven
docker@pureven:~$ sed 's/hello/world/' < input.txt > output.txt                                                           
docker@pureven:~$ cat output.txt                                                                                          
world world
world pureven       
docker@pureven:~$ cat input.txt | sed 's/hello/world/' - > output.txt                                             
docker@pureven:~$ cat output.txt                                                                                          
world world
world pureven
```

- 每行替换所有的匹配如何实现
```
docker@pureven:~$ cat input.txt 
hello world hello world hello hello
hello pureven hello pureven hello hello
docker@pureven:~$                                                                                                         
docker@pureven:~$ sed 's/hello/world/' input.txt > output.txt        
docker@pureven:~$ cat output.txt                                                                                          
world world hello world hello hello
world pureven hello pureven hello hello
docker@pureven:~$ sed 's/hello/world/g' input.txt > output.txt                                                            
docker@pureven:~$ cat output.txt                                                                                          
world world world world world world
world pureven world pureven world world
```
通过比较可以得出<code>/g</code>的作用是将每行所有的<code>hello</code>替换为<code>world</code>。

----

#### 脚本 ####



----

#### 命令行选项 ####


----


### awk ###

#### 前言 ####
AWK是一种优良的文本处理工具，Linux及Unix环境中现有的功能最强大的数据处理引擎之一。名称得自于它的创始人<code>Alfred Aho</code>、<code>Peter Weinberger</code>和<code>Brian Kernighan</code>姓氏的首个字母
AWK提供了极其强大的功能：可以进行<cdoe>正则表达式的匹配</code>，<code>样式装入</code>、<code>流控制</code>、<code>数学运算符</code>、<code>进程控制语句</code>甚至于<code>内置的变量</code>和<code>函数</code>。下面进行简单介绍

----

#### awk的命令格式和选项 ####

**语法形式** 

><code>awk [options] 'pattern {action}' (filename)</code>

选项参数说明:
<code>options</code>:
- -F fs or --field-separator fs: 指定输入文件折分隔符，fs是一个字符串或者一个正则表达式
- -v var=value or --asign var=value: 赋值一个用户定义变量
- -f scriptfile or --file scriptfile: 从脚本文件中读取awk命令
- -W help or --help, -W usage or --usage: 打印全部awk选项和每个选项的简短说明

<code>pattern</code>:表示模式，即条件
<code>action</code>:为awk语句，表示每一行的处理动作，只能被单引号包含  
<code>filename</code>:表示awk要处理的文本文件。

**举例说明:**

其信息通过冒号<code>:</code>进行连接，下面通过awk进行格式化显示：
```
[root@tony Desktop]# cat /etc/passwd | head -n 10 > passwd.info 
[root@tony Desktop]# cat passwd.info 
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
adm:x:3:4:adm:/var/adm:/sbin/nologin
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
sync:x:5:0:sync:/sbin:/bin/sync
shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
halt:x:7:0:halt:/sbin:/sbin/halt
mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
operator:x:11:0:operator:/root:/sbin/nologin
[root@tony Desktop]# awk -F : '{printf "%02s %-10s %-8s %-8s %-8s %-10s %-16s %-8s\n", NR,$1,$2,$3,$4,$5,$6,$7}' passwd.info 
 1 root       x        0        0        root       /root            /bin/bash
 2 bin        x        1        1        bin        /bin             /sbin/nologin
 3 daemon     x        2        2        daemon     /sbin            /sbin/nologin
 4 adm        x        3        4        adm        /var/adm         /sbin/nologin
 5 lp         x        4        7        lp         /var/spool/lpd   /sbin/nologin
 6 sync       x        5        0        sync       /sbin            /bin/sync
 7 shutdown   x        6        0        shutdown   /sbin            /sbin/shutdown
 8 halt       x        7        0        halt       /sbin            /sbin/halt
 9 mail       x        8        12       mail       /var/spool/mail  /sbin/nologin
10 operator   x        11       0        operator   /root            /sbin/nologin
[root@tony Desktop]#
```
其中$1 - $7、 NR为内置变量， -F的作用是设置定界符，这里使用<code>:</code>进行分割后得到的每一列。
**这里<code>options</code>即<code>-F :</code>,<code>action</code>即<code>printf</code>**

多个分隔符示例：
```
docker@pureven:~$ cat pwd.info 
root:x:0:0:root:/root:/bin/bash
lp:x:7:7:lp:/var/spool/lpd:/bin/sh
docker@pureven:~$ awk -F '[:]' '{print $1,$2,$3,$4,$5}' pwd.info                                                          
root x 0 0 root
lp x 7 7 lp
docker@pureven:~$                                                                                                         
docker@pureven:~$ awk -F '[:|root]' '{print $1,$2,$3,$4,$5}' pwd.info 
    
lp x 7 7 lp
docker@pureven:~$ awk -F '[:|root]+' '{print $1,$2,$3,$4,$5}' pwd.info                                                    
 x 0 0 /
lp x 7 7 lp
docker@pureven:~$ 
```
其中的<code>+</code>表示连续出现的分隔符当作一个来处理

```
docker@pureven:~$ awk -F : '{printf "NR:%-6s NF:%-6s %-10s %-10s %-16s %-8s\n", NR,NF,$1,$5,$6,$7}' pwd.info                                                
NR:1      NF:7      root       root       /root            /bin/bash
NR:2      NF:7      lp         lp         /var/spool/lpd   /bin/sh 
NR:3      NF:7      nobody     nobody     /nonexistent     /bin/false
NR:4      NF:7      tc         Linux User,,, /home/tc         /bin/sh 
NR:5      NF:7      docker     Docker     /home/docker     /bin/bash
NR:6      NF:7      dockremap  Linux User,,, /home/dockremap  /bin/false
docker@pureven:~$ awk -F : 'NR == 3 || NR == 5{printf "NR:%-6s NF:%-6s %-10s %-10s %-16s %-8s\n", NR,NF,$1,$5,$6,$7}' pwd.info                              
NR:3      NF:7      nobody     nobody     /nonexistent     /bin/false
NR:5      NF:7      docker     Docker     /home/docker     /bin/bash
```
**这里<code>pattern</code> 即'NR == 3 || NR == 5'**

----

#### 内置变量 ####

上面用到的$1 - $7及NR均为swk内置的变量，每个内置变量的作用不同，下面列出常用的几个：

| 变量名 | 作用 |
| :----  | :--- |
| $0 | 存放整行内容 |
| $1 - $n | 存放通过FS将内容分割后的第一个到第几个字段 |
| NR | 已经读出的内容的行号，从1开始，如果有多个文件，这个值也是不断累加 |
| FNR | 与NR不同之处在于每个文件都从1开始累加 |
| NF | 记录通过FS将内容分割后的字段数目，也就是列的数目 |
| FS | 输入的字段分隔符，默认是空格 |
| OFS | 输出的字段分隔符，默认是空格 |
| RS | 输入的记录分隔符，默认是换行符 |
| ORS | 输出的记录分隔符，默认是换行符 |
| OFMT | 数字输出格式，默认为%.6g，保留6位小数 |
| FILENAME | 当前文件名 |

**举例说明:**

- 查看$0内容
```
[root@tony Desktop]# awk '{print $0}' pwd.info 
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
adm:x:3:4:adm:/var/adm:/sbin/nologin
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
[root@tony Desktop]# 
[root@tony Desktop]# cat pwd.info 
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
adm:x:3:4:adm:/var/adm:/sbin/nologin
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
```
$0即读取每行内容，这里将每行内容打印出来跟cat pwd.info效果一样

- FILENAME/NR/FNR/NF 示例：
```
[root@tony Desktop]# awk -F : '{printf "FILENAME:%-12s FNR:%-6s NR:%-6s NF:%-6s %-10s %-10s %-16s %-8s\n", FILENAME,FNR,NR,NF,$1,$5,$6,$7}' pwd.info shadow.info
FILENAME:pwd.info     FNR:1      NR:1      NF:7      root       root       /root            /bin/bash
FILENAME:pwd.info     FNR:2      NR:2      NF:7      bin        bin        /bin             /sbin/nologin
FILENAME:pwd.info     FNR:3      NR:3      NF:7      daemon     daemon     /sbin            /sbin/nologin
FILENAME:pwd.info     FNR:4      NR:4      NF:7      adm        adm        /var/adm         /sbin/nologin
FILENAME:pwd.info     FNR:5      NR:5      NF:7      lp         lp         /var/spool/lpd   /sbin/nologin
FILENAME:shadow.info  FNR:1      NR:6      NF:9      root       99999      7                        
FILENAME:shadow.info  FNR:2      NR:7      NF:9      bin        99999      7                        
FILENAME:shadow.info  FNR:3      NR:8      NF:9      daemon     99999      7                        
FILENAME:shadow.info  FNR:4      NR:9      NF:9      adm        99999      7                        
FILENAME:shadow.info  FNR:5      NR:10     NF:9      lp         99999      7  
```

- FS/OFS 示例： 输入**字段**分隔符<code>:</code>, 输出**字段**分隔符<code>**</code>
```` 
docker@pureven:~$ cat pwd.info                                        
root:x:0:0:root:/root:/bin/bash
lp:x:7:7:lp:/var/spool/lpd:/bin/sh
nobody:x:65534:65534:nobody:/nonexistent:/bin/false
tc:x:1001:50:Linux User,,,:/home/tc:/bin/sh
docker:x:1000:50:Docker:/home/docker:/bin/bash
dockremap:x:100:101:Linux User,,,:/home/dockremap:/bin/false
docker@pureven:~$                                                                                                         
docker@pureven:~$ awk '{FS=":",OFS="**"}{print $1, $2, $3, $4, $5, $6, $7 }' pwd.info 
root:x:0:0:root:/root:/bin/bash************
lp**x**7**7**lp**/var/spool/lpd**/bin/sh
nobody**x**65534**65534**nobody**/nonexistent**/bin/false
tc**x**1001**50**Linux User,,,**/home/tc**/bin/sh
docker**x**1000**50**Docker**/home/docker**/bin/bash
dockremap**x**100**101**Linux User,,,**/home/dockremap**/bin/false
````

- OFMT 示例：
>**所有输入都将视为字符串，直到通过使用方式进行隐式转换为止**
```
docker@pureven:~$ echo 3.1415926 | awk '{OFMT="%.2f";print 0+$0}'
3.14
docker@pureven:~$ echo 3.1415926 | awk '{OFMT="%.3f";print 0+$0}'                                                         
3.142
docker@pureven:~$ echo 3.1415926 | awk '{OFMT="%.4f";print 0+$0}'                                                         
3.1416
docker@pureven:~$ echo 3.1415926 | awk '{OFMT="%.5f";print 0+$0}'                                                         
3.14159
docker@pureven:~$ echo 3.1415926 | awk '{OFMT="%d";print 0+$0}'                                                           
3
docker@pureven:~$ echo 3.1415926 | awk '{OFMT="%d";print $0}'                                                             
3.1415926
```

----

#### 内置函数 ####

| 函数名 | 作用 |
| :---| :------|
| toupper | 将字符转为大写 |
| tolower | 将字符转为小写 |
| length  | 长度 |
| substr  | 子字符串 |
| sin     | 正弦 |
| cos     | 余弦 |
| sqrt    | 平方根 |
| rand    | 随机数 |

完整列表请参见[手册](https://www.gnu.org/software/gawk/manual/html_node/Built_002din.html#Built_002din)

**举例说明:**

- <code>substr()</code>函数测试：
```
[root@tony Desktop]# awk -F : '{print substr(FILENAME, 5,4), NF, $(NF-1), $0}' pwd.info 
info 7 /root root:x:0:0:root:/root:/bin/bash
info 7 /bin bin:x:1:1:bin:/bin:/sbin/nologin
info 7 /sbin daemon:x:2:2:daemon:/sbin:/sbin/nologin
info 7 /var/adm adm:x:3:4:adm:/var/adm:/sbin/nologin
info 7 /var/spool/lpd lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
[root@tony Desktop]# 
```

- <code>toupper()/tolower()</code>函数测试
```
[root@tony Desktop]# 
[root@tony Desktop]# awk -F : '{print tolower(FILENAME), NF, $(NF-1), $0}' pwd.info 
pwd.info 7 /root root:x:0:0:root:/root:/bin/bash
pwd.info 7 /bin bin:x:1:1:bin:/bin:/sbin/nologin
pwd.info 7 /sbin daemon:x:2:2:daemon:/sbin:/sbin/nologin
pwd.info 7 /var/adm adm:x:3:4:adm:/var/adm:/sbin/nologin
pwd.info 7 /var/spool/lpd lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
[root@tony Desktop]# 
[root@tony Desktop]# awk -F : '{print toupper(FILENAME), NF, $(NF-1), $0}' pwd.info 
PWD.INFO 7 /root root:x:0:0:root:/root:/bin/bash
PWD.INFO 7 /bin bin:x:1:1:bin:/bin:/sbin/nologin
PWD.INFO 7 /sbin daemon:x:2:2:daemon:/sbin:/sbin/nologin
PWD.INFO 7 /var/adm adm:x:3:4:adm:/var/adm:/sbin/nologin
PWD.INFO 7 /var/spool/lpd lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
```

- 对变量进行重新赋值
```
[root@tony Desktop]# awk -F : '{print toupper(FILENAME), NF, $(NF-1), $0 = "***"}' pwd.info 
PWD.INFO 7 /root ***
PWD.INFO 7 /bin ***
PWD.INFO 7 /sbin ***
PWD.INFO 7 /var/adm ***
PWD.INFO 7 /var/spool/lpd ***
```
$0本来是每行内容的，经过赋值变成了***

- 实现单词统计和去重
```
docker@pureven:~$ cat word.list                                                                                             
hello world pureven awk
hello world pureven awk
hello world pureven awk
awk hello world pureven
pureven awk hello world
world pureven awk hello
docker@pureven:~$ awk '{c+=length($0)+1;w+=NF}END{print "row_nums = " NR,"\nword_nums = " w, "\nchar_nums = " c}' word.list                         
row_nums = 6 
word_nums = 24 
char_nums = 144
docker@pureven:~$ awk '!arr[$0]++ {print $0}' word.list                                                                                             
hello world pureven awk
awk hello world pureven
pureven awk hello world
world pureven awk hello
docker@pureven:~$
```
>单词统计：c += leng($0) + 1将每行字符串相加；w += NF 将每行单词数相加。
去重：<code>arr[$0]++</code>中$0作为key，初值arr[$0] = 0，当读取重复行后通过arr[$0]++变为arr[$0] = 1，取非后为假就过滤掉了

----

#### awk 模式 ####

<code>pattern</code>表示模式，用一个比较好理解的单词就是指**条件**，这里介绍awk的模式中的三类：<code>空模式</code>, <code>关系运算模式</code>, <code>BEGIN/END模式</code>。
> 空模式：表示没有指定任何条件的模式，awk会直接对文本处理。
> 关系运算模式： 如前文中的'NR % 2 == 1'、'$1 == "root"'、'$1 == "daemon"'等，awk会根据这些条件对文件进行操作。
> BEGIN/END模式：BEGIN表示开始处理文本之前需要执行的操作，END表示将所有行都处理完毕之后需要执行的操作。

##### <code>关系运算模式</code> #####

<code>awk</code>允许指定输出条件，只输出符合条件的行。
```
[root@tony Desktop]# awk -F : '{printf "%02s %-10s %-8s %-8s %-8s %-10s %-16s %-8s\n", NR,$1,$2,$3,$4,$5,$6,$7}' pwd.info 
 1 root       x        0        0        root       /root            /bin/bash
 2 bin        x        1        1        bin        /bin             /sbin/nologin
 3 daemon     x        2        2        daemon     /sbin            /sbin/nologin
 4 adm        x        3        4        adm        /var/adm         /sbin/nologin
 5 lp         x        4        7        lp         /var/spool/lpd   /sbin/nologin
[root@tony Desktop]#
[root@tony Desktop]# awk -F : 'NR % 2 == 1 {printf "%02s %-10s %-8s %-8s %-8s %-10s %-16s %-8s\n", NR,$1,$2,$3,$4,$5,$6,$7}' pwd.info 
 1 root       x        0        0        root       /root            /bin/bash
 3 daemon     x        2        2        daemon     /sbin            /sbin/nologin
 5 lp         x        4        7        lp         /var/spool/lpd   /sbin/nologin
[root@tony Desktop]# 
[root@tony Desktop]# awk -F : '$1 == "root" {printf "%02s %-10s %-8s %-8s %-8s %-10s %-16s %-8s\n", NR,$1,$2,$3,$4,$5,$6,$7}' pwd.info 
 1 root       x        0        0        root       /root            /bin/bash
[root@tony Desktop]# 
[root@tony Desktop]# awk -F : '$1 == "daemon" {printf "%02s %-10s %-8s %-8s %-8s %-10s %-16s %-8s\n", NR,$1,$2,$3,$4,$5,$6,$7}' pwd.info 
 3 daemon     x        2        2        daemon     /sbin            /sbin/nologin
[root@tony Desktop]#
```
<code>NR % 2 == 1</code>表示条件，作用是输出时只输出NR为奇数的行,<code>$1 == "root"</code>和<code>$1 == "daemon"</code>分别匹配第一列为<code>root</code>和<code>daemon</code>的行。

另外<code>awk</code>还支持if ... else条件判断
```
[root@tony Desktop]# awk -F : '{printf "%02s %-10s %-8s %-8s %-8s %-10s %-16s %-8s\n", NR,$1,$2,$3,$4,$5,$6,$7}' pwd.info 
 1 root       x        0        0        root       /root            /bin/bash
 2 bin        x        1        1        bin        /bin             /sbin/nologin
 3 daemon     x        2        2        daemon     /sbin            /sbin/nologin
 4 adm        x        3        4        adm        /var/adm         /sbin/nologin
 5 lp         x        4        7        lp         /var/spool/lpd   /sbin/nologin
[root@tony Desktop]# 
[root@tony Desktop]# 
[root@tony Desktop]# 
[root@tony Desktop]# awk -F : '{if (NR > 3) printf "%02s %-10s %-8s %-8s %-8s %-10s %-16s %-8s\n", NR,$1,$2,$3,$4,$5,$6,$7; else print NR, $0}' pwd.info 
1 root:x:0:0:root:/root:/bin/bash
2 bin:x:1:1:bin:/bin:/sbin/nologin
3 daemon:x:2:2:daemon:/sbin:/sbin/nologin
 4 adm        x        3        4        adm        /var/adm         /sbin/nologin
 5 lp         x        4        7        lp         /var/spool/lpd   /sbin/nologin
[root@tony Desktop]#
```

##### <code>BEGIN/END模式</code> #####

```
docker@pureven:~$ cat input.txt 
a b c d e f g
h i j k l m n
o p q r s t
u v w z y z
docker@pureven:~$                                                                                                                                           
docker@pureven:~$ awk 'BEGIN{print "1","2","3","4","5","6","7"}{print $1, $2, $3, $4, $5, $6, $7}END{print "7","6","5","4","3","2","1"}' input.txt 
1 2 3 4 5 6 7
a b c d e f g
h i j k l m n
o p q r s t 
u v w z y z 
7 6 5 4 3 2 1
docker@pureven:~$
```

----

### grep ###

#### 前言 ####

grep是一个最初用于Unix操作系统的命令行工具。由<code>Kenneth Lane Thompson</code>写成。grep原先是ed下的一个应用程序，名称来自于g/re/p（globally search a regular expression and print，**全面搜索正则表达式并把行打印出来**）。在给出文件列表或标准输入后，grep会对匹配一个或多个正则表达式的文本进行搜索，并只输出匹配（或者不匹配）的行或文本。摘自[维基百科](https://zh.wikipedia.org/wiki/Grep)。

#### 使用说明 ####

语法形式
> grep options pattern filename
grep options "pattern" filename

选项
>-a 将 binary 文件以 text 文件的方式搜寻数据。
-A<显示列数> 除了显示'搜寻字符串'的那一行之外，并显示该行之后的内容。
-b 在显示'搜寻字符串'的那一行之外，并显示该行之前的内容。
-c 计算找到 '搜寻字符串' 的次数。
-C<显示列数>或-<显示列数>  除了显示'搜寻字符串'的那一列之外，并显示该列之前后的内容。
-d<进行动作> 当指定要查找的是目录而非文件时，必须使用这项参数，否则grep命令将回报信息并停止动作。
-e<'搜寻字符串'> 指定字符串作为查找文件内容的'搜寻字符串'。
-E 将'搜寻字符串'为延伸的普通表示法来使用，意味着使用能使用扩展正则表达式。
-f<搜索文件> 指定搜索文件，其内容有一个或多个'搜寻字符串'，让grep查找符合范本条件的文件内容，格式为每一列的'搜寻字符串'。
-F 将'搜寻字符串'视为固定字符串的列表。
-G 将'搜寻字符串'视为普通的表示法来使用。
-h 在显示'搜寻字符串'的那一列之前，不标示该列所属的文件名称。
-H 在显示'搜寻字符串'的那一列之前，标示该列的文件名称。
-i 忽略字符大小写的差别。
-l 列出文件内容符合指定的'搜寻字符串'的文件名称。
-L 列出文件内容不符合指定的'搜寻字符串'的文件名称。
-n 输出该列的行号。
-q 不显示任何信息。
-R/-r 此参数的效果和指定“-d recurse”参数相同。
-s 不显示错误信息。
-v 反转查找。
-w 只显示全字符合的列。
-x 只显示全列符合的列。
-y 此参数效果跟“-i”相同。
-o 只输出文件中匹配到的部分。

**应用示例**



### 参考链接 ###
[awk 入门教程](http://www.ruanyifeng.com/blog/2018/11/awk.html)
[sed 简明教程](https://coolshell.cn/articles/9104.html)


