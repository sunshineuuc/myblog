---
title: CodeIgniter控制器类文件Controller.php
date: 2020-02-16 15:45:41
tags:
- php
- codeigniter
categories:
- web工作笔记
---

#### 引言 ####
 该类为超级控制器类，是我们通常所说的MVC中的C。在项目开发过程中开发的所有的控制器类都要继承自这个文件。在经过路由分发之后，实际的应用Controller接管用户的所有请求，并负责与用户数据的交互。CI中所有的应用控制器都应该是CI_Controller的子类(除非你扩展了CI的核心，那么你的Controller父类可以是MY_Controller)。
<!--more-->

---

#### 成员变量 ####
```text
// 该类为单例模式的类，类的实例不能直接访问，需要通过统一的访问接口进行访问。
// 此处`$instance`用于保存该类的实例，即当前对象`$this`。
private static $instance;
```

---

#### __construct() ####
```text
public function __construct()
{
    // 通过self::$instance实现单例化，静态变量`$instance`表示当前对象。
    self::$instance =& $this;

    // is_loaded()为Common.php文件中定义的全局方法，用于返回已加载的组件(类的实例)。
    // 这里将所有已加载的组件以$this->xxx = &load_class('xxx')的形式赋值给当前对象(超级控制器)，然后就可以直接使用$this->xxx了。
    // 比如：$this->input->post(); $this->security->xss_clean($data); $this->benchmark->mark('controller init start');
    foreach (is_loaded() as $var => $class)
    {
        $this->$var =& load_class($class);
    }
    // Loader组件单独给超级控制器，之后就可以使用$this->load->model('xxx_model'); $this->load->library('xxx');进行加载某个类了。
    $this->load =& load_class('Loader', 'core');
    // 初始化Loader组件。
    $this->load->initialize();
    log_message('info', 'Controller Class Initialized');
}
```

---

#### get_instance() ####
```text
public static function &get_instance()
{
    // $instance为私有变量，外界不能直接访问，所以提供此接口用来获取该类(超级控制器)的实例。
    return self::$instance;
}
```

---

#### 参考链接 ####
[CI框架源码解析十四之控制器类文件Controller.php](https://blog.csdn.net/Zhihua_W/article/details/52948034)
