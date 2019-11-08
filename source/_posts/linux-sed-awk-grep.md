---
title: sed awk grep 入门
date: 2019-11-07 17:36:20
tags:
- Command
- Linux
categories:
- 学习笔记
---

### sed ###

#### 名称来源 ####


#### 基本用法 ####

----

### awk ###

#### 前言 ####
AWK是一种优良的文本处理工具，Linux及Unix环境中现有的功能最强大的数据处理引擎之一。名称得自于它的创始人<code>Alfred Aho</code>、<code>Peter Weinberger</code>和<code>Brian Kernighan</code>姓氏的首个字母
AWK提供了极其强大的功能：可以进行<cdoe>正则表达式的匹配</code>，<code>样式装入</code>、<code>流控制</code>、<code>数学运算符</code>、<code>进程控制语句</code>甚至于<code>内置的变量</code>和<code>函数</code>。下面进行简单介绍

----

#### awk的命令格式和选项 ####

**语法形式** 

><code>awk [options] '{action}' (filename)</code>

选项参数说明:
<code>options</code>:
- -F fs or --field-separator fs: 指定输入文件折分隔符，fs是一个字符串或者一个正则表达式
- -v var=value or --asign var=value: 赋值一个用户定义变量
- -f scriptfile or --file scriptfile: 从脚本文件中读取awk命令
- -W help or --help, -W usage or --usage: 打印全部awk选项和每个选项的简短说明

<code>action</code>:为awk语句，表示每一行的处理动作，只能被单引号包含,由<code>条件</code>和<code>动作组成</code>  
<code>filename</code>:表示awk要处理的文本文件。

**举例说明:**
将/etc/passwd前10行写入文件passwd.info
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
```
其信息通过冒号<code>:</code>进行连接，下面通过awk进行格式化显示：
```
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

- FILENAME/NR/FNR/NF 查看
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

<code>substr()</code>函数测试：
```
[root@tony Desktop]# awk -F : '{print substr(FILENAME, 5,4), NF, $(NF-1), $0}' pwd.info 
info 7 /root root:x:0:0:root:/root:/bin/bash
info 7 /bin bin:x:1:1:bin:/bin:/sbin/nologin
info 7 /sbin daemon:x:2:2:daemon:/sbin:/sbin/nologin
info 7 /var/adm adm:x:3:4:adm:/var/adm:/sbin/nologin
info 7 /var/spool/lpd lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
[root@tony Desktop]# 
```

<code>toupper()/tolower()</code>函数测试
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

另外还支持对变量进行重新赋值
```
[root@tony Desktop]# awk -F : '{print toupper(FILENAME), NF, $(NF-1), $0 = "***"}' pwd.info 
PWD.INFO 7 /root ***
PWD.INFO 7 /bin ***
PWD.INFO 7 /sbin ***
PWD.INFO 7 /var/adm ***
PWD.INFO 7 /var/spool/lpd ***
```
$0本来是每行内容的，经过赋值变成了***

----

#### 条件判断 ####

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

----

### grep ###

### 参考链接 ###
[awk 入门教程](http://www.ruanyifeng.com/blog/2018/11/awk.html)
[sed 简明教程](https://coolshell.cn/articles/9104.html)


