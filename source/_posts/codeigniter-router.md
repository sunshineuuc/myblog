---
title: CodeIgniter路由类文件Router.php
date: 2020-01-20 14:42:28
tags:
- php
- codeigniter
categories:
- web工作笔记
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
---
$$enable_query_strings表示是否支持字符串查询。

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

---

#### set_class() ####
```text
public function set_class($class)
{
    $this->class = str_replace(array('/', '.'), '', $class);
}
```

---

#### fetch_class() ####
```text
public function fetch_class()
{
    return $this->class;
}
```

---

#### set_method() ####
```text
public function set_method($method)
{
    $this->method = $method;
}
```

---

#### fetch_method() ####
```text
public function fetch_method()
{
    return $this->method;
}
```

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

---

#### fetch_directory() ####
```text
public function fetch_directory()
{
    return $this->directory;
}
```

---

#### 参考链接 ####
[CI框架源码解析九之路由类文件Router.php](https://blog.csdn.net/Zhihua_W/article/details/52918664)

