---
title: PHPStorm配置Xdebug断点调试
date: 2020-05-03 19:48:40
tags:
- PHPStorm
- PHP
categories:
- Tools
---

#### 引言 ####

厌倦了通过`var_dump()`、`var_export()`、`print_r()`等命令加`exit()`命令调试代码可以使用**Xdebug**来调试。
<!-- more -->

---

#### 原理 ####

XDebug调试是一种C/S结构，Client是PHP-Xdebug插件，Server是我们的IDE（或者各种Editor插件），中间通过DBGp协议通信。PHP脚本在运行时，由Xdebug插件向IDE发起连接，将调试信息发送给IDE，并通过DBGp协议进行互动。详细结束可参考[官网说明](https://xdebug.org/docs/remote)。

---

#### 安装配置 ####

##### 安装 #####
下载Xdebug，先打印phpinfo()信息，然后`右键->源码`复制源码信息到[https://xdebug.org/wizard](https://xdebug.org/wizard)，点击`分析我的phpinfo()输出`可以看到当前php环境对应的Xdebug版本，点击下载即可。

下载完成后根据提示放入对应的php安装目录的`ext`目录下，如`G:\Nginx+php+mysql\php-7.4.3-nts-Win32-vc15-x64\ext\php_xdebug-2.9.5-7.4-vc15-nts-x86_64.dll`。

##### 配置 #####
在php.ini文件中进行Xdebug相关设置，相关配置说明[参考官网](https://xdebug.org/docs/all_settings)
```ini
[XDebug]
xdebug.profiler_enable=on ; 启用性能检测分析
xdebug.auto_trace=on      ; 启用代码自动跟踪
xdebug.collect_params=on  ; 允许收集传递给函数的参数变量
xdebug.collect_return=on  ; 允许收集函数调用的返回值
xdebug.profiler_output_dir="G:\Nginx+php+mysql\tmp\xdebug" ; 指定性能分析文件的存放目录
xdebug.trace_output_dir="G:\Nginx+php+mysql\tmp\xdebug"    ; 指定堆栈跟踪文件的存放目录
zend_extension = "G:\Nginx+php+mysql\php-7.4.3-nts-Win32-vc15-x64\ext\php_xdebug-2.9.5-7.4-vc15-nts-x86_64.dll" # 扩展文件绝对路径
xdebug.remote_enable=on     ; 打开远程调试开关
xdebug.remote_handler=dbgp  ; 
xdebug.remote_mode=req      ; 
xdebug.remote_port=9100     ; 此处为客户端监听端口，即debug信息通过此端口传递给客户端，如PHPStorm，所以不要与服务器监听的端口冲突，比如Apache或Nginx
xdebug.idekey="PHPSTORM"    ;  
```
---

#### 配置PHPStorm ####

##### 添加PHP Debug Servers #####
点击`File -> Settings -> Languages & Frameworks -> PHP -> Debug -> Servers`，点击`+`号添加站点地址和端口以及Debugger类型，如图
![](20200503223425.png)
点击`apply`及`OK`。

##### 添加PHP Web Page #####
点击`Run -> Edit Configurations`，点击`+`号选择`PHP Web Page`，选择上面添加的服务，然后设置入口文件，如`/index.php`，配置如图
![](20200503224221.png)

---

#### 调试 ####
PHPStorm选择添加的`PHP Web Page`，设置好断点，点击绿色小虫虫图标就可以看到文件中加载的变量信息了，如图
![](20200503224637.png)

---

#### 参考链接 ####
[Phpstorm+Xdebug配置断点调试](https://segmentfault.com/a/1190000019811298)
[PHP xdebug 调试工具安装与使用](https://segmentfault.com/a/1190000011332021)
