---
title: Nginx配置入门-WNMP(Win10+Nginx+MySQL+PHP)
date: 2020-03-06 09:15:26
tags:
- Nginx
- PHP
- MySQL
categories:
- 开发者手册
---

#### 引言 ####

[上一篇](https://pureven.cc/2020/02/29/nginx-simple-conf-with-static-site/)学习了Nginx配置文件中的基本指令，然后配置了一个静态网站。通过这个网站可以访问指定目录中的静态资源，但是如果向php脚本这样的文件还是无法访问，这是因为php脚本只能由特定的解析器(php解析器)来解析，本文学习Win10环境下配置Nginx和PHP-FPM的环境然后通过Nginx来访问指定目录中的动态资源(php脚本)，同时安装配置并调试MySQL。

<!-- more -->

---

#### PHP下载 ####

下载PHP的**非线程安全版本：**[php-7.4.3-nts-Win32-vc15-x64.zip](https://windows.php.net/download#php-7.4-nts-vc15-x64)。

##### 关于线程安全和非线程安全 #####

Windows版的PHP从版本5.2.1开始有`Thread Safe`。这两者不同在于何处？到底应该用哪种？这里做一个简单的介绍。

从2000年10月20日发布的第一个Windows版的PHP3.0.17开始的都是线程安全的版本，这是由于与Linux/Unix系统是采用`多进程`的工作方式不同的是Windows系统是采用`多线程`的工作方式。如果在IIS下以CGI方式运行PHP会非常慢，这是由于CGI模式是建立在多进程 的基础之上的，而非多线程。一般我们会把PHP配置成以`ISAPI`的方式来运行，ISAPI是多线程的方式，这样就快多了。但存在一个问题，很多常用的 PHP扩展是以Linux/Unix的多进程思想来开发的，这些扩展在ISAPI的方式运行时就会出错搞垮IIS。而用线程安全版本的话顶多只是搞跨某个 线程，而不会影响到整个IIS的安全。
    
当然在IIS下CGI模式才是 PHP运行的最安全方式，但CGI模式对于每个HTTP请求都需要重新加载和卸载整个PHP环境，其消耗是巨大的。为了兼顾IIS下PHP的效率和安全， 有人给出了FastCGI的解决方案。FastCGI可以让PHP的进程重复利用而不是每一个新的请求就重开一个进程。同时FastCGI也可以允许几个 进程同时执行。这样既解决了CGI进程模式消耗太大的问题，又利用上了CGI进程模式不存在线程安全问题的优势。

`因此，如果是使用ISAPI的方式来运行PHP就必须用Thread Safe(线程安全)的版本；而用FastCGI模式运行PHP的话就没有必要用线程安全检查了，用None Thread Safe(NTS，非线程安全)的版本能够更好的提高效率。`

---

#### PHP配置 ####

1. 进入`php-7.4.3-nts-Win32-vc15-x64`目录，拷贝一份`php.ini-development`并将文件名修改为`php.ini`。
2. 修改`php.ini`:
```yaml
; On windows:
extension_dir = "G:\Nginx+php+mysql\php-7.4.3-nts-Win32-vc15-x64\ext"

extension=curl
extension=mbstring
extension=exif      ; Must be after mbstring as it depends on it
extension=mysqli
extension=pdo_mysql

; http://php.net/cgi.fix-pathinfo
cgi.fix_pathinfo=1

[Date]
; Defines the default timezone used by the date functions
; http://php.net/date.timezone
date.timezone = 'Asia/Shanghai'
```

---

#### Nginx配置 ####
```yaml
server {
    listen       6688;
    server_name  localhost;
    
    # 定义与FastCGI服务器建立连接的超时时间。应该指出的是，这个超时通常不能超过75秒。
    fastcgi_connect_timeout 120s;
    # 定义从FastCGI服务器读取响应的超时时间。超时只在两次连续的读操作之间设置，而不是用于传输整个响应。
    # 如果FastCGI服务器在此时间内没有传输任何内容，则连接将被关闭。
    fastcgi_read_timeout 300s;
    # 设置向FastCGI服务器发送请求的超时时间。超时只在两次连续写入操作之间设置，而不是用于传输整个请求。
    # 如果FastCGI服务器在此时间内没有收到任何内容，则连接将关闭。
    fastcgi_send_timeout 300s;
    
    # 设置number和size用于读取从FastCGI的服务器的响应，供用于单个连接的缓冲器。
    # 默认情况下，缓冲区大小等于一个内存页面。这是4K或8K，取决于平台。
    fastcgi_buffers 256 16k; 
    fastcgi_buffer_size 128k; 
    # 当启用FastCGI服务器的响应缓冲时，限制size可能正忙于向客户端发送响应的缓冲区总数，而响应尚未完全读取。
    # 同时，其余的缓冲区可以用于读取响应，并且如果需要的话，缓冲部分对临时文件的响应。
    # 默认情况下，size受fastcgi_buffer_size和fastcgi_buffers指令设置的两个缓冲区大小的限制。
    fastcgi_busy_buffers_size 256k; 
    # size一旦启用了从FastCGI服务器到临时文件的缓存响应，就一次限制写入临时文件的数据。
    # 默认情况下，size由fastcgi_buffer_size和fastcgi_buffers指令设置的两个缓冲区限制。
    # 临时文件的最大大小由fastcgi_max_temp_file_size指令设置。
    fastcgi_temp_file_write_size 256k;
    
    root "E:/CodeIgniter_hmvc";
    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:8888
    #
    location ~ \.php$ {
        root           G:\Nginx+php+mysql\html;
        # 设置FastCGI服务器的地址。该地址可以指定为域名或IP地址，以及端口：localhost:9000;
        # 或者作为UNIX域套接字路径：unix:/tmp/fastcgi.socket;
        fastcgi_pass   127.0.0.1:8888;
        # 在$fastcgi_script_name变量的值中设置一个文件名，该文件名将附加在以斜杠结尾的URI后面。
        fastcgi_index  index.php;
        # 设置一个parameter应该传递给FastCGI服务器的应用程序。该value可以包含文本，变量，他们的组合。
        # 当且仅当没有fastcgi_param在当前级别上定义的指令时，这些指令才从前一级继承。
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; # 针对当前请求的根路径设置值 . 脚本名称
        include        fastcgi_params;
    }
    
    # 这里使用try_files
    # ① 当请求localhost:6688/api/migrate时先在root下找api文件
    # ② 找不到就在root/api/下找migrate文件
    # ③ 找不到就请求root/api/index.php并将migrate作为参数传递给fastcgi
    location ^~ /api {
        index index.php;

        try_files $uri $uri/ /api/index.php;
        
        location = /api/index.php {
            fastcgi_pass   127.0.0.1:8888;
            fastcgi_index  index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include        fastcgi_params;
        }
    }
}
```
`fastcig`相关指令参考[ngx_http_fastcgi_module](https://cloud.tencent.com/developer/section/1259146)

---

#### 开启PHP-fpm服务 ####

```yaml
[G:\Nginx+php+mysql]$ cd php-7.4.3-nts-Win32-vc15-x64
[G:\Nginx+php+mysql\php-7.4.3-nts-Win32-vc15-x64]$ php-cgi.exe -b 127.0.0.1:8888 -c php.ini
```

---

#### 重启Nginx ####
```yaml
[G:\Nginx+php+mysql\nginx-1.17.8]$ nginx.exe -s reload
```

---

#### 测试 ####

1. 创建index.php文件
```yaml
[G:\Nginx+php+mysql]$ cd html
[G:\Nginx+php+mysql\html]$ dir
 驱动器 G 中的卷是 研发专用
 卷的序列号是 5861-182A

 G:\Nginx+php+mysql\html 的目录

2020/03/06  08:51    <DIR>          .
2020/03/06  08:51    <DIR>          ..
2020/01/21  21:39               494 50x.html
2020/03/06  08:51    <DIR>          ci
2020/01/21  21:39               612 index.html
2020/03/06  14:24                24 index.php
               3 个文件          1,130 字节
               3 个目录 31,849,316,352 可用字节

[G:\Nginx+php+mysql\html]$ type index.php
<?php

echo phpinfo();
[G:\Nginx+php+mysql\html]$ 
```
2. 访问index.php
![](nginx-simple-conf-with-php-fpm/20200306144934.png)

---

#### 将PHP-fpm注册为服务 ####

下面介绍使用<code>winsw</code>将nginx加入到windows服务的操作流程：
1. 下载[winsw](https://github.com/kohsuke/winsw/releases/tag/winsw-v2.2.0),目前稳定版为<code>winsw-v2.2.0</code>，本例下载的为<code>WinSW.NET2.exe</code>
2. 将<code>WinSW.NET2.exe</code>重命名为<code>php-pureven.exe</code>并放入与<code>php-cgi.exe</code>相同目录下
3. 新建配置文件<code>php-pureven.xml</code>，参考[这里](https://github.com/kohsuke/winsw/blob/master/doc/xmlConfigFile.md)进行配置，本例配置信息为：
```xml
<configuration>
  <!-- ID of the service. It should be unique accross the Windows system-->
  <id>PHP-pureven</id>
  <!-- Display name of the service -->
  <name>PHPCGI-pureven</name>
  <!-- Service description -->
  <description>Serve PHPCGI on 8888 by pureven</description>
  
  <!-- Path to the executable, which should be started -->
  <executable>G:\Nginx+php+mysql\php-7.4.3-nts-Win32-vc15-x64\php-cgi.exe</executable>

  <onfailure action="restart" delay="20 sec"/>

  <arguments>-b 127.0.0.1:8888 -c "G:\Nginx+php+mysql\php-7.4.3-nts-Win32-vc15-x64\php.ini"</arguments>

  <!--
  <startarguments>-b 127.0.0.1:8888 -c "G:\Nginx+php+mysql\php-7.4.3-nts-Win32-vc15-x64\php.ini"</startarguments>
  -->
  
  <priority>Normal</priority>

  <stoptimeout>30 sec</stoptimeout>

  <stopparentprocessfirst>false</stopparentprocessfirst>

  <stopexecutable>taskkill</stopexecutable>

  <stoparguments>/f /IM php-cgi.exe</stoparguments>-->

  <startmode>Automatic</startmode>
  <!--
  <delayedAutoStart/>
  -->

  <waithint>15 sec</waithint>

  <sleeptime>1 sec</sleeptime>
  
  <logpath>G:\Nginx+php+mysql\php-7.4.3-nts-Win32-vc15-x64\logs</logpath>
  <log mode="roll-by-size">
    <sizeThreshold>10240</sizeThreshold>
    <keepFiles>8</keepFiles>
  </log>

  <env name="PHP_FCGI_MAX_REQUESTS" value="3000" />
  <env name="PHP_FCGI_CHILDREN" value="12" />
  <env name="CI_ENV" value="production" />

  <beeponshutdown/>

</configuration>
```
4. 管理员权限通过cmd终端运行<code>php-pureven.exe install</code>
```text
G:\Nginx+php+mysql\php-7.4.3-nts-Win32-vc15-x64>php-pureven.exe install
2020-03-06 15:26:50,233 INFO  - Installing the service with id 'PHP-pureven'
```
5. 加入服务成功，如图：
![](nginx-simple-conf-with-php-fpm/20200306153358.png)
6. 启动停止可通过服务界面直接操作了，另外配置文件中设置了开机自启，上图可以看到，至此设置完毕！

---

#### Linux下安装配置Nginx + PHP-fpm ####

请参考[Nginx中文官方文档-nginx php-fpm安装配置](https://wizardforcel.gitbooks.io/nginx-doc/content/Text/6.5_nginx_php_fpm.html)

---

#### MySQL下载配置 ####

##### 下载[MySQL-5.7.28](https://dev.mysql.com/downloads/mysql/)安装包并解压到目录`G:\Nginx+php+mysql` #####
```markdown
[G:\Nginx+php+mysql]$ cd mysql-5.7.28-winx64
[G:\Nginx+php+mysql\mysql-5.7.28-winx64]$ dir
 驱动器 G 中的卷是 研发专用
 卷的序列号是 5861-182A

 G:\Nginx+php+mysql\mysql-5.7.28-winx64 的目录

2020/03/12  08:40    <DIR>          .
2020/03/12  08:40    <DIR>          ..
2020/03/12  08:40    <DIR>          bin
2020/03/12  08:40    <DIR>          docs
2020/03/12  08:40    <DIR>          include
2020/03/12  08:40    <DIR>          lib
2019/12/10  03:53           405,571 LICENSE
2019/12/10  03:53               687 README
2020/03/12  08:40    <DIR>          share
               2 个文件        406,258 字节
               7 个目录 30,955,925,504 可用字节
```

##### 在`G:\Nginx+php+mysql\mysql-5.7.28-winx64`目录下新建文件`my.ini` #####
```yaml
[G:\Nginx+php+mysql\mysql-5.7.28-winx64]$ type my.ini
[mysqld]
# 设置3306端口
port=3306
# 设置mysql的安装目录
basedir=G:\Nginx+php+mysql\mysql-5.7.28-winx64
# 设置mysql数据库的数据的存放目录
datadir=G:\Nginx+php+mysql\mysql-5.7.28-winx64\data
# 允许最大连接数
max_connections=200
# 允许连接失败的次数。这是为了防止有人从该主机试图攻击数据库系统
max_connect_errors=10
# 服务端使用的字符集默认为UTF8
character-set-server=utf8
# 创建新表时将使用的默认存储引擎
default-storage-engine=INNODB
# 默认使用“mysql_native_password”插件认证
default_authentication_plugin=mysql_native_password
[mysql]
# 设置mysql客户端默认字符集
default-character-set=utf8
[client]
# 设置mysql客户端连接服务端时默认使用的端口
port=3306
default-character-set=utf8
```

##### 环境变量设置 #####
**将MySQL解压后的目录加入环境变量`MYSQL_HOME`**
![](nginx-simple-conf-with-php-fpm/20200312085658.png)

**将bin目录绝对路径加入系统变量`path`**
```yaml
%MYSQL_HOME\bin% ==> path # 此处不是代码，理解万岁
```

##### 数据库服务初始化 #####
```yaml
G:\Nginx+php+mysql\mysql-5.7.28-winx64\bin>mysqld.exe --initialize --console
2020-03-11T13:33:52.368829Z 0 [System] [MY-013169] [Server] G:\Nginx+php+mysql\mysql-5.7.28-winx64\bin\mysqld.exe (mysqld 5.7.28) initializing of server in progress as process 12704
2020-03-11T13:33:52.370320Z 0 [Warning] [MY-013242] [Server] --character-set-server: 'utf8' is currently an alias for the character set UTF8MB3, but will be an alias for UTF8MB4 in a future release. Please consider using UTF8MB4 in order to be unambiguous.
2020-03-11T13:34:00.541307Z 5 [Note] [MY-010454] [Server] A temporary password is generated for root@localhost: iw.r)rhp)7jX
```
注意最后一行中的`iw.r)rhp)7jX`是默认生成的密码。

##### 安装并启动MySQL服务 #####
```yaml
G:\Nginx+php+mysql\mysql-5.7.28-winx64\bin>mysqld.exe install pureven-MySQL-5.7.28
Service successfully installed.

G:\Nginx+php+mysql\mysql-5.7.28-winx64\bin>net start mysql
MySQL 服务正在启动 ..
MySQL 服务已经启动成功。
```
**注：可通过`sc delete pureven-MySQL-5.7.28`命令删除`pureven-MySQL`服务。**

##### 登录数据库并修改密码 #####
```yaml
G:\Nginx+php+mysql\mysql-5.7.28-winx64\bin>mysql.exe -u root -p
Enter password: ************ # 这里使用的密码是上面初始化后系统生成的密码：iw.r)rhp)7jX
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 8
Server version: 5.7.28

Copyright (c) 2000, 2020, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> set password for root@localhost='xxxxxx'; # 修改密码为6个x，即xxxxxx
Query OK, 0 rows affected (0.03 sec)

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
4 rows in set (0.01 sec)
```
