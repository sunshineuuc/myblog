---
title: grep sed awk 入门
date: 2019-11-09 7:36:20
tags:
- Command
- Linux
categories:
- 学习笔记
---


### grep ###

#### 前言 ####

grep是一个最初用于Unix操作系统的命令行工具。由<code>Kenneth Lane Thompson</code>写成。grep原先是ed下的一个应用程序，名称来自于g/re/p（globally search a regular expression and print，**利用正则表达式在指定文件中进行全局搜索并将搜索到的行打印出来**）。在给出文件列表或标准输入后，grep会对匹配一个或多个正则表达式的文本进行搜索，并只输出匹配（或者不匹配）的行或文本。摘自[维基百科](https://zh.wikipedia.org/wiki/Grep)。可以将grep理解为**字符查找工具**，类似于<code>ctrl + F</code>。

#### 语法形式 ####

````text
[root@pureven ~]# grep --help
用法: grep [选项]... PATTERN [FILE]...
在每个 FILE 或是标准输入中查找 PATTERN。
默认的 PATTERN 是一个基本正则表达式(缩写为 BRE)。
例如: grep -i 'hello world' menu.h main.c

正则表达式选择与解释:
  -E, --extended-regexp     PATTERN 是一个可扩展的正则表达式(缩写为 ERE)
  -F, --fixed-strings       PATTERN 是一组由断行符分隔的定长字符串。
  -G, --basic-regexp        PATTERN 是一个基本正则表达式(缩写为 BRE)
  -P, --perl-regexp         PATTERN 是一个 Perl 正则表达式
  -e, --regexp=PATTERN      用 PATTERN 来进行匹配操作
  -f, --file=FILE           从 FILE 中取得 PATTERN
  -i, --ignore-case         忽略大小写
  -w, --word-regexp         强制 PATTERN 仅完全匹配字词
  -x, --line-regexp         强制 PATTERN 仅完全匹配一行
  -z, --null-data           一个 0 字节的数据行，但不是空行

Miscellaneous:
  -s, --no-messages         suppress error messages
  -v, --invert-match        select non-matching lines
  -V, --version             display version information and exit
      --help                display this help text and exit

输出控制:
  -m, --max-count=NUM       NUM 次匹配后停止
  -b, --byte-offset         输出的同时打印字节偏移
  -n, --line-number         输出的同时打印行号
      --line-buffered       每行输出清空
  -H, --with-filename       为每一匹配项打印文件名
  -h, --no-filename         输出时不显示文件名前缀
      --label=LABEL         将LABEL 作为标准输入文件名前缀
  -o, --only-matching       show only the part of a line matching PATTERN
  -q, --quiet, --silent     suppress all normal output
      --binary-files=TYPE   assume that binary files are TYPE;
                            TYPE is 'binary', 'text', or 'without-match'
  -a, --text                equivalent to --binary-files=text
  -I                        equivalent to --binary-files=without-match
  -d, --directories=ACTION  how to handle directories;
                            ACTION is 'read', 'recurse', or 'skip'
  -D, --devices=ACTION      how to handle devices, FIFOs and sockets;
                            ACTION is 'read' or 'skip'
  -r, --recursive           like --directories=recurse
  -R, --dereference-recursive
                            likewise, but follow all symlinks
      --include=FILE_PATTERN
                            search only files that match FILE_PATTERN
      --exclude=FILE_PATTERN
                            skip files and directories matching FILE_PATTERN
      --exclude-from=FILE   skip files matching any file pattern from FILE
      --exclude-dir=PATTERN directories that match PATTERN will be skipped.
  -L, --files-without-match print only names of FILEs containing no match
  -l, --files-with-matches  print only names of FILEs containing matches
  -c, --count               print only a count of matching lines per FILE
  -T, --initial-tab         make tabs line up (if needed)
  -Z, --null                print 0 byte after FILE name

文件控制:
  -B, --before-context=NUM  打印以文本起始的NUM 行
  -A, --after-context=NUM   打印以文本结尾的NUM 行
  -C, --context=NUM         打印输出文本NUM 行
  -NUM                      same as --context=NUM
      --group-separator=SEP use SEP as a group separator
      --no-group-separator  use empty string as a group separator
      --color[=WHEN],
      --colour[=WHEN]       use markers to highlight the matching strings;
                            WHEN is 'always', 'never', or 'auto'
  -U, --binary              do not strip CR characters at EOL (MSDOS/Windows)
  -u, --unix-byte-offsets   report offsets as if CRs were not there
                            (MSDOS/Windows)

‘egrep’即‘grep -E’。‘fgrep’即‘grep -F’。
直接使用‘egrep’或是‘fgrep’均已不可行了。
若FILE 为 -，将读取标准输入。不带FILE，读取当前目录，除非命令行中指定了-r 选项。
如果少于两个FILE 参数，就要默认使用-h 参数。
如果有任意行被匹配，那退出状态为 0，否则为 1；
如果有错误产生，且未指定 -q 参数，那退出状态为 2。

请将错误报告给: bug-grep@gnu.org
GNU Grep 主页: <http://www.gnu.org/software/grep/>
GNU 软件的通用帮助: <http://www.gnu.org/gethelp/>
[root@pureven ~]# 

````

----

#### 应用示例 ####

##### 在文件中查找字符串 #####

- 在文件pwd.info中查找“spool”：默认**区分大小写**
```
[root@pureven Documents]# cat pwd.info 
   ROOT:X:0:0:ROOT:/ROOT:/BIN/BASH
   BIN:X:1:1:BIN:/BIN:/SBIN/NOLOGIN
   DAEMON:X:2:2:DAEMON:/SBIN:/SBIN/NOLOGIN
   ADM:X:3:4:ADM:/VAR/ADM:/SBIN/NOLOGIN
   LP:X:4:7:LP:/VAR/SPOOL/LPD:/SBIN/NOLOGIN
   sync:x:5:0:sync:/sbin:/bin/sync
   shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
   halt:x:7:0:halt:/sbin:/sbin/halt
   mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
   operator:x:11:0:operator:/root:/sbin/nologin
   [root@pureven Documents]# grep "spool" pwd.info 
   mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
```

##### 不区分大小写 -i #####

- 在文件pwd.info中查找“spool”及“SPOOL”，使用<code>-i</code>**选项**
```
[root@pureven Documents]# cat pwd.info 
ROOT:X:0:0:ROOT:/ROOT:/BIN/BASH
BIN:X:1:1:BIN:/BIN:/SBIN/NOLOGIN
DAEMON:X:2:2:DAEMON:/SBIN:/SBIN/NOLOGIN
ADM:X:3:4:ADM:/VAR/ADM:/SBIN/NOLOGIN
LP:X:4:7:LP:/VAR/SPOOL/LPD:/SBIN/NOLOGIN
sync:x:5:0:sync:/sbin:/bin/sync
shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
halt:x:7:0:halt:/sbin:/sbin/halt
mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
operator:x:11:0:operator:/root:/sbin/nologin
[root@pureven Documents]# grep -i "spool" pwd.info 
LP:X:4:7:LP:/VAR/SPOOL/LPD:/SBIN/NOLOGIN
mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
```

##### 显示匹配行在文件中的行号 -n #####

- 在文件pwd.info中查找“spool”，显示匹配行在文件中的行号，使用<code>-n</code>**选项** 
```
[root@pureven Documents]# cat pwd.info 
ROOT:X:0:0:ROOT:/ROOT:/BIN/BASH
BIN:X:1:1:BIN:/BIN:/SBIN/NOLOGIN
DAEMON:X:2:2:DAEMON:/SBIN:/SBIN/NOLOGIN
ADM:X:3:4:ADM:/VAR/ADM:/SBIN/NOLOGIN
LP:X:4:7:LP:/VAR/SPOOL/LPD:/SBIN/NOLOGIN
sync:x:5:0:sync:/sbin:/bin/sync
shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
halt:x:7:0:halt:/sbin:/sbin/halt
mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
operator:x:11:0:operator:/root:/sbin/nologin
[root@pureven Documents]# grep -i -n "spool" pwd.info 
5:LP:X:4:7:LP:/VAR/SPOOL/LPD:/SBIN/NOLOGIN
9:mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
```

##### 获取匹配行数 -c #####

- 在文件pwd.info中查找“spool”，显示匹配行的总数，使用<code>-c</code>**选项**
````
[root@pureven Documents]# grep -i "spool" pwd.info 
LP:X:4:7:LP:/VAR/SPOOL/LPD:/SBIN/NOLOGIN
mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
[root@pureven Documents]# grep -i -c  "spool" pwd.info 
2
````
**注意：**<code>-c</code>选项只会打印总行数，不会打印行内容

##### 显示匹配信息上下文 -A{num}/-B{num}/-C{num} #####

- 当需要了解匹配信息上下文时，需要用到文件控制部分的<code>-A</code>、<code>-B</code>、<code>-C</code>选项:
>  -B, --before-context=NUM  打印以文本起始的NUM 行
   -A, --after-context=NUM   打印以文本结尾的NUM 行
   -C, --context=NUM         打印输出文本NUM 行
   换言之
   <code>-B2</code>将会输出匹配行以及匹配行下面的2行
   <code>-A2</code>将会输出匹配行以及匹配行上面的2行
   <code>-C2</code>将会输出匹配行以及匹配行上下文各2行
```
[root@pureven Documents]# grep -n "SPOOL" pwd.info 
5:LP:X:4:7:LP:/VAR/SPOOL/LPD:/SBIN/NOLOGIN
[root@pureven Documents]# grep -n -A2 "SPOOL" pwd.info 
5:LP:X:4:7:LP:/VAR/SPOOL/LPD:/SBIN/NOLOGIN
6-sync:x:5:0:sync:/sbin:/bin/sync
7-shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
[root@pureven Documents]# grep -n -B2 "SPOOL" pwd.info 
3-DAEMON:X:2:2:DAEMON:/SBIN:/SBIN/NOLOGIN
4-ADM:X:3:4:ADM:/VAR/ADM:/SBIN/NOLOGIN
5:LP:X:4:7:LP:/VAR/SPOOL/LPD:/SBIN/NOLOGIN
[root@pureven Documents]# grep -n -C2 "SPOOL" pwd.info 
3-DAEMON:X:2:2:DAEMON:/SBIN:/SBIN/NOLOGIN
4-ADM:X:3:4:ADM:/VAR/ADM:/SBIN/NOLOGIN
5:LP:X:4:7:LP:/VAR/SPOOL/LPD:/SBIN/NOLOGIN
6-sync:x:5:0:sync:/sbin:/bin/sync
7-shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
[root@pureven Documents]#
```

##### words 匹配 -w #####

- 在文件pwd.info中查找单词“spool”，即<code>spool</code>作为独立的单词存在，使用<code>-w</code>**选项**
```text
[root@pureven Documents]# cat pwd.info 
hello ROOT:X:0:0:ROOT:/ROOT:/BIN/BASH
world BIN:X:1:1:BIN:/BIN:/SBIN/NOLOGIN
helloDAEMON:X:2:2:DAEMON:/SBIN:/SBIN/NOLOGIN
worldADM:X:3:4:ADM:/VAR/ADM:/SBIN/NOLOGIN
helloLP:X:4:7:LP:/VAR/SPOOL/LPD:/SBIN/NOLOGIN
grep sync:x:5:0:sync:/sbin:/bin/sync
grepshutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
hello halt:x:7:0:halt:/sbin:/sbin/halt
grep mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
world operator:x:11:0:operator:/root:/sbin/nologin
[root@pureven Documents]# 
[root@pureven Documents]# grep "grep" pwd.info 
grep sync:x:5:0:sync:/sbin:/bin/sync
grepshutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
grep mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
[root@pureven Documents]# 
[root@pureven Documents]# grep -w "grep" pwd.info 
grep sync:x:5:0:sync:/sbin:/bin/sync
grep mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
[root@pureven Documents]#
```

##### 反向查找 -v #####

- 在文件pwd.info中查找不包含“spool”的行，使用<code>-v</code>**选项**
```
[root@pureven Documents]# cat pwd.info 
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
[root@pureven Documents]# grep -n "sbin" pwd.info 
2:bin:x:1:1:bin:/bin:/sbin/nologin
3:daemon:x:2:2:daemon:/sbin:/sbin/nologin
4:adm:x:3:4:adm:/var/adm:/sbin/nologin
5:lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
6:sync:x:5:0:sync:/sbin:/bin/sync
7:shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
8:halt:x:7:0:halt:/sbin:/sbin/halt
9:mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
10:operator:x:11:0:operator:/root:/sbin/nologin
[root@pureven Documents]# grep -v -n "sbin" pwd.info 
1:root:x:0:0:root:/root:/bin/bash
```

##### 同时匹配多个字符串 -e #####

- 在文件中同时匹配多个字符串，只要有一个字符串匹配就说明此行匹配成功，使用<code>-e</code>**选项**
```text
[root@pureven Documents]# cat char.list 
a b c d e f g
h i j k l m n
o p q r s t
u v w x y z
[root@pureven Documents]# grep "a" char.list 
a b c d e f g
[root@pureven Documents]# grep "i" char.list 
h i j k l m n
[root@pureven Documents]# grep -e "a" -e "i" char.list 
a b c d e f g
h i j k l m n
```

##### 静默模式 -q #####

- 如果不关心在文件中匹配的行信息以及上下文，只关心是否匹配成功，则需要使用<code>-q</code>**选项**
使用-q在文件中进行匹配有三个结果：
> 0：匹配成功
1：匹配失败
2：匹配文件不存在
```
[root@pureven Documents]# cat char.list 
a b c d e f g
h i j k l m n
o p q r s t
u v w x y z
[root@pureven Documents]# grep -q "a" char.list 
[root@pureven Documents]# echo $?
0
[root@pureven Documents]# grep -q "+" char.list 
[root@pureven Documents]# echo $?
1
[root@pureven Documents]# grep -q "a" char.lists
grep: char.lists: 没有那个文件或目录
[root@pureven Documents]# echo $?
2
[root@pureven Documents]#
```

##### 正则表达式 -E/egrep #####

- <code>grep</code>支持使用扩展的正则表达式模式来匹配字符串，需要使用**-E**选项或直接使用<code>egrep</code>
```
[root@pureven Documents]# cat char.list 
a b c d e f g
h i j k l m n
o p q r s t
u v w x y z
[root@pureven Documents]# grep "a" char.list 
a b c d e f g
[root@pureven Documents]# grep "i" char.list 
h i j k l m n
[root@pureven Documents]# grep -e "a" -e "i" char.list 
a b c d e f g
h i j k l m n
[root@pureven Documents]# grep -E 'a|i' char.list 
a b c d e f g
h i j k l m n
[root@pureven Documents]#
```
其中<code>'a|i'</code>表示<code>a或i</code>

#### 参考链接 ####

本文归纳的不全，如果不满足自己的需求可参考下列链接:
[https://linux.cn/article-6941-1.html](https://linux.cn/article-6941-1.html)
[https://www.zsythink.net/archives/1733](https://www.zsythink.net/archives/1733)

----

### sed ###

#### 引言 ####

sed是<code>stream editor(流编辑器)</code>的缩写，是一个使用简单紧凑的编程语言来解析和转换文本的Unix实用程序。sed由贝尔实验室的Lee E. McMahon于1973年至1974年开发，并且现在大多数操作系统都可以使用。 
sed基于交互式编辑器ed（“editor”，1971）和早期qed（“quick editor”，1965-66）的脚本功能。sed是最早支持**正则表达式**的工具之一，至今仍然用于**文本处理**，特别是用于**替换**命令。
摘自[维基百科](https://zh.wikipedia.org/wiki/Sed)

----

#### 语法形式 ####

```text
[root@pureven Documents]# sed --help
用法: sed [选项]... {脚本(如果没有其他脚本)} [输入文件]...

  -n, --quiet, --silent
                 取消自动打印模式空间
  -e 脚本, --expression=脚本
                 添加“脚本”到程序的运行列表
  -f 脚本文件, --file=脚本文件
                 添加“脚本文件”到程序的运行列表
  --follow-symlinks
                 直接修改文件时跟随软链接
  -i[SUFFIX], --in-place[=SUFFIX]
                 edit files in place (makes backup if SUFFIX supplied)
  -c, --copy
                 use copy instead of rename when shuffling files in -i mode
  -b, --binary
                 does nothing; for compatibility with WIN32/CYGWIN/MSDOS/EMX (
                 open files in binary mode (CR+LFs are not treated specially))
  -l N, --line-length=N
                 指定“l”命令的换行期望长度
  --posix
                 关闭所有 GNU 扩展
  -r, --regexp-extended
                 在脚本中使用扩展正则表达式
  -s, --separate
                 将输入文件视为各个独立的文件而不是一个长的连续输入
  -u, --unbuffered
                 从输入文件读取最少的数据，更频繁的刷新输出
  -z, --null-data
                 separate lines by NUL characters
  --help
                 display this help and exit
  --version
                 output version information and exit

如果没有 -e, --expression, -f 或 --file 选项，那么第一个非选项参数被视为
sed脚本。其他非选项参数被视为输入文件，如果没有输入文件，那么程序将从标准
输入读取数据。
GNU sed home page: <http://www.gnu.org/software/sed/>.
General help using GNU software: <http://www.gnu.org/gethelp/>.
E-mail bug reports to: <bug-sed@gnu.org>.
Be sure to include the word ``sed'' somewhere in the ``Subject:'' field.
```

#### 脚本动作 ####

##### 单词替换 #####

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

##### 替换 s #####

- 每行替换所有的匹配如何实现
```
[root@pureven Documents]# clear
[root@pureven Documents]# cat char.list
a b c d a f g
a b c d a f g
a b c d e f g
h i j k l m n
o p q r s t
u v w x y z
[root@pureven Documents]# sed 's/a/*/' char.list
* b c d a f g
* b c d a f g
* b c d e f g
h i j k l m n
o p q r s t
u v w x y z
[root@pureven Documents]# sed 's/a/*/2' char.list
a b c d * f g
a b c d * f g
a b c d e f g
h i j k l m n
o p q r s t
u v w x y z
[root@pureven Documents]# sed 's/a/*/g' char.list
* b c d * f g
* b c d * f g
* b c d e f g
h i j k l m n
o p q r s t
u v w x y z
[root@pureven Documents]#
```
通过比较可以得出<code>/g</code>的作用是将每行所有的<code>a</code>替换为<code>*</code>。

##### 增加/删除/插入 a/d/i #####

- a表示新增，后面接字符串，这些字符串会在指定行的下一行出现

比如在第二行后增加"hello wrold"，在所有行后增加"hello world"：
```text
[root@pureven Documents]# cat char.list
a b c d e f g
h i j k l m n
o p q r s t
u v w x y z
[root@pureven Documents]# sed '2a hello world' char.list
a b c d e f g
h i j k l m n
hello world
o p q r s t
u v w x y z
[root@pureven Documents]# sed 'a hello world' char.list
a b c d e f g
hello world
h i j k l m n
hello world
o p q r s t
hello world
u v w x y z
hello world
[root@pureven Documents]#
```

- d表示删除，删除指定行

比如删除第二行，删除第二至第四行：
```text
[root@pureven Documents]# cat char.list
a b c d e f g
h i j k l m n
o p q r s t
u v w x y z
[root@pureven Documents]# sed '2d' char.list
a b c d e f g
o p q r s t
u v w x y z
[root@pureven Documents]# sed '2,4d' char.list
a b c d e f g
[root@pureven Documents]#
```

- i表示插入，后面接字符串，这些字符串会在指定行的上一行出现

比如在第二行后插入"hello wrold"，在所有行后插入"hello world"：
```text
[root@pureven Documents]# cat char.list
a b c d e f g
h i j k l m n
o p q r s t
u v w x y z
[root@pureven Documents]# sed '2i hello pureven' char.list
a b c d e f g
hello pureven
h i j k l m n
o p q r s t
u v w x y z
[root@pureven Documents]# sed 'i hello pureven' char.list
hello pureven
a b c d e f g
hello pureven
h i j k l m n
hello pureven
o p q r s t
hello pureven
u v w x y z
[root@pureven Documents]# 
```

##### 行替换 c #####

- c ：取代， c 的后面可以接字串，这些字串可以取代 n1,n2 之间的行！
```text
[root@pureven Documents]# cat char.list
a b c d e f g
a b c d e f g
a b c d e f g
h i j k l m n
o p q r s t
u v w x y z
[root@pureven Documents]# sed '1,4c cc cc cc' char.list
cc cc cc
o p q r s t
u v w x y z
[root@pureven Documents]#
```

##### 搜索 p #####

- p ：打印，亦即将某个选择的数据印出。通常 p 会与参数 sed -n 一起运行～
```text
[root@pureven Documents]# cat char.list
a b c d e f g
h i j k l m n
o p q r s t
u v w x y z
[root@pureven Documents]# sed '/o/p' char.list
a b c d e f g
h i j k l m n
o p q r s t
o p q r s t
u v w x y z
[root@pureven Documents]# sed -n '/o/p' char.list
o p q r s t
[root@pureven Documents]#
```

#### 选项参数 ####

##### 使用文件中的命令进行替换 -f #####

- -f ：添加文件中的命令
```text
[root@pureven Documents]# cat char.list
a b c d a f g
a b c d a f g
a b c d e f g
h i j k l m n
o p q r s t
u v w x y z
[root@pureven Documents]# cat char.sed 
s/a/*/g
s/$/…………/
[root@pureven Documents]# sed -f char.sed char.list
* b c d * f g…………
* b c d * f g…………
* b c d e f g…………
h i j k l m n…………
o p q r s t…………
u v w x y z…………
[root@pureven Documents]#
```

##### 取消自动打印模式 -n #####

- -n ：sed默认会打印经过处理后的所有文本信息， <code>-n</code>则取消这种自动打印的信息，一般和p搭配使用
```
[root@pureven Documents]# cat char.list
a b c d a f g
a b c d a f g
a b c d e f g
h i j k l m n
o p q r s t
u v w x y z
[root@pureven Documents]# sed '2,3a hello pureven' char.list
a b c d a f g
a b c d a f g
hello pureven
a b c d e f g
hello pureven
h i j k l m n
o p q r s t
u v w x y z
[root@pureven Documents]# sed -n '2,3a hello pureven' char.list
hello pureven
hello pureven
[root@pureven Documents]# sed -n '/x/p' char.list
u v w x y z
[root@pureven Documents]# 
```

##### 直接修改文件内容 -i #####

- -i ：直接修改文件内容
```text
[root@pureven Documents]# cat char.list
a b c d e f g
a b c d e f g
a b c d e f g
h i j k l m n
o p q r s t
u v w x y z
[root@pureven Documents]# sed -i '2,3s/a/*/' char.list
[root@pureven Documents]# cat char.list
a b c d e f g
* b c d e f g
* b c d e f g
h i j k l m n
o p q r s t
u v w x y z
[root@pureven Documents]#
```

##### 多个匹配 -e #####

- -e : 指定匹配规则，可添加多个
```text
[root@pureven Documents]# cat char.list
a b c d a f g
a b c d a f g
a b c d e f g
h i j k l m n
o p q r s t
u v w x y z
[root@pureven Documents]# sed -e '2,3s/a/*/' -e 's/$/********/' char.list
a b c d a f g********
* b c d a f g********
* b c d e f g********
h i j k l m n********
o p q r s t********
u v w x y z********
[root@pureven Documents]#
```
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

#### 参考链接 ####
[awk 入门教程](http://www.ruanyifeng.com/blog/2018/11/awk.html)
[sed 简明教程](https://coolshell.cn/articles/9104.html)


