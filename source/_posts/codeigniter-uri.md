---
title: CodeIgniter编码类文件URI.php
date: 2020-01-14 21:51:34
tags:
- php
- codeigniter
categories:
- web工作笔记
---

#### 引言 ####
URI类主要处理地址字符串，将**uri**分解成对应的片段并存到**segments**数组中。启用查询字符串则将**查询字符串**分解后存到**$_GET**数组中。**Router路由类**在之后的解析路由动作中，也主要依靠URI类的segments属性数组来获取当前上下文的请求URI信息。<font color="#891717">在CI框架中如果启用查询字符串，URI类将不做任何处理，Router类也只会匹配目录、控制器、方法。CI框架体系中的方法参数都是从URI片段中取的,并按**顺序**传递给方法参数。不支持将参数中的变量通过方法参数名传给方法，只能用$_GET获取。</font>
<!-- more -->
`$config['uri_protocol']`配置不但决定以哪个函数处理URI，同时决定了从哪个全局变量里获取当前上下文的uri地址。对应关系是：
1. `'REQUEST_URI'`使用 `$_SERVER['REQUEST_URI']`。
2. `'QUERY_STRING'`使用 `$_SERVER['QUERY_STRING']`。
3. `'PATH_INFO'`使用 `$_SERVER['PATH_INFO']`。

【注意】: **如果配置为PATH_INFO，则uri需要进行url_decode解码。**
那么这三个变量有什么区别呢？
1. `$_SERVER['REQUEST_URI']`获取的是**url地址中主机头后面所有的字符**。
2. `$_SERVER['QUERY_STRING']`获取的是**url地址中"?"后面的部分**。
3. `$_SERVER['PATH_INFO']`获取的是**url地址中脚本文件`$_SERVER['SCRIPT_NAME']`之后"?"之前的字符内容**。

该类包含5个属性及22个方法，下面分别剖析。
---

#### 类属性 ####
```text
public $keyval = array();
public $uri_string = '';
public $segments = array();
public $rsegments = array();
protected $_permitted_uri_chars;
```
---

#### 构造方法 ####

---

#### _set_uri_string() ####

---

#### _parse_request_uri() ####

---

#### _parse_query_string() ####

---

#### _parse_argv() ####

---

#### _remove_relative_directory() ####

---

#### filter_uri() ####

---

#### segment() ####

---

#### rsegment() ####

---

#### uri_to_assoc() ####

---

#### ruri_to_assoc() ####

---

#### _uri_to_assoc() ####

---

#### assoc_to_uri() ####

---

#### slash_segment() ####

---

#### slash_rsegment ####

---

#### _slash_segment() ####

---

#### segment_array() ####

---

#### rsegment_array() ####

---

#### total_segments() ####

---

#### total_rsegments() ####

---

#### uri_string() ####

---

#### ruri_string() ####

---

#### 参考链接 #### 

[CI框架源码解析八之地址解析类文件URI.php](https://blog.csdn.net/Zhihua_W/article/details/52872407)
