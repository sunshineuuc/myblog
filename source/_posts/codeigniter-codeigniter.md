---
title: CodeIgniter引导文件CodeIgniter.php
date: 2019-12-19 20:56:41
tags:
- PHP
- Codeigniter
categories:
- 开发者手册
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

函数信息可参考手册[set_error_handler()](https://www.php.net/manual/zh/function.set-error-handler.php)、[set_exception_handler()](https://www.php.net/manual/zh/function.set-exception-handler.php)、[register_shutdown_function()](https://www.php.net/manual/zh/function.register-shutdown-function)

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
CI的扩展组件用于在不改变CI核心的基础上改变或者增加系统的核心运行功能。Hook钩子允许在系统运行的各个挂钩点（hook point）添加自定义的功能，如pre_system，pre_controller,post_controller等预定义的挂钩点，具体参考<b>APPPATH . config/hooks.php</b>。这里加载完Hooks后首先调用pre_system钩子。

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
2. 如果php启用`mbstring`扩展，则设置常量`MB_ENABLED`为TRUE；设置默认的内部字符编码使网站成为多语言站点，<font color="#891717">注意：此功能自PHP5.6.0起已被弃用</font>；设置替代字符，当输入字符的编码无效时则替换为null，即不输出。
3. 如果php启用`iconv`扩展，则设置常量`ICONV_ENABLED`为TRUE，<font color="#891717">注意：此功能自PHP5.6.0起已被弃用</font>。
4. 如果PHP版本 >= 5.6, 使用`internal_encoding`来设置用于mbstring和iconv等多字节模块。默认为空。如果为空， 则使用`default_charset`。对于5.6已废弃的特性可参考[PHP 5.6.x 中已废止的特性](https://www.php.net/manual/zh/migration56.deprecated.php)

##### 加载兼容性函数 #####
```text
require_once(BASEPATH.'core/compat/mbstring.php');
require_once(BASEPATH.'core/compat/hash.php');
require_once(BASEPATH.'core/compat/password.php');
require_once(BASEPATH.'core/compat/standard.php');
```
CodeIgniter提供了一组兼容性函数，使您可以使用PHP本身可用的函数，但只能在更高版本或取决于特定扩展名的情况下使用。这些函数是自定义实现，它们自己也将具有一些依赖关系，但是如果您的PHP安装程序没有本地提供它们，它们仍然很有用。
<font color="#891717">注意: 与通用功能很相似，只要满足依赖关系，兼容性功能便始终可用。</font>

##### UTF8类 #####
```text
$UNI =& load_class('Utf8', 'core');
```
用于对UTF-8字符集处理的相关支持。其他组件如INPUT组件，需要改组件的支持。

##### URI类 #####
```text
$URI =& load_class('URI', 'core');
```
解析URI（Uniform Rescource Identifier）参数等.这个组件与RTR组件关系紧密。

##### Router类 #####
```text
$RTR =& load_class('Router', 'core', isset($routing) ? $routing : NULL);
```
路由组件，通过URI组件的参数解析，决定数据流向（路由）。

##### Output类 #####
```text
$OUT =& load_class('Output', 'core');
```
最终的输出管理组件，掌管着CI的最终输出。加载完Output类之后，调用`cache_override`钩子来判断如果有缓存则输出缓存，没用则继续。
<font color="#891717">注意</font>: `cache_override`钩子可以调用自己的函数来取代output类中的_display_cache() 函数.这可以使用自己的缓存显示方法
```text
if ($EXT->call_hook('cache_override') === FALSE && $OUT->_display_cache($CFG, $URI) === TRUE)
{
    exit;
}
```

##### Security类 #####
```text
$SEC =& load_class('Security', 'core');
```
用于安全性处理，比如防止跨站请求伪造等。

##### Input类 #####
```text
$IN	=& load_class('Input', 'core');
```
用于获取输入以及表单验证。

##### Lang类 #####
```text
$LANG =& load_class('Lang', 'core');
```
用于设置框架语言。

##### 加载控制器 #####
```text
require_once BASEPATH.'core/Controller.php';
function &get_instance()
{
    return CI_Controller::get_instance();
}
if (file_exists(APPPATH.'core/'.$CFG->config['subclass_prefix'].'Controller.php'))
{
    require_once APPPATH.'core/'.$CFG->config['subclass_prefix'].'Controller.php';
}
```
此处定义的get_instance方法返回一个引用，表明CI控制器拒绝副本，是单例模型。到这部核心组件加载完了，标记一下:
```text
$BM->mark('loading_time:_base_classes_end');
```

---

#### 路由的设置与判断 ####
```text
$e404 = FALSE;
$class = ucfirst($RTR->class);
$method = $RTR->method;
if (empty($class) OR ! file_exists(APPPATH.'controllers/'.$RTR->directory.$class.'.php'))
{
    $e404 = TRUE;
}
else
{
    require_once(APPPATH.'controllers/'.$RTR->directory.$class.'.php');
    if ( ! class_exists($class, FALSE) OR $method[0] === '_' OR method_exists('CI_Controller', $method))
    {
        $e404 = TRUE;
    }
    elseif (method_exists($class, '_remap'))
    {
        $params = array($method, array_slice($URI->rsegments, 2));
        $method = '_remap';
    }
    elseif ( ! method_exists($class, $method))
    {
        $e404 = TRUE;
    }
    elseif ( ! is_callable(array($class, $method)))
    {
        $reflection = new ReflectionMethod($class, $method);
        if ( ! $reflection->isPublic() OR $reflection->isConstructor())
        {
            $e404 = TRUE;
        }
    }
}
if ($e404)
{
    if ( ! empty($RTR->routes['404_override']))
    {
        if (sscanf($RTR->routes['404_override'], '%[^/]/%s', $error_class, $error_method) !== 2)
        {
            $error_method = 'index';
        }
        $error_class = ucfirst($error_class);
        if ( ! class_exists($error_class, FALSE))
        {
            if (file_exists(APPPATH.'controllers/'.$RTR->directory.$error_class.'.php'))
            {
                require_once(APPPATH.'controllers/'.$RTR->directory.$error_class.'.php');
                $e404 = ! class_exists($error_class, FALSE);
            }
            elseif ( ! empty($RTR->directory) && file_exists(APPPATH.'controllers/'.$error_class.'.php'))
            {
                require_once(APPPATH.'controllers/'.$error_class.'.php');
                if (($e404 = ! class_exists($error_class, FALSE)) === FALSE)
                {
                    $RTR->directory = '';
                }
            }
        }
        else
        {
            $e404 = FALSE;
        }
    }
    if ( ! $e404)
    {
        $class = $error_class;
        $method = $error_method;
        $URI->rsegments = array(
            1 => $class,
            2 => $method
        );
    }
    else
    {
        show_404($RTR->directory.$class.'/'.$method);
    }
}
```
CI认为下面这几种情况认为是404，如果找不到就调用show_404()函数:
1. 请求的class为空或class文件不存在:`empty($class) OR ! file_exists(APPPATH.'controllers/'.$RTR->directory.$class.'.php')`   
2. 请求的class不存在或请求的方法为私有方法或请求的是基类中的方法:`! class_exists($class, FALSE) OR $method[0] === '_' OR method_exists('CI_Controller', $method)`   
3. 请求的方法不存在:` ! method_exists($class, $method)`
4. 请求的不是公共方法: `! $reflection->isPublic() OR $reflection->isConstructor()`
如果请求的条件满足上面4个中的任何一个，则被认为是不合法的请求（或者是无法定位的请求），因此会被CI定向到404页面（值得注意的是，如果设置了404_override，并且404_override的class存在，并不会直接调用show_404并退出，而是会像正常的访问一样，实例化：$CI = new $class();）

获取请求参数:
```text
if ($method !== '_remap')
{
    $params = array_slice($URI->rsegments, 2);
}
```
路由选择和安全性检查都已完成后，调用pre_controller钩子，在开始执行前进行环境预处理，然后标记运行开始时间点:
```text
$EXT->call_hook('pre_controller');
$BM->mark('controller_execution_time_( '.$class.' / '.$method.' )_start');
```

---

#### 解析请求的类，并调用请求的方法 ####
```text
$CI = new $class();
$EXT->call_hook('post_controller_constructor');
call_user_func_array(array(&$CI, $method), $params);
```
实例化控制器类，然后调用`post_controller_constructor`钩子，再然后通过`call_user_func_array ( callable $callback , array $param_arr )`函数调用`$CI`类中的`$method`方法，参数为数组`$params`。

在控制器运行完成之后标记运行结束并调用`post_controller`钩子。
```text
$BM->mark('controller_execution_time_( '.$class.' / '.$method.' )_end');
$EXT->call_hook('post_controller');
```

---

#### 输出 ####
```text
if ($EXT->call_hook('display_override') === FALSE)
{
    $OUT->_display();
}
```
在未定义`display_override`钩子的情况下使用`_display()`函数完成最终输出，$this->load->view()之后，并不会直接输出，而是放在了缓存区。$Out->_display之后，才会设置缓存，并最终输出。
<font color="#891717">注意</font>: `display_override`钩子的作用是覆盖_display()函数, 用来在系统执行末尾向web浏览器发送最终页面.这允许你用自己的方法来显示.<b>这里需要通过 $this->CI =& get_instance()引用CI超级对象，然后这样的最终数据可以通过调用 $this->CI->output->get_output() 来获得。</b>

在最终渲染页面发送到浏览器后，浏览器接收完最终数据的系统末尾调用`post_system`钩子:
```text
$EXT->call_hook('post_system');
```

---

#### 参考链接 ####

[CI框架源码解析二之引导文件CodeIgniter.php](https://blog.csdn.net/Zhihua_W/article/details/52821598)
