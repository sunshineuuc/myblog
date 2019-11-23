---
title: 将NGINX注册为Windows系统服务
date: 2019-11-16 11:46:32
tags:
- windows
- nginx
categories:
- web学习笔记
---

### NGINX安装 ###

- 首先在[nginx官网](https://www.nginx.com/)下载到的压缩包，目前稳定版本为[nginx-1.16.1](https://nginx.org/download/nginx-1.16.1.zip)
- 解压后放入D盘
```text
[D:\nginx]$ pwd
D:\nginx
[D:\nginx]$ dir
 驱动器 D 中的卷是 LENOVO
 卷的序列号是 DAB9-EE00

 D:\nginx 的目录

2019/11/16  11:32    <DIR>          .
2019/11/16  11:32    <DIR>          ..
2019/11/15  21:30    <DIR>          conf
2019/11/15  21:30    <DIR>          contrib
2019/11/15  21:30    <DIR>          docs
2019/11/15  21:30    <DIR>          html
2019/11/16  11:44    <DIR>          logs
2019/08/13  21:42         3,697,152 nginx.exe
2019/11/16  11:44    <DIR>          temp
               3 个文件      4,068,736 字节
               8 个目录  5,441,527,808 可用字节
```
- 运行NGINX，直接双击nginx.exe即可

<!-- more -->

### 问题 ###

通过双击运行nginx后，有几点不便：
1. 启停不方便，修改配置后启停nginx需要cmd操作
2. 无法开机自启动

### 解决方案 ###

**将nginx加入到windows服务**
下面介绍使用<code>winsw</code>将nginx加入到windows服务的操作流程：
1. 下载[winsw](https://github.com/kohsuke/winsw/releases/tag/winsw-v2.2.0),目前稳定版为<code>winsw-v2.2.0</code>，本例下载的为<code>WinSW.NET2.exe</code>
2. 将<code>WinSW.NET2.exe</code>重命名为<code>nginxsvr.exe</code>并放入与<code>nginx.exe</code>相同目录下
3. 新建配置文件<code>nginxsvr.xml</code>，参考[这里](https://github.com/kohsuke/winsw/blob/master/doc/xmlConfigFile.md)进行配置，本例配置信息为：
```text
<service>
  <id>nginx-pureven</id>
  <name>nginx-pureven</name>
  <description>nginx服务，嘿嘿</description>
  <logpath>D://nginx//logs\</logpath>
  <executable>D://nginx//nginx.exe</executable>
  <startmode>Automatic</startmode>
  <stopexecutable>-p D://nginx//nginx.exe -s stop</stopexecutable>
  <logpath>D:/nginx/logs/</logpath>
  <logmode>roll</logmode>
</service>
```
4. cmd终端运行<code>nginxsvr.exe install</code>
```text
D:\nginx>nginxsvr.exe install
2019-11-16 11:43:45,440 INFO  - Installing the service with id 'nginx-pureven'
```
5. 加入服务成功，如图：
![](windows_nginx_svr/20191116135032.png)
6. 启动停止可通过服务界面直接操作了，另外配置文件中设置了开机自启，上图可以看到，至此设置完毕！
