---
title: CodeIgniter实现HMVC模块扩展
date: 2020-03-28 13:48:07
tags:
- PHP
- Codeigniter
categories:
- 开发者手册
---

#### 引言 ####
模块扩展让CodeIgniter框架模块化。模块是一组独立的组件（通常有模型、控制器和视图），它们被分类在应用模块的子文件夹中，并且能够直接拖到其他的CodeIgniter应用中。

HMVC的意思是分层模型视图控制器。

模块控制器能够作为普通的控制器或者HMVC控制器使用，它们也能够被当做小部件帮助你开发一部分视图。
<!-- more -->
---

#### 模块扩展安装 ####

1. 安装CI框架，下载地址:[CodeIgniter-3.1.11](https://github.com/bcit-ci/CodeIgniter/archive/3.1.11.tar.gz)。
2. 配置好CI环境，访问URL `/index.php/welcome`可以看到欢迎界面说明正常。
3. 下载[模块扩展源码](https://bitbucket.org/wiredesignz/codeigniter-modular-extensions-hmvc/get/f77a3fc9a6fd.zip)并将模块扩展的third_party文件拖入application/third_party目录。
4. 修改`third_party/MX/Loader.php`文件，有个bug需要处理下，要不然会报错，[参考连接](https://github.com/pureven/CodeIgniter-HMVC/commit/ce4f66e228e617885bf17358045d6c3eaba20690)。 
5. 再次访问URL `/index.php/welcome`看到欢迎界面。
6. 创造模块目录结构`application/modules/welcome/controllers`。
7. 将控制器文件**application/controllers/welcome.php**移动至**application/modules/welcome/controllers/welcome.php**。
8. 访问URL `/index.php/welcome`看到欢迎界面。
9. 创建目录`application/modules/welcome/views`。
10. 将视图文件<font color="#891717">pplication/views/welcome_message.php</font>移动至<font color="#891717">application/modules/welcome/views/welcome_message.php</font>。
11. 访问URL `/index.php/welcome`看到欢迎界面

配置完毕。

---

#### FAQ ####

Q: 什么是模块？我为什么要使用他们？

A: 参见维基百科：
- [http://en.wikipedia.org/wiki/Module)](http://en.wikipedia.org/wiki/Module))
- [http://en.wikipedia.org/wiki/Modular_programming)](http://en.wikipedia.org/wiki/Modular_programming))
- [http://blog.fedecarg.com/2008/06/28/a-modular-approach-to-web-development)](http://blog.fedecarg.com/2008/06/28/a-modular-approach-to-web-development))

Q: 什么是模块化HMVC，为什么我应该使用它？

A: 模块化 HMVC = `Multiple MVC triads`

当你需要载入视图和视图中的数据的时候，这将是非常有用的。考虑添加一个购物车到一个页面中，这个购物车需要它自己的控制器，这个控制器要调用一个模型来获取购物车数据。然后控制器需要将数据载入到视图中。因此，和在主控制器处理这个页面和购物车不同，购物车MVC能够直接在页面中加载。这个主控制器不需要知道购物车MVC，并且和购物车MVC是完全隔离的。

在CI框架中，我们不能够在一次请求中调用多个控制器。因此，为了实现HMVC，我们不得不模拟控制器的行为。这用类库可以做到或者使用这个“模块扩展HMVC”。

使用一个类库和一个“模块扩展HMVC”类不同之处在于：
1. 不需要在HMVC中获取和使用CI实例
2. HMVC类存储在modules目录中而不是类库目录中

Q: 模块扩展HMVC和模块分离是一样的么？

A: 是，也可以说不是。和模块分离类似，模块扩展使得模块变得“可便携的”。例如，如果你有一个漂亮的自包含MVC文件集，你能够将你的MVC文件加入到另一个项目中，仅仅通过复制一个目录就行了。所有文件都在同一个地方而不是散布在model、view 和controller文件夹。

模块化HMVC意味着模块化MVC triads。 模块分离和模块扩展让相关的控制器、模型、类库、视图等等文件能够被打包在模块子目录中，并且能够像一个小型应用那样使用。但是，模块扩展更进一步，它允许这些模块互相通信。你能够不用通过与http交互得到控制器的输出内容。

---
#### 特点 ####

所有的控制器都包含一个`$autoload`类变量，这个类变量拥有一个运行时优先载入的条目（item）数组。这个功能能够和 `module/config/autoload.php`一起使用，然而，使用`$autoload`变量仅仅在对应的控制器中起作用。
```php
class Xyz extends MX_Controller 
{
    $autoload = array(
        'helper'    => array('url', 'form'),
        'libraries' => array('email'),
    );
}
```

`Modules::$locations`可以在`application/config.php`文件中设置，例如：
```php
$config['modules_locations'] = array(
    APPPATH.'modules/' => '../modules/',
);
```

`Modules::run()`输出将会被缓存，因此从任何从控制器返回或者输出的数据将会被捕获并且返回到调用者。特别的，`$this->load->view()`能够在一个普通的控制器中按照你所想的那样使用，而不用返回任何值。

控制器能够作为别的控制器的类变量载入，使用语句`$this->load->module('module/controller');`或者在控制器的名称和模块的名称一致的时候，使用`$this->load->module('module');`

任何加载的模块都可以当做一个类库使用，例如`$this->controller->method()`，但是加载的模块拥有自己独立与调用它的类的模块和类库。

所有模块控制器都能够通过URL（ `module/controller/method`或者模块名和控制器名称一致的时候使用`module/method`）访问到。如果你添加了`_remap()`方法到你的控制器中，你能够阻止不需要的访问然后重定向或者发送一个错误，这些随你。

---

#### 注意 ####

要使用HMVC功能，例如`Modules::run()`，控制器必须继承`MX_Controller`类。

仅仅使用分开的模块而不是HMVC功能，控制器可以继承CodeIgniter类。

你必须在控制器中使用PHP5样式的构造函数，例如：
```php
class Xyz extends MX_Controller 
{
    function __construct()
    {
        parent::__construct();
    }
}
```

构造函数并不是必须的，除非你想在控制器创建的时候载入或者处理什么东西。

所有的`MY_extension`类库应该包含（需要）他们同等的MX类库文件，并且继承它们同等的`MX_class`。

每一个模块可以包含一个`config/routes.php`文件，在文件中定义该模块的路由和默认控制器：
```php
$route['module_name'] = 'controller_name';
```

控制器可以从`application/controllers`子目录中载入。

控制器也可以从`module/controllers`子目录中载入。

资源能够能够跨控制器载入，例如： `$this->load->model('module/model');`

`Modules::run()`被设计成返回部分视图，并且它将会从控制器返回缓存输出（一个视图）。使用`modules::run`语法是一个URI类型的片段字符串和无限的变量。
```php
/** module and controller names are different, you must include the method name also, including 'index' **/
modules::run('module/controller/method', $params, $...);

/** module and controller names are the same but the method is not 'index' **/
modules::run('module/method', $params, $...);

/** module and controller names are the same and the method is 'index' **/
modules::run('module', $params, $...);

/** Parameters are optional, You may pass any number of parameters. **/
```

在控制器里边调用一个模块控制器，你可以使用`$this->load->module()`或者`Modules::load()`，PHP5的方法链也可以用在任何被MX加载的对象中，例如： `$this->load->library(‘validation’)->run()`。

载入模块的语言文件推荐使用载入方法，该方法将会传递一个激活的模块名称到一个语言实例，例如：`$this->load->language('language_file');`

PHP5的spl_autoload特性允许你自由地扩展你的控制器、模块和来自`application/core`或者`application/libraries`基本类的的类库，不需要考虑显式包含他们。

类库加载器也被更新从而适应一些CI的特性，例如：类库别名能够和模块别名一样的方式接受，并且从模块配置目录中载入配置文件作为类库的参数（例如：`form_validation.php`），这项特性也被加了进来。

`$config = $this->load->config(‘config_file’)`，返回已加载的数组到变量中。

模块和类库也能够从他们各自的应用目录的子目录中加载。

在用MX使用表单验证时，你将需要继承`CI_Form_validation`类，如下所示：
```php
/** application/libraries/MY_Form_validation **/ 
class MY_Form_validation extends CI_Form_validation 
{
    public $CI;
}
```

在将目前的控制器作为$CI变量赋值给表单验证类库之前。这将让你的回调函数正常工作。
```php
class Xyz extends MX_Controller 
{
    function __construct()
    {
        parent::__construct();

        $this->load->library('form_validation');
        $this->form_validation->CI =& $this;
    }
}
```

---

#### 参考链接 ####

[【译】CodeIgniter HMVC模块扩展使用文档](https://segmentfault.com/a/1190000004105563)
[源码分析](https://github.com/pureven/CodeIgniter-HMVC)
