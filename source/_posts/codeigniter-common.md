---
title: CodeIgniter全局函数库文件Common.php
date: 2019-12-23 18:30:37
tags:
- php
- codeigniter
categories:
- web工作笔记
---

#### 引言 ####

Common.php文件定义了一系列的全局函数，CI引导文件<b>CodeIgniter.php</b>开头加载完常量后最先加载的就是Common.php文件，然后使用全局函数加载后面的组件、判断PHP版本等等一系列操作。全局函数库文件中的函数有: `is_php()`、`is_really_writable()`、`load_class()`、`is_loaded()`、`get_config()`、`config_item()`、`get_mimes()`、`is_https()`、`is_cli()`、`show_error()`、`show_404()`、`log_message()`、`set_status_header()`、`_error_handler()`、`_exception_handler()`、`_shutdown_handler()`、`remove_invisible_characters()`、`html_escape()`、`_stringify_attributes()`、`function_usable()`等，下面进行逐一分析。

---

#### is_php() ####
```text
if ( ! function_exists('is_php'))
{
	function is_php($version)
	{
		static $_is_php;
		$version = (string) $version;
		if ( ! isset($_is_php[$version]))
		{
			$_is_php[$version] = version_compare(PHP_VERSION, $version, '>=');
		}
		return $_is_php[$version];
	}
}
```
这个函数的作用是判断当前环境的PHP版本是否是指定版本`$version`或更高版本。<font color="#891717">因为CI框架中有一些配置依赖于PHP的版本和行为（如magic_quotes，PHP5.3版本之前，该特性用于指定是否开启转义，而PHP5.3之后，该特性已经被废弃），为了向后兼容，当遇到magic_quotes、register_globals等后来版本已删除的功能时需要先进行版本判断，当运行环境PHP版本小于指定版本时禁用这些功能。在CodeIgniter.php文件中就是这么做的。</font>
功能实现: 
1. 定义一个静态数组变量`$_is_php`，用于存放比较结果。当下此再调用该方法比较PHP版本时会先遍历`$_is_php`数组，如果有记录则直接返回，没用则继续。
2. 版本比较： 通过[version_compare()](https://www.php.net/manual/zh/function.version-compare.php)方法比较当前版本和指定版本的大小关系，并将结果存入`$_is_php`数组。
3. 返回比较结果，这里直接返回数组中对应的结果。

---

#### is_really_writable() ####
```text
if ( ! function_exists('is_really_writable'))
{
	function is_really_writable($file)
	{
		if (DIRECTORY_SEPARATOR === '/' && (is_php('5.4') OR ! ini_get('safe_mode')))
		{
			return is_writable($file);
		}
		if (is_dir($file))
		{
			$file = rtrim($file, '/').'/'.md5(mt_rand());
			if (($fp = @fopen($file, 'ab')) === FALSE)
			{
				return FALSE;
			}
			fclose($fp);
			@chmod($file, 0777);
			@unlink($file);
			return TRUE;
		}
		elseif ( ! is_file($file) OR ($fp = @fopen($file, 'ab')) === FALSE)
		{
			return FALSE;
		}
		fclose($fp);
		return TRUE;
	}
}
```
这个函数用于判断文件或者目录是否真实可写，一般情况下，通过内置函数[is_writable()](https://www.php.net/manual/zh/function.is-writable)返回的结果是比较可靠的，但是也有一些例外，比如:
1. Windows中，如果对文件或者目录设置了只读属性，则is_writable返回结果是true,但是却无法写入。
2. Linux系统中，如果开启了Safe Mode，则也会影响is_writable的结果。
因此，本函数的处理是：如果是一般的Linux系统且没有开启safe mode，则直接调用is_writable；否则如果是目录则尝试在目录中创建一个文件来检查目录是否可写，如果是文件，则尝试以写入模式打开文件，如果无法打开，则返回false，最后调用fclose关闭句柄。

---

#### load_class() ####
```text
if ( ! function_exists('load_class'))
{
	function &load_class($class, $directory = 'libraries', $param = NULL)
	{
		static $_classes = array();
		if (isset($_classes[$class]))
		{
			return $_classes[$class];
		}
		$name = FALSE;
		foreach (array(APPPATH, BASEPATH) as $path)
		{
			if (file_exists($path.$directory.'/'.$class.'.php'))
			{
				$name = 'CI_'.$class;
				if (class_exists($name, FALSE) === FALSE)
				{
					require_once($path.$directory.'/'.$class.'.php');
				}
				break;
			}
		}
		if (file_exists(APPPATH.$directory.'/'.config_item('subclass_prefix').$class.'.php'))
		{
			$name = config_item('subclass_prefix').$class;
			if (class_exists($name, FALSE) === FALSE)
			{
				require_once(APPPATH.$directory.'/'.$name.'.php');
			}
		}
		if ($name === FALSE)
		{
			set_status_header(503);
			echo 'Unable to locate the specified class: '.$class.'.php';
			exit(5);
		}
		is_loaded($class);
		$_classes[$class] = isset($param)
			? new $name($param)
			: new $name();
		return $_classes[$class];
	}
}
```
功能实现：
1. 定义静态数组`$_classes`，用于存放类的实例。
2. 判断`$_classes`中是否存在该类的实例，如果存在则返回，该方法避免重复加载类实例，类似于单例模式。
3. 分别从<b>APPPATH</b>和<b>BASEPATH</b>目录下寻找指定目录`$directory`，然后找`$class . 'php'`文件，如果找到则将类名设置为<b color="#891717">'CI_'.$class</b>，加载该类文件并退出当前循环。
4. 从<b>APPPATH</b>目录下寻找指定目录`$directory`，然后寻找带有前缀的`config_item('subclass_prefix').$class.'.php'`文件，也叫扩展类文件，找到后将类名<font color="#891717">重新</font>设置为<b>扩展类文件名</b>并加载该扩展类文件。<b><font color="#891717">注意: 如果找到扩展类文件，后面是对该扩展类进行实例化的，即CI加载的实际上是该扩展类。这意味着，可以对CI的核心进行修改或者扩展。</font></b>
5. 如果不曾找到要加载的类文件，即$name依然为<b>FALSE</b>，则报错退出。
6. 调用`is_loaded()`方法将类名存入静态数组`$_is_loaded`。
7. 实例化该类并将该实例存入静态数组`$_classes`。

<b><font color="#891717">注意: 该函数返回的是一个class实例的引用. 对该实例的任何改变，都会影响下一次函数调用的结果。</font></b>

---

#### is_loaded() ####
```text
if ( ! function_exists('is_loaded'))
{
	function &is_loaded($class = '')
	{
		static $_is_loaded = array();
		if ($class !== '')
		{
			$_is_loaded[strtolower($class)] = $class;
		}
		return $_is_loaded;
	}
}
```
该函数定义静态数组`$_is_loaded`并将`load_class()`函数实例化后的对象名放入此数组中，最后返回所有已加载的类，在控制器类中使用过此函数获取所有已加载的类。此函数通常用于追踪所有已加载的类。

---

#### get_config() ####
```text
if ( ! function_exists('get_config'))
{
	function &get_config(Array $replace = array())
	{
		static $config;
		if (empty($config))
		{
			$file_path = APPPATH.'config/config.php';
			$found = FALSE;
			if (file_exists($file_path))
			{
				$found = TRUE;
				require($file_path);
			}
			if (file_exists($file_path = APPPATH.'config/'.ENVIRONMENT.'/config.php'))
			{
				require($file_path);
			}
			elseif ( ! $found)
			{
				set_status_header(503);
				echo 'The configuration file does not exist.';
				exit(3);
			}
			if ( ! isset($config) OR ! is_array($config))
			{
				set_status_header(503);
				echo 'Your config file does not appear to be formatted correctly.';
				exit(3);
			}
		}
		foreach ($replace as $key => $val)
		{
			$config[$key] = $val;
		}
		return $config;
	}
}
```
功能实现:
1. 定义静态数组`$config`。
2. 如果数组为空则加载配置文件`APPPATH.'config/config.php'`，由于这里是静态数组，这意味着该函数支持动态运行的过程中修改Config.php中的条目。
3. 如果有根据当前运行环境自定义的配置文件则加载对应的配置文件。
4. 如果没找到配置文件则报错退出，同时由于CI的配置文件中是通过数组形式进行配置的，如:`$config['index_page'] = 'index.php';`，因此如果发现`$config`不是数组同样报错退出。
5. 这里比较给力，对于配置文件中的配置是可以覆盖的，比如CodeIgniter.php文件中的`get_config(array('subclass_prefix' => $assign_to_config['subclass_prefix']));`就是通过这里将子类前缀进行覆盖。
6. 返回静态数组`$config`。

<b><font color="#891717">注意: 该函数返回的是config文件中$config的引用。若运行过程中改变了Config的配置文件，由于该函数的缓存原因，无法读取最新的配置。</font></b>

---

#### config_item() ####
```text
if ( ! function_exists('config_item'))
{
	function config_item($item)
	{
		static $_config;
		if (empty($_config))
		{
			$_config[0] =& get_config();
		}
		return isset($_config[0][$item]) ? $_config[0][$item] : NULL;
	}
}
```
该函数的作用是返回相应的设置条目。需要注意两个地方:
1. `$_config[0] =& get_config();`中`&`不能省略，引用返回需要两边都用`&`。详见[引用返回](https://www.php.net/manual/zh/language.references.return.php)。
2. `$_config[0] =& get_config();` 这里官方的解释是引用不能直接赋值给静态变量，因此使用的是数组的形式。其实原因是引用不是静态存储的，具体可参考[变量范围](https://www.php.net/manual/zh/language.variables.scope.php#language.variables.scope.static)。

---

#### get_mimes() ####
```text
if ( ! function_exists('get_mimes'))
{
	function &get_mimes()
	{
		static $_mimes;
		if (empty($_mimes))
		{
			$_mimes = file_exists(APPPATH.'config/mimes.php')
				? include(APPPATH.'config/mimes.php')
				: array();
			if (file_exists(APPPATH.'config/'.ENVIRONMENT.'/mimes.php'))
			{
				$_mimes = array_merge($_mimes, include(APPPATH.'config/'.ENVIRONMENT.'/mimes.php'));
			}
		}
		return $_mimes;
	}
}
```
此函数跟get_config()类似，加载配置目录下mime.php文件并返回静态数组$_mimes的引用。

---

#### is_https() ####
```text
if ( ! function_exists('is_https'))
{
	function is_https()
	{
		if ( ! empty($_SERVER['HTTPS']) && strtolower($_SERVER['HTTPS']) !== 'off')
		{
			return TRUE;
		}
		elseif (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && strtolower($_SERVER['HTTP_X_FORWARDED_PROTO']) === 'https')
		{
			return TRUE;
		}
		elseif ( ! empty($_SERVER['HTTP_FRONT_END_HTTPS']) && strtolower($_SERVER['HTTP_FRONT_END_HTTPS']) !== 'off')
		{
			return TRUE;
		}
		return FALSE;
	}
}
```
这里满足三个条件中的任何一个就说明是通过请求为https请求:
1. $_SERVER['HTTPS']不为空且值不为'off'。
2. $_SERVER['HTTP_X_FORWARDED_PROTO']存在且值为'https'。
3. $_SERVER['HTTP_FRONT_END_HTTPS']不为空且值不为'off'。

---

#### is_cli() ####
```text
if ( ! function_exists('is_cli'))
{
	function is_cli()
	{
		return (PHP_SAPI === 'cli' OR defined('STDIN'));
	}
}
```
此函数通过`PHP_SAPI`和是否定义常量`STDIN`来判断当前运行模式是否为cli模式。

---

#### show_error() ####
```text
if ( ! function_exists('show_error'))
{
	function show_error($message, $status_code = 500, $heading = 'An Error Was Encountered')
	{
		$status_code = abs($status_code);
		if ($status_code < 100)
		{
			$exit_status = $status_code + 9;
			$status_code = 500;
		}
		else
		{
			$exit_status = 1; 
		}
		$_error =& load_class('Exceptions', 'core');
		echo $_error->show_error($heading, $message, 'error_general', $status_code);
		exit($exit_status);
	}
}
```
该函数用来展示错误信息并终止运行，功能实现
- 设置状态码。
- 加载`Exceptions`组件，并使用其中的`show_error()`方法打印错误信息。
- 终止程序运行。 

---

#### show_404() ####
```text
if ( ! function_exists('show_404'))
{
	function show_404($page = '', $log_error = TRUE)
	{
		$_error =& load_class('Exceptions', 'core');
		$_error->show_404($page, $log_error);
		exit(4); 
	}
}
```
该函数加载`Exceptions`组件，并使用其中的`show_404()`方法返回404页面。

---

#### log_message() ####
```text
if ( ! function_exists('log_message'))
{
	function log_message($level, $message)
	{
		static $_log;
		if ($_log === NULL)
		{
			$_log[0] =& load_class('Log', 'core');
		}
		$_log[0]->write_log($level, $message);
	}
}
```
该函数调用Log组件的write_log方法记录信息。<font color="#891717">注意: 如果主配置文件中log_threshold被设置为0，则不会记录任何Log信息。</font>

---

#### set_status_header() ####
```text
if ( ! function_exists('set_status_header'))
{
	function set_status_header($code = 200, $text = '')
	{
		if (is_cli())
		{
			return;
		}
		if (empty($code) OR ! is_numeric($code))
		{
			show_error('Status codes must be numeric', 500);
		}
		if (empty($text))
		{
			is_int($code) OR $code = (int) $code;
			$stati = array(
				100	=> 'Continue',
				101	=> 'Switching Protocols',
				200	=> 'OK',
				201	=> 'Created',
				202	=> 'Accepted',
				203	=> 'Non-Authoritative Information',
				204	=> 'No Content',
				205	=> 'Reset Content',
				206	=> 'Partial Content',
				300	=> 'Multiple Choices',
				301	=> 'Moved Permanently',
				302	=> 'Found',
				303	=> 'See Other',
				304	=> 'Not Modified',
				305	=> 'Use Proxy',
				307	=> 'Temporary Redirect',
				400	=> 'Bad Request',
				401	=> 'Unauthorized',
				402	=> 'Payment Required',
				403	=> 'Forbidden',
				404	=> 'Not Found',
				405	=> 'Method Not Allowed',
				406	=> 'Not Acceptable',
				407	=> 'Proxy Authentication Required',
				408	=> 'Request Timeout',
				409	=> 'Conflict',
				410	=> 'Gone',
				411	=> 'Length Required',
				412	=> 'Precondition Failed',
				413	=> 'Request Entity Too Large',
				414	=> 'Request-URI Too Long',
				415	=> 'Unsupported Media Type',
				416	=> 'Requested Range Not Satisfiable',
				417	=> 'Expectation Failed',
				422	=> 'Unprocessable Entity',
				426	=> 'Upgrade Required',
				428	=> 'Precondition Required',
				429	=> 'Too Many Requests',
				431	=> 'Request Header Fields Too Large',
				500	=> 'Internal Server Error',
				501	=> 'Not Implemented',
				502	=> 'Bad Gateway',
				503	=> 'Service Unavailable',
				504	=> 'Gateway Timeout',
				505	=> 'HTTP Version Not Supported',
				511	=> 'Network Authentication Required',
			);
			if (isset($stati[$code]))
			{
				$text = $stati[$code];
			}
			else
			{
				show_error('No status text available. Please check your status code number or supply your own message text.', 500);
			}
		}
		if (strpos(PHP_SAPI, 'cgi') === 0)
		{
			header('Status: '.$code.' '.$text, TRUE);
			return;
		}
		$server_protocol = (isset($_SERVER['SERVER_PROTOCOL']) && in_array($_SERVER['SERVER_PROTOCOL'], array('HTTP/1.0', 'HTTP/1.1', 'HTTP/2'), TRUE))
			? $_SERVER['SERVER_PROTOCOL'] : 'HTTP/1.1';
		header($server_protocol.' '.$code.' '.$text, TRUE, $code);
	}
}
```


---

#### _error_handler() ####

---

#### _exception_handler() ####

---

#### _shutdown_handler() ####

---

#### remove_invisible_characters() ####

---

#### html_escape() ####

---

#### _stringify_attributes() ####

---

#### function_usable() ####

---

#### 参考连接 ####

[CI框架源码解析三之全局函数库文件Common.php](https://blog.csdn.net/Zhihua_W/article/details/52838358)
