---
title: CodeIgniter路由类文件Router.php
date: 2020-01-20 14:42:28
tags:
- Php
- Codeigniter
categories:
- Web工作笔记
---

#### 引言 ####

[上文](https://pureven.cc/2020/01/14/codeigniter-uri/)对URI类进行了原码分析，URI类实现了将URL分段保存到`segments`数组中。下面对Router类代码进行剖析来看看CodeIgniter是如何利用`segments`将URI映射到对应控制器、方法的。
<!--more-->

---

#### 路由配置文件routes.php ####

从[官网](https://codeigniter.org.cn/user_guide/general/routing.html)可知URI路由的特性有:
1. 自定义路由，即在routes.php文件中使用通配符和正则表达式进行设置，如:
```text
$route['product/(:num)'] = 'catalog/product_lookup_by_id/$1';
$route['login/(.+)'] = 'auth/login/$1';
```

2. 使用回调函数来处理逆向引用，如:
```text
$route['products/([a-zA-Z]+)/edit/(\d+)'] = function ($product_type, $id)
{
    return 'catalog/product_edit/' . strtolower($product_type) . '/' . $id;
};
```
3. 在路由中使用 HTTP 动词。
```text
$route['products/(:num)']['DELETE'] = 'product/delete/$1';
```
4. 定义默认路由。
```text
$route['default_controller'] = 'welcome';
```
通过Router类可以实现对这些路由定义方式的解析。

---

#### 成员变量 ####
```text
public $config;
public $routes =	array();
public $class =		'';
public $method =	'index';
public $directory;
public $default_controller;
public $translate_uri_dashes = FALSE;
public $enable_query_strings = FALSE;
```
$config表示加载的配置类对象。
$routes表示配置的路由数组。
$class表示请求的控制器类。
$method表示请求的方法。
$directory表示`index.php`中设置的子目录。
$default_controller表示默认控制器类。
$translate_uri_dashes为true则表示将连字符`-`转换为下划线`_`。也是通过路由配置文件进行设置。
$enable_query_strings表示是否支持字符串查询。
---

#### 构造函数 ####
```text
public function __construct($routing = NULL)
{
    $this->config =& load_class('Config', 'core');
    $this->uri =& load_class('URI', 'core');
    $this->enable_query_strings = ( ! is_cli() && $this->config->item('enable_query_strings') === TRUE);
    is_array($routing) && isset($routing['directory']) && $this->set_directory($routing['directory']);
    $this->_set_routing();
    if (is_array($routing))
    {
        empty($routing['controller']) OR $this->set_class($routing['controller']);
        empty($routing['function'])   OR $this->set_method($routing['function']);
    }
    log_message('info', 'Router Class Initialized');
}
```
该方法是Router类功能实现的统一入口，完成该类初始化。功能实现：
1. 加载Config、URI类，获取查询字符串开关。
2. 如果存在`$routing['directory']`则使用该值设置子目录。<font color="#891717">该值在index.php文件中定义，包括directory、controller、method优先级高于uri中的directory、controller、method。</font>
3. 调用`_set_routing`方法完成路由配置读取及解析。

---

#### _set_routing() ####
```text
protected function _set_routing()
{
    if (file_exists(APPPATH.'config/routes.php'))
    {
        include(APPPATH.'config/routes.php');
    }
    if (file_exists(APPPATH.'config/'.ENVIRONMENT.'/routes.php'))
    {
        include(APPPATH.'config/'.ENVIRONMENT.'/routes.php');
    }
    if (isset($route) && is_array($route))
    {
        isset($route['default_controller']) && $this->default_controller = $route['default_controller'];
        isset($route['translate_uri_dashes']) && $this->translate_uri_dashes = $route['translate_uri_dashes'];
        unset($route['default_controller'], $route['translate_uri_dashes']);
        $this->routes = $route;
    }
    if ($this->enable_query_strings)
    {
        if ( ! isset($this->directory))
        {
            $_d = $this->config->item('directory_trigger');
            $_d = isset($_GET[$_d]) ? trim($_GET[$_d], " \t\n\r\0\x0B/") : '';
            if ($_d !== '')
            {
                $this->uri->filter_uri($_d);
                $this->set_directory($_d);
            }
        }
        $_c = trim($this->config->item('controller_trigger'));
        if ( ! empty($_GET[$_c]))
        {
            $this->uri->filter_uri($_GET[$_c]);
            $this->set_class($_GET[$_c]);
            $_f = trim($this->config->item('function_trigger'));
            if ( ! empty($_GET[$_f]))
            {
                $this->uri->filter_uri($_GET[$_f]);
                $this->set_method($_GET[$_f]);
            }
            $this->uri->rsegments = array(
                1 => $this->class,
                2 => $this->method
            );
        }
        else
        {
            $this->_set_default_controller();
        }
        return;
    }
    if ($this->uri->uri_string !== '')
    {
        $this->_parse_routes();
    }
    else
    {
        $this->_set_default_controller();
    }
}
```
该方法的功能是读取路由配置文件，确定uri及调用解析路由`_parse_routes方法。功能实现：
1. 加载路由配置文件，将路由配置数组中的默认控制器和连接线转换下划线开关赋值给该类成员变量后删除。
2. 如果启用查询字符串则依次对路径、控制器、方法进行获取、特殊字符过滤并赋值给改类成员变量。<font color="#891717">这里路径设置的前提是没有在index.php文件中设置，否则会被覆盖。</font>
3. 如果uri字符串不为空则进行路由解析，否则调用设置默认控制器方法。

---

#### _set_request() ####
```text
protected function _set_request($segments = array())
{
    $segments = $this->_validate_request($segments);
    if (empty($segments))
    {
        $this->_set_default_controller();
        return;
    }
    if ($this->translate_uri_dashes === TRUE)
    {
        $segments[0] = str_replace('-', '_', $segments[0]);
        if (isset($segments[1]))
        {
            $segments[1] = str_replace('-', '_', $segments[1]);
        }
    }
    $this->set_class($segments[0]);
    if (isset($segments[1]))
    {
        $this->set_method($segments[1]);
    }
    else
    {
        $segments[1] = 'index';
    }
    array_unshift($segments, NULL);
    unset($segments[0]);
    $this->uri->rsegments = $segments;
}
```
该方法的参数由`_parse_routes`传入，是经过处理后的包含请求控制器及请求方法的数组，该方法的作用是验证请求路由并确定`rsegments`。功能实现:
1. 调用`_validate_request`方法将控制器连字符`-`转为下划线`_`，并附加子目录。
2. 如果参数为空则设置默认路由。
3. 将情况控制器和方法中存在的连字符`-`转为下划线`_`。
4. 设置控制器，如果存在请求方法则设置方法，不存在则默认`index`。
5. `array_unshift($segments,NULL)`和`unset($segments[0])`的作用是保证$segments数组有用下标是从1开始。
6. 最后将处理后的`$segments`赋值给`URI`类的`rsegments`成员变量。

---

#### _set_default_controller() ####
```text
protected function _set_default_controller()
{
    if (empty($this->default_controller))
    {
        show_error('Unable to determine what should be displayed. A default route has not been specified in the routing file.');
    }
    if (sscanf($this->default_controller, '%[^/]/%s', $class, $method) !== 2)
    {
        $method = 'index';
    }
    if ( ! file_exists(APPPATH.'controllers/'.$this->directory.ucfirst($class).'.php'))
    {
        return;
    }
    $this->set_class($class);
    $this->set_method($method);
    $this->uri->rsegments = array(
        1 => $class,
        2 => $method
    );
    log_message('debug', 'No URI present. Default controller set.');
}
```
该方法用于设置默认控制器，以下几种情况下调用：
1. URI开启了查询字符串功能但是没有指定控制器。
2. 没有指定uri或uri段为空。
功能实现：
1. 如果发现默认控制器为空则直接报错退出，因为调用此方法就说明请求的uri为空或不存在必须走默认控制器给出响应。
2. 如果没有指定默认方法则统一为`index`。
3. 如果指定了默认控制器但是控制器类文件不存在则直接返回。
4. 调用成员方法设置**类**、**方法**并赋值`rsegments`。

---

#### _validate_request() ####
```text
protected function _validate_request($segments)
{
    $c = count($segments);
    $directory_override = isset($this->directory);
    while ($c-- > 0)
    {
        $test = $this->directory
            .ucfirst($this->translate_uri_dashes === TRUE ? str_replace('-', '_', $segments[0]) : $segments[0]);
        if ( ! file_exists(APPPATH.'controllers/'.$test.'.php')
            && $directory_override === FALSE
            && is_dir(APPPATH.'controllers/'.$this->directory.$segments[0])
        )
        {
            $this->set_directory(array_shift($segments), TRUE);
            continue;
        }
        return $segments;
    }
    return $segments;
}
```
该方法用于验证`$segments`段，功能实现:
1. 获取`segments`段的个数，如果index.php文件中设置了`$routing['directory']`则使用该值作为子目录。
2. 如果`translate_uri_dashes`值为true则将控制器类的连字符`-`转换为下划线`_`。
3. 如果直接在controllers这个目录下找到与第一段相应的控制器名，那就说明找到了控制器，确定路由，返回。
4. 如果第一段是目录，则设置子目录，CI是允许控制器放在自定义的目录下的。
---

#### _parse_routes() ####
```text
protected function _parse_routes()
{
    $uri = implode('/', $this->uri->segments);
    $http_verb = isset($_SERVER['REQUEST_METHOD']) ? strtolower($_SERVER['REQUEST_METHOD']) : 'cli';
    foreach ($this->routes as $key => $val)
    {
        if (is_array($val))
        {
            $val = array_change_key_case($val, CASE_LOWER);
            if (isset($val[$http_verb]))
            {
                $val = $val[$http_verb];
            }
            else
            {
                continue;
            }
        }
        $key = str_replace(array(':any', ':num'), array('[^/]+', '[0-9]+'), $key);
        if (preg_match('#^'.$key.'$#', $uri, $matches))
        {
            if ( ! is_string($val) && is_callable($val))
            {
                array_shift($matches);
                $val = call_user_func_array($val, $matches);
            }
            elseif (strpos($val, '$') !== FALSE && strpos($key, '(') !== FALSE)
            {
                $val = preg_replace('#^'.$key.'$#', $val, $uri);
            }
            $this->_set_request(explode('/', $val));
            return;
        }
    }
    $this->_set_request(array_values($this->uri->segments));
}
```
该方法用于解析路由，功能实现：
1. 获取uri，即`implode('/', $this->uri->segments)`。
2. 获取请求动词，即`$_SERVER['REQUEST_METHOD']`，为空表示通过cli方式请求的。
3. 解析$routes数组，如果请求uri对应的是个数组，使用[array_change_key_case](https://www.php.net/manual/zh/function.array-change-key-case.php)将key转为小写然后匹配请求动词。
4. 将通配符转为正则表达式，也就是说`路由数组中的通配符最终也是通过正则表达式的形式类解析路由的`。
5. 匹配uri，如果$val是回调函数则直接调用(`这里解释了路由可以是回调函数`)；如果是key中有通配符则进行正则匹配(例如`$route['api/v1/(:any)/(:num)/(:any)']="api_v1/$1/$3/$2"`)。
6. 设置路由，通过`_set_request`方法和`$val`设置`rsegments`;若没有匹配到则直接解析`uri->segments`来设置`rsegments`。

---

#### set_class() ####
```text
public function set_class($class)
{
    $this->class = str_replace(array('/', '.'), '', $class);
}
```
该方法用于设置请求控制器类。

---

#### fetch_class() ####
```text
public function fetch_class()
{
    return $this->class;
}
```
该方法用于获取请求控制器类。

---

#### set_method() ####
```text
public function set_method($method)
{
    $this->method = $method;
}
```
该方法用于设置请求方法。

---

#### fetch_method() ####
```text
public function fetch_method()
{
    return $this->method;
}
```
该方法用于获取请求的方法。

---

#### set_directory() ####
```text
public function set_directory($dir, $append = FALSE)
{
    if ($append !== TRUE OR empty($this->directory))
    {
        $this->directory = str_replace('.', '', trim($dir, '/')).'/';
    }
    else
    {
        $this->directory .= str_replace('.', '', trim($dir, '/')).'/';
    }
}
```
该方法用于设置子目录。如果`directory`为空或`$append`为false，则直接赋值给`directory`；否则附加到`directory`后面。


---

#### fetch_directory() ####
```text
public function fetch_directory()
{
    return $this->directory;
}
```
该方法用于获取子目录。

---

#### 参考链接 ####
[CI框架源码解析九之路由类文件Router.php](https://blog.csdn.net/Zhihua_W/article/details/52918664)

