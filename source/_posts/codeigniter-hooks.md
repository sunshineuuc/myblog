---
title: CodeIgniter钩子类文件Hooks.php
date: 2019-12-29 17:30:04
tags:
- PHP
- Codeigniter
categories:
- 开发者手册
---

#### 引言 ####
CodeIgniter的钩子特性提供了一种方法来**修改框架的内部运作流程，而无需修改核心文件**。CodeIgniter的运行遵循着一个特定的流程，你可以参考这个页面的[应用程序流程图](https://codeigniter.org.cn/user_guide/overview/appflow.html) 。但是，有些时候你可能希望**在执行流程中的某些阶段添加一些动作**，例如在控制器加载之前或之后执行一段脚本， 或者在其他的某些位置触发你的脚本。上面是摘自[官网](https://codeigniter.org.cn/user_guide/general/hooks.html)的描述，在实际应用中见过一个例子: 在控制器实例化之后控制器的任何方法调用前先进行表单验证，即注册一个表单验证的钩子将表单验证从各个控制器方法中分离出来。
<!-- more -->
---

#### CI中的挂钩点 ####

以下是[官网](https://codeigniter.org.cn/user_guide/general/hooks.html)给出的所有可用挂钩点的一份列表:
- **pre_system** 在系统执行的早期调用，这个时候只有 基准测试类 和 钩子类 被加载了， 还没有执行到路由或其他的流程。
- **pre_controller** 在你的控制器调用之前执行，所有的基础类都已加载，路由和安全检查也已经完成。
- **post_controller_constructor** 在你的控制器实例化之后立即执行，控制器的任何方法都还尚未调用。
- **post_controller** 在你的控制器完全运行结束时执行。
- **display_override** 覆盖 _display() 方法，该方法用于在系统执行结束时向浏览器发送最终的页面结果。 这可以让你有自己的显示页面的方法。注意你可能需要使用 $this->CI =& get_instance() 方法来获取 CI 超级对象，以及使用 $this->CI->output->get_output() 方法来 获取最终的显示数据。
- **cache_override** 使用你自己的方法来替代 输出类 中的 _display_cache() 方法，这让你有自己的缓存显示机制。
- **post_system** 在最终的页面发送到浏览器之后、在系统的最后期被调用。

#### 属性 ####
```text
public $enabled = FALSE;
public $hooks =	array();
protected $_objects = array();
protected $_in_progress = FALSE;
```
1. `$enabled`用于判断钩子是否可用。
2. `$hooks`用于存储配置文件中定义的钩子列表，是一个数组。
3. `$_objects`用于存储钩子类的实例对象。
4. `$_in_progress`用于判断钩子是否正在被调用，防止出现死循环。
---

#### 初始化 ####
```text
public function __construct()
{
    $CFG =& load_class('Config', 'core');
    log_message('info', 'Hooks Class Initialized');
    if ($CFG->item('enable_hooks') === FALSE)
    {
        return;
    }
    if (file_exists(APPPATH.'config/hooks.php'))
    {
        include(APPPATH.'config/hooks.php');
    }
    if (file_exists(APPPATH.'config/'.ENVIRONMENT.'/hooks.php'))
    {
        include(APPPATH.'config/'.ENVIRONMENT.'/hooks.php');
    }
    if ( ! isset($hook) OR ! is_array($hook))
    {
        return;
    }
    $this->hooks =& $hook;
    $this->enabled = TRUE;
}
```
该方法将完成组件钩子初始化，功能实现:
1. 加载配置类，检查配置文件中`enable_hooks`是否开启，该参数可用在`APPPATH.config/config.php`文件中进行设置。
2. 如果启用了hook功能，则继续加载`hooks.php`文件。如果有对应开发环境特定的钩子配置文件则加载。
3. 此时如果$hook为空或不是数组(`即未设置任何hook，或 hook格式有问题`)则直接退出。如果正常则将配置文件中的数组赋值给`$hooks`属性同时`$enabled`属性置为true表示钩子可用。
---

#### call_hook() ####
```text
public function call_hook($which = '')
{
    if ( ! $this->enabled OR ! isset($this->hooks[$which]))
    {
        return FALSE;
    }
    if (is_array($this->hooks[$which]) && ! isset($this->hooks[$which]['function']))
    {
        foreach ($this->hooks[$which] as $val)
        {
            $this->_run_hook($val);
        }
    }
    else
    {
        $this->_run_hook($this->hooks[$which]);
    }
    return TRUE;
}
```
该方法是[CodeIgniter.php](https://pureven.cc/2019/12/19/codeigniter-codeigniter/)文件中直接调用的接口，功能是判断钩子是否启用，以及被调用的钩子是否被定义，最后调用`_run_hook()`内部方法执行。功能实现:
- 如果钩子未启用或被调用的钩子不存在则直接返回。
- 判断钩子的定义类型分别来执行`_run_hook()`，这里如果钩子数组是一个关联数组存在function键名则执行根据其值执行`_run_hook()`，如果是多次调用同一个挂钩点或者匿名函数进行调用的则直接执行`_run_hook()`。

这里钩子的定义类型有三种：
1. 钩子数组是一个关联数组，数组的键名可以为`class`、`function`、`filename`、`filepath`、`params`。下面是官网例子:
```text
$hook['pre_controller'] = array(
    'class'    => 'MyClass',
    'function' => 'Myfunction',
    'filename' => 'Myclass.php',
    'filepath' => 'hooks',
    'params'   => array('beer', 'wine', 'snacks')
);
```
2. 钩子数组用二维数组来实现多次调用同一个挂钩点，多个脚本执行顺序为定义数组的顺序，如:
```text
$hook['pre_controller'][] = array(
    'class'    => 'MyClass',
    'function' => 'MyMethod',
    'filename' => 'Myclass.php',
    'filepath' => 'hooks',
    'params'   => array('beer', 'wine', 'snacks')
);
$hook['pre_controller'][] = array(
    'class'    => 'MyOtherClass',
    'function' => 'MyOtherMethod',
    'filename' => 'Myotherclass.php',
    'filepath' => 'hooks',
    'params'   => array('red', 'yellow', 'blue')
);
```
3. 闭包(匿名)函数作为钩子，如在系统执行早期`使用钩子自动将环境变量.evn加载到getenv()、$_ENV和$_SERVER中`。
````text
$hook['pre_system'][] = function() {
    $dotenv = new Dotenv\Dotenv(FCPATH);
    $dotenv->load();
};
````

---

#### _run_hook() ####
```text
protected function _run_hook($data)
{
    if (is_callable($data))
    {
        is_array($data)
            ? $data[0]->{$data[1]}()
            : $data();
        return TRUE;
    }
    elseif ( ! is_array($data))
    {
        return FALSE;
    }
    if ($this->_in_progress === TRUE)
    {
        return;
    }
    if ( ! isset($data['filepath'], $data['filename']))
    {
        return FALSE;
    }
    $filepath = APPPATH.$data['filepath'].'/'.$data['filename'];
    if ( ! file_exists($filepath))
    {
        return FALSE;
    }
    $class		= empty($data['class']) ? FALSE : $data['class'];
    $function	= empty($data['function']) ? FALSE : $data['function'];
    $params		= isset($data['params']) ? $data['params'] : '';
    if (empty($function))
    {
        return FALSE;
    }
    $this->_in_progress = TRUE;
    if ($class !== FALSE)
    {
        // The object is stored?
        if (isset($this->_objects[$class]))
        {
            if (method_exists($this->_objects[$class], $function))
            {
                $this->_objects[$class]->$function($params);
            }
            else
            {
                return $this->_in_progress = FALSE;
            }
        }
        else
        {
            class_exists($class, FALSE) OR require_once($filepath);
            if ( ! class_exists($class, FALSE) OR ! method_exists($class, $function))
            {
                return $this->_in_progress = FALSE;
            }
            $this->_objects[$class] = new $class();
            $this->_objects[$class]->$function($params);
        }
    }
    else
    {
        function_exists($function) OR require_once($filepath);
        if ( ! function_exists($function))
        {
            return $this->_in_progress = FALSE;
        }
        $function($params);
    }
    $this->_in_progress = FALSE;
    return TRUE;
}
```
该方法是钩子的实际执行者，功能实现:
1. 判断参数如果是个闭包(匿名)函数则直接执行并返回，否则判断参数如果不为数组则直接返回。
2. 通过`_in_progress`判断如果正在执行中则返回，防止死循环。
3. 如果不是匿名函数，则需要根据`filepath`和`filename`来确定文件是否存在，因此这两个参数不存在或文件不存在直接返回。
4. 根据参数确定`class`、`function`、`params`，如果`function`不存在则直接返回。
5. 设置`_in_progress`为true，即表示当前钩子正在执行中。
6. 如果`$class`存在则加载相关类文件，`_objects`属性赋值该类的实例并调用相关方法(`function`)；不存在`$class`则直接执行函数`function`。
7. 执行完成后，设置`_in_progress`为false。

---

#### 参考链接 ####

[CI框架源码解析五之钩子类文件Hooks.php](https://blog.csdn.net/Zhihua_W/article/details/52850773)
