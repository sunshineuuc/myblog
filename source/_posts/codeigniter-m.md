---
title: CodeIgniter模型类文件Model.php
date: 2020-02-16 17:33:03
tags:
- php
- codeigniter
categories:
- web工作笔记
---

#### 引言 ####
该类就是MVC中的M。在项目开发过程中定义的模型都要继承这个文件。
<!-- more -->

---

#### __construct() ####
```php
public function __construct() {}
```

---

#### __get() ####
```php
public function __get($key)
{
    // 这里定义了一个魔术方法，当在model类中去加载别的model或library，则需要使用超级控制器中已实例化的相关对象。
    return get_instance()->$key;
}
```

#### 参考链接 ####
[CI框架源码解析十五之模型类文件Model.php](https://blog.csdn.net/Zhihua_W/article/details/52953226)
