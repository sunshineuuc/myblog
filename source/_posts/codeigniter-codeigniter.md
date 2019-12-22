---
title: CodeIgniter引导文件codeigniter.php学习笔记
date: 2019-12-19 20:56:41
tags:
- php
- codeigniter
categories:
- web工作笔记
---

#### 引言 ####

codeigniter.php是CI框架的引导(BOOTSTRAP)文件，也就是CI的核心文件。主要完成下面五项工作：

- 加载框架常量、函数库以及框架初始化
- 加载核心类组件
- 路由的设置与判断
- 解析请求的类，并调用请求的方法
- 输出
<!-- more -->

--- 

#### 加载框架常量、函数库以及框架初始化 ####

##### 唯一入口判断 #####
```gherkin
defined('BASEPATH') OR exit('No direct script access allowed');
```
常量`BASEPATH`在`index.php`文件中定义，除index.php外其他所有文件都要执行上面代码进行唯一入口判断，保证单一入口进入程序、防止跨站攻击直接访问文件路径等恶意攻击。

##### 设置版本号 #####
```gherkin
const CI_VERSION = '3.1.10';
```

##### 加载常量文件 #####
```gherkin
if (file_exists(APPPATH.'config/'.ENVIRONMENT.'/constants.php'))
{
    require_once(APPPATH.'config/'.ENVIRONMENT.'/constants.php');
}
if (file_exists(APPPATH.'config/constants.php'))
{
    require_once(APPPATH.'config/constants.php');
}
```
`ENVIRONMENT`为index.php文件中定义的运行环境常量，针对某个环境可以在`APPPATH . config/`下创建对应的目录，然后创建constants.php文件，如`application/config/development/constants.php`，这个文件为当前运行环境下需要的特殊常量。然后加载CI默认的常量文件`APPPATH . config/constants.php`。

##### 加载全局函数库 #####
```gherkin
require_once(BASEPATH.'core/Common.php');
```
这个文件中有很多函数，如<b>get_config()</b>、<b>config_item()</b>这两个方法不是应该由core/Config.php这个组件去做么？那个load_class()不应该由core/Loader.php去做么？把这些函数定义出来貌似感觉架构变得不那么优雅，有点多余。`其实是出于这样一种情况：比如说，如果一切和配置有关的动作都由Config组件来完成，一切加载的动作都由Loader来完成，试想一下，如果我要加载Config组件，那么必须得通过Loader来加载，所以Loader必须比Config要更早实例化，但是如果Loader实例化的时候需要一些和Loader有关的配置信息才能实例化呢？那就必须通过Config来为它取得配置信息。这里就出现了鸡和鸡蛋的问题。`先定义一些公共的函数就很好地解决了这个问题。

##### 对全局变量进行安全处理 #####
```gherkin
if ( ! is_php('5.4'))
{
	ini_set('magic_quotes_runtime', 0);
	if ((bool) ini_get('register_globals'))
	{
		$_protected = array(
			'_SERVER',
			'_GET',
			'_POST',
			'_FILES',
			'_REQUEST',
			'_SESSION',
			'_ENV',
			'_COOKIE',
			'GLOBALS',
			'HTTP_RAW_POST_DATA',
			'system_path',
			'application_folder',
			'view_folder',
			'_protected',
			'_registered'
		);
		$_registered = ini_get('variables_order');
		foreach (array('E' => '_ENV', 'G' => '_GET', 'P' => '_POST', 'C' => '_COOKIE', 'S' => '_SERVER') as $key => $superglobal)
		{
			if (strpos($_registered, $key) === FALSE)
			{
				continue;
			}
			foreach (array_keys($$superglobal) as $var)
			{
				if (isset($GLOBALS[$var]) && ! in_array($var, $_protected, TRUE))
				{
					$GLOBALS[$var] = NULL;
				}
			}
		}
	}
}
```
`is_php()`是common.php文件中定义的全局函数，用于判断当前判断是否大于等于指定版本，此处通过比较来对php小于5.4版本时做兼容处理。干了两件事：①禁用魔术引号；②删除全局变量。
1. 魔术引号
如果`magic_quotes_runtime`设置为TRUE，则读取数据时会自动对引号进行转义。<font color="#891717">由于此功能在PHP 5.3.0中已 弃用，而在PHP 7.0.0中已删除。因此为了向后兼容，如果小于5.4则禁用此功能。</font>更多信息请参考[设置当前 magic_quotes_runtime 配置选项的激活状态](https://doc.bccnsoft.com/docs/php-docs-7.4-cn/function.set-magic-quotes-runtime.html)。

2. 全局变量
如果低于php5.4版本，将进行全局变量安全处理。当开启了register_globals，这就意味着[EGPCS](https://www.php.net/manual/zh/ini.core.php#ini.variables-order)中的变量可以直接用变量名访问，这些全局变量是存储在$GLOBALS数组中的，这是个隐患，虽然5.4及之后消除了，但考虑兼容以前，需要手工清除这些全局变量。那么挑选了最重要的需要特别保护的一些变量名，也就是$_protected数组的值。凡是EGPCS中涉及到变量名称在$_protected数组中的，一律清空。

##### 自定义错误、异常和程序完成的函数 #####
```gherkin
set_error_handler('_error_handler');
set_exception_handler('_exception_handler');
register_shutdown_function('_shutdown_handler');
```
1. 设置错误处理：set_error_handler('_error_handler')。处理函数原型：`function _error_handler($severity, $message, $filepath, $line)`。程序本身原因或手工触发trigger_error("A custom error has been triggered");
2. 设置异常处理：set_exception_handler('_exception_handler')。处理函数原型：`function _exception_handler($exception)`。当用户抛出异常时触发throw new Exception('Exception occurred');
3. 千万不要被shutdown迷惑：register_shutdown_function('_shutdown_handler')可以这样理解调用条件：当页面被用户强制停止时、当程序代码运行超时时、当php代码执行完成时。

##### 检查核心class是否被扩展 #####
```gherkin
if ( ! empty($assign_to_config['subclass_prefix']))
{
    get_config(array('subclass_prefix' => $assign_to_config['subclass_prefix']));
}
```
其中,$assign_to_config是定义在入口文件Index.php中的配置数组. 通常情况下，CI的核心组件的名称均以`CI_`开头，而如果更改了或者扩展CI的核心组件，则应该使用不同的subclass_prefix前缀如`MY_` ,这种情况下，应该通过$assign_to_config['subclass_prefix']指定你的扩展核心的前缀名，便于CI的Loader组件加载该类，或者可能出现找不到文件的错误。另外，subclass_prefix配置项默认是位于APPPATH/Config/config.php配置文件中的，这段代码同样告诉我们，`index.php文件中的subclass_prefix具有更高的优先权`（也就是，如果两处都设置了subclass_prefix,index.php中的配置项会覆盖配置文件Config.php中的配置）。

##### 加载composer ##### 
```gherkin
if ($composer_autoload = config_item('composer_autoload'))
{
    if ($composer_autoload === TRUE)
    {
        file_exists(APPPATH.'vendor/autoload.php')
            ? require_once(APPPATH.'vendor/autoload.php')
            : log_message('error', '$config[\'composer_autoload\'] is set to TRUE but '.APPPATH.'vendor/autoload.php was not found.');
    }
    elseif (file_exists($composer_autoload))
    {
        require_once($composer_autoload);
    }
    else
    {
        log_message('error', 'Could not find the specified $config[\'composer_autoload\'] path: '.$composer_autoload);
    }
}
```
`composer_autoload`有两种定义方式，一种是Boolean类型，为TRUE时表示composer自动加载，这时需要判断`APPPATH . vendor/autoload.php`文件是否存在然后再来加载；另外一种时直接定义为加载文件名`$config['composer_autoload'] = '/path/to/vendor/autoload.php';`，具体参考<b>APPPATH . config/config.php</b>。

---

#### 加载核心类组件 ####
通常，CI框架中不同的功能均由不同的组件来完成（如Log组件主要用于记录日志，Input组件则用于处理用户的GET,POST等数据）这种模块化的方式使得各组件之间的耦合性较低，从而也便于扩展。

##### 基准点组件 #####
```text
$BM =& load_class('Benchmark', 'core');
$BM->mark('total_execution_time_start');
$BM->mark('loading_time:_base_classes_start');
```
Benchmark主要用于记录各种时间点、记录内存使用等参数，便于性能测试和追踪，说白了就是用来计算程序运行消耗的时间和内存。

##### 钩子组件 #####
```gherkin
$EXT =& load_class('Hooks', 'core');
$EXT->call_hook('pre_system');
```
CI的扩展组件用于在不改变CI核心的基础上改变或者增加系统的核心运行功能。Hook钩子允许在系统运行的各个挂钩点（hook point）添加自定义的功能，如pre_system，pre_controller,post_controller等预定义的挂钩点，具体参考<b>APPPATH . config/hooks.php</b>。

##### 配置组件 #####
```gherkin
$CFG =& load_class('Config', 'core');
if (isset($assign_to_config) && is_array($assign_to_config))
{
    foreach ($assign_to_config as $key => $value)
    {
        $CFG->set_item($key, $value);
    }
}
```
Config配置管理组件主要用于加载配置文件、获取和设置配置项等。这里包含了对$assign_to_config的处理：如果有在index.php定义配置数组，那么就丢给配置组件CFG，以后就由CFG来保管了配置信息了。

##### 设置默认字符编码 #####
```text
$charset = strtoupper(config_item('charset'));
ini_set('default_charset', $charset);
if (extension_loaded('mbstring'))
{
    define('MB_ENABLED', TRUE);
    @ini_set('mbstring.internal_encoding', $charset);
    mb_substitute_character('none');
}
else
{
    define('MB_ENABLED', FALSE);
}
if (extension_loaded('iconv'))
{
    define('ICONV_ENABLED', TRUE);
    @ini_set('iconv.internal_encoding', $charset);
}
else
{
    define('ICONV_ENABLED', FALSE);
}
if (is_php('5.6'))
{
    ini_set('php.internal_encoding', $charset);
}
```
这里功能如下：
1. 设置默认字符集，可在配置文件中进行相关配置。
2. 如果php启用`mbstring`扩展，则设置常量`MB_ENABLED`为TRUE，<font color="#891717">注意：此功能自PHP5.6.0起已被弃用</font>；设置默认的内部字符编码使网站成为多语言站点；设置替代字符，当输入字符的编码无效时则替换为null，即不输出。
3. 如果php启用`iconv`扩展，则设置常量`ICONV_ENABLED`为TRUE，<font color="#891717">注意：此功能自PHP5.6.0起已被弃用</font>。



---

#### 路由的设置与判断 ####

---

#### 解析请求的类，并调用请求的方法 ####

---

#### 输出 ####

---

#### 参考链接 ####

[CI框架源码解析二之引导文件CodeIgniter.php](https://blog.csdn.net/Zhihua_W/article/details/52821598)
