---
title: CodeIgniter之Loader类原码学习笔记
date: 2019-12-09 21:00:44
tags:
- PHP
- Codeigniter
categories:
- 开发者手册
---

#### 引言 ####

2017年5月17日是一个特殊的日子，在这一天我第一次提交代码。这个时期的编码使用的是原生php，每个功能文件开头都需要`require(dirname(__FILE__) . '/../config.php');`，`config.php`的作用主要有: `内存上限`、`设置cookie为httponly`、`参数安全过滤及拦截`、`数据库相关设置`、`语言文件加载`等等。基本每个文件开头都是先进行require/require_once/include/include_once等操作。2019年3月首次接触公司重构的业务代码，使用的是CodeIniger + Vue前后端分离架构设计，我负责部分后端API的开发及维护工作。下面是在工作中对CodeIgniter框架中Loader类的原码学习笔记。

---

<marquee direction="left"><font color="#891717" face="隶书" size="+5" behavior="alternate" scrollamount="10" scrolldelay="100">CodeIgniter Loader</font></marquee>

---

#### 流程控制中加载文件的语句 ####

工作中常用到加载文件相关的`语句`有: `include`、`require`、`include_once`、`require_once`等。下面时[官网](https://www.php.net/manual/zh/function.include.php)的相关解释：

**include require 语句包含并运行指定文件**

被包含文件先按参数给出的路径寻找，如果没有给出目录（只有文件名）时则按照 `include_path` 指定的目录寻找。如果在 include_path 下没找到该文件则 include 最后才在调用脚本文件所在的目录和当前工作目录下寻找。如果最后仍未找到文件则 include 结构会发出一条<b><font color="#891717">警告</font></b>。

**如果定义了路径——不管是绝对路径（在 Windows 下以盘符或者 \ 开头，在 Unix/Linux 下以 / 开头）还是当前目录的相对路径（以 . 或者 .. 开头）——include_path 都会被完全忽略。例如一个文件以 ../ 开头，则解析器会在当前目录的父目录下寻找该文件。**

`当一个文件被包含时，其中所包含的代码继承了 include 所在行的变量范围。从该处开始，调用文件在该行处可用的任何变量在被调用的文件中也都可用。不过所有在包含文件中定义的函数和类都具有全局作用域。`

**require** 和 include 几乎完全一样，除了处理失败的方式不同之外。require 在出错时产生 E_COMPILE_ERROR 级别的错误。换句话说`require将导致脚本中止` **而** `include 只产生警告（E_WARNING），脚本会继续运行。`

**include_once require_once**

include_once/require_once语句在脚本执行期间包含并运行指定文件。此行为和 include/require 语句唯一区别是如果该文件中已经被包含过，则不会再次包含。如同此语句名字暗示的那样，只会包含一次。

include_once/require_once可以用于在脚本执行期间同一个文件有可能被包含超过一次的情况下，想确保它只被包含一次以避免函数重定义，变量重新赋值等问题。

**include_path**

指定目录列表，其中 `require`，`include`， `fopen（）`，`file（）`， `readfile（）`和`file_get_contents（）` 函数在其中查找文件。格式类似于系统的 PATH环境变量：在Unix中用`冒号`或在Windows中用`分号`分隔的目录列表。

当寻找要包含的文件时，PHP会分别考虑包含路径中的每个条目。它将检查第一个路径，如果找不到，请检查下一个路径，直到找到包含的文件或返回警告 或错误为止 。您可以在运行时使用[set_include_path（）](https://www.php.net/manual/zh/function.set-include-path.php)修改或设置包含路径。

---

#### CodeIgniter框架中的加载类 ####

CodeIgniter框架有专门的Loader类专门用于文件加载， 让我们在编程过程中更专注与业务逻辑，从而提高效率。下面是Loader类的学习笔记。

##### __construct() #####

从构造方法开始，下面是构造方法的定义：
```gherkin
public function __construct()
{
    $this->_ci_ob_level = ob_get_level();
    $this->_ci_classes =& is_loaded();
    log_message('info', 'Loader Class Initialized');
}
```
这里主要干了两件事：

- 获取输出缓冲机制的嵌套级别并赋值给`_ci_ob_level`属性。关于`ob系列函数`有一篇文章可以细细品味[《结合php ob函数理解缓冲机制》](https://www.cnblogs.com/deanchopper/p/4688667.html);
- `_ci_classes`引用Common函数`is_loaded()`表示`_ci_classes`存放已加载的类。

###### Common中的is_loaded()函数 ######

下面来看`is_loaded()`函数的定义：
```gherkin
function &is_loaded($class = '')
{
    static $_is_loaded = array();

    if ($class !== '')
    {
        $_is_loaded[strtolower($class)] = $class;
    }

    return $_is_loaded;
}
```

第一次调用该函数时会初始化一个静态数组`$_is_loaded`，若指定了参数$class然后则将参数中给的类名$class**小写**形式作为`key`、$class作为`value`保存到数组中，最后返回静态数组$_is_loaded。比如传入一个参数'Test'，则静态数组中会产生一个关于Test类的映射`$_is_loaded['test'] = 'Test';`，is_loaded()<b><font color="#891717">函数负责记录哪些类被加载过，返回的是已加载类的集合</font></b>。<b>此处构造函数中并没有指定类名，因此只是获取已加载类的集合。</b>

由此可以判断Loader类构造方法的作用是：

- 属性`_ci_ob_level`表示输出缓冲机制的嵌套级别。
- 属性`_ci_classes`表示已加载类的映射集合。

---

##### initialize() #####

initialize()方法在`CI_Controller类`中调用，负责将**autoload.php**文件中指定的默认加载项进行加载。其定义为：
```gherkin
public function initialize()
{
    $this->_ci_autoloader();
}
```

接着看下_ci_autoloader()的实现，看看_ci_autoloader()是如何将autoload.php文件中指定的默认加载项进行加载的。

###### _ci_autoloader() ######

1. 引入autoload.php文件
```gherkin
if (file_exists(APPPATH.'config/autoload.php'))
{
    include(APPPATH.'config/autoload.php');
}		
if (file_exists(APPPATH.'config/'.ENVIRONMENT.'/autoload.php'))
{
    include(APPPATH.'config/'.ENVIRONMENT.'/autoload.php');
}
```
autoload.php文件结构为：
>$autoload = [
    'packages' => [APPPATH . 'third_party/MX'],
    'libraries' => ['my_class', 'database'],
    'drivers' => [],
    'helper' => ['array', 'language'],
    'config' => ['codeigniter'],
    'language' => [],
    'model' => [],
 ]
 
2. 判断是否存在$autoload，也就是如果不存在autoload.php文件，直接return
```gherkin
if ( ! isset($autoload))
{
    return;
}
```

---

3. 根据$autoload的分类即keys分别进行加载，首先加载**packages**，代码如下：
```gherkin
if (isset($autoload['packages']))
{
    foreach ($autoload['packages'] as $package_path)
    {
        $this->add_package_path($package_path);
    }
}
```
`add_package_path()`方法代码如下：
```gherkin
public function add_package_path($path, $view_cascade = TRUE)
{
    $path = rtrim($path, '/').'/';
    array_unshift($this->_ci_library_paths, $path);
    array_unshift($this->_ci_model_paths, $path);
    array_unshift($this->_ci_helper_paths, $path);
    $this->_ci_view_paths = array($path.'views/' => $view_cascade) + $this->_ci_view_paths;
    $config =& $this->_ci_get_component('config');
    $config->_config_paths[] = $path;
    return $this;
}
```
其中_ci_get_component()方法的作用是获取CI实例，CodeIgniter在CI_Controller类中通过`self::$instance`实现`单例化`，在第一次实例时，通过静态变量$instance引用了这个实例。 以后都可以通过&get_instance();来获得这个单一实例。构成这样的单例模式的好处就是单例类不会重复占用内存和系统资源而是让应用程序的其他部分更好的使用这些资源。此处通过全局函数get_instance()拿到CI实例。
其代码如下：
```gherkin
protected function &_ci_get_component($component)
{
    $CI =& get_instance();
    return $CI->$component;
}
```

总结add_package_path()的作用如下：
- 将$package_path分别加入`_ci_library_paths`、`_ci_model_paths`、`_ci_helper_paths`这几个属性中，`array_unshift()`的作用是在数组的开头加入新元素。
- 使用数组相加的方式将最先出现的值作为结果将$package_path . 'views/'加入到`_ci_view_paths`中。
- 获取CI实例，通过CI实例将$package_path加入到`$CI->config->_config_paths`数组中。

---

4. 加载autoload.php中配置的config文件，即$autoload['config']中的内容：
```gherkin
if (count($autoload['config']) > 0)
{
    foreach ($autoload['config'] as $val)
    {
        $this->config($val);
    }
}
```
config()方法：
```gherkin
public function config($file, $use_sections = FALSE, $fail_gracefully = FALSE)
{
    return get_instance()->config->load($file, $use_sections, $fail_gracefully);
}
```
这里`get_instance()->config`即`CI_Config`，在`CI_Controller`类中已执行过`$this->config = new CI_Config();`。 此处$autoload['config'] = ['codeigniter']，因此此处执行的是CI_Config->load('codeigniter')进行加载codeigniter.php文件，即`include('codeigniter.php')`。然后将文件名记入CI_Config->is_loaded数组，方便检查文件是否已加载。

---

5. 加载helper、language文件
```gherkin
foreach (array('helper', 'language') as $type)
{
    if (isset($autoload[$type]) && count($autoload[$type]) > 0)
    {
        $this->$type($autoload[$type]);
    }
}
```
这里以变量函数的形式调用了helper()和language()方法：
```gherkin
public function language($files, $lang = '')
{
    get_instance()->lang->load($files, $lang);
    return $this;
}
```
这里执行的时CI_Lang->load()加载指定的语言包。本例通过helpers()加载['array', 'language']
```gherkin
public function helpers($helpers = array())
{
    return $this->helper($helpers);
}
```
helper()的执行流程：
①构造helper文件名：
```gherkin
$filename = basename($helper);
$filepath = ($filename === $helper) ? '' : substr($helper, 0, strlen($helper) - strlen($filename));
$filename = strtolower(preg_replace('#(_helper)?(\.php)?$#i', '', $filename)).'_helper';// 加后缀 _helper,比如 array_helper
$helper   = $filepath.$filename;
```
②若已包含则继续下一个
```gherkin
if (isset($this->_ci_helpers[$helper]))
{
    continue;
}
```
③检查是否有前缀，比如`MY_array_helper`，前面`add_package_path()`方法将依赖包依次赋值给$this->**_ci_helper_paths**属性，此处用到了！
```gherkin
$ext_helper = config_item('subclass_prefix').$filename;
$ext_loaded = FALSE;
foreach ($this->_ci_helper_paths as $path)
{
    if (file_exists($path.'helpers/'.$ext_helper.'.php'))
    {
        include_once($path.'helpers/'.$ext_helper.'.php');
        $ext_loaded = TRUE;
    }
}
```
④如果MY_array_helper.php存在，但是array_helper.php不存在则报错，这里可理解为扩展类存在，基类不存在报错。
```gherkin
if ($ext_loaded === TRUE)
{
    $base_helper = BASEPATH.'helpers/'.$helper.'.php';
    if ( ! file_exists($base_helper))
    {
        show_error('Unable to load the requested file: helpers/'.$helper.'.php');
    }
    include_once($base_helper);
    $this->_ci_helpers[$helper] = TRUE;
    log_message('info', 'Helper loaded: '.$helper);
    continue;
}
```
⑤如果前缀文件不存在则加载默认目录下的helper文件，不存在则不成功则报错。如果存在则通过`include_once`进行加载，然后将helper文件名放入`$this->_ci_helper`数组里方便后面加载前判断是否存在。
```gherkin
foreach ($this->_ci_helper_paths as $path)
{
    if (file_exists($path.'helpers/'.$helper.'.php'))
    {
        include_once($path.'helpers/'.$helper.'.php');
        $this->_ci_helpers[$helper] = TRUE;
        log_message('info', 'Helper loaded: '.$helper);
        break;
    }
}
// unable to load the helper
if ( ! isset($this->_ci_helpers[$helper]))
{
    show_error('Unable to load the requested file: helpers/'.$helper.'.php');
}
```

6. 加载drivers 数据库驱动器
```gherkin
if (isset($autoload['drivers']))
{
    $this->driver($autoload['drivers']);
}
```
`driver()`方法有三个参数`$library` `$params` `$object_name`， 具体加载流程如下：
① $library如果为数组则走递归，为空则直接return false。默认$autoload并没有指定drivers，因此到这就返回了。
② $library不为数组也不为空则判断是否存在`CI_Driver_Library`类，不存在则`require BASEPATH . 'libraries/Driver.php';`。这里不是实例化对象，只是使基类可用。
③执行`$library = ucfirst($library) . '/' . $library;`，原因是`驱动器位于 system/libraries/ 目录，每个驱动器都有一个独立的目录，目录名和 驱动器父类的类名一致，在该目录下还有一个子目录，命名为 drivers，用于存放所有子类的文件。`。
④执行`return $this->library($library, $params, $object_name);`。library()方法执行的是`_ci_load_library()`方法进行加载。下面来看_ci_load_library()：

--- 

**_ci_load_library($class, $params = NULL, $object_name = NULL)**

- 若$class字符串中存在.php，将其去掉。
```gherkin
$class = str_replace('.php', '', trim($class, '/'));
```
- $class去掉末尾/后发现还有/就说明在子目录下了，这时要获取子目录
```gherkin
if (($last_slash = strrpos($class, '/')) !== FALSE)
{
    // Extract the path
    $subdir = substr($class, 0, ++$last_slash);
    // Get the filename from the path
    $class = substr($class, $last_slash);
}
else
{
    $subdir = '';
}
```
- 确保类名首字母大写
```gherkin
$class = ucfirst($class);
```
- 

---

#### 挑战：不要使用include_once ####

读过[laruence](https://baike.baidu.com/item/%E6%83%A0%E6%96%B0%E5%AE%B8)前辈的一篇博文[《再一次, 不要使用(include/require)_once》](http://www.laruence.com/2012/09/12/2765.html)。其中指出了不要使用include_once的原因并讲解了include_once对文件加载流程：

1. 尝试解析文件的绝对路径, 如果能解析成功, 则检查EG(included_files), 存在则返回,不存在继续。
2. 打开文件, 得到文件的打开路径(opened path)。
3. 拿opened path去EG(included_files)查找, 是否存在, 如果存在则返回, 不存在继续。
4. 编译文件(compile_file)。

也就是说include_once需要查询一遍已加载的文件列表, 确认是否存在, 然后再加载。文章最后说`你使用include_once, 只能证明, 你对自己的代码没信心.`，确实很激励人的！继续加油啦！！
