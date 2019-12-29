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
该函数功能是自定义HTTP协议头信息。功能实现：
1. 命令行环境下直接退出。
2. 如果状态码即`$code`为空或不是数组则设置为`500`并说明状态码必须为整数。
3. 如果信息即`$text`为空则使用默认信息，CI默认支持的状态码。
4. 如果参数状态码没有出现在表格中则报错500并提示`No status text available. Please check your status code number or supply your own message text.`。
5. 检查web服务器和PHP之间的[接口类型](https://www.php.net/manual/zh/function.php-sapi-name.php)，如果检测到`cgi`则根据参数`$code`、`$text`设置HTTP头信息；否则从$_SERVER中获取协议信息并输出HTTP头。
<table>
<caption style="text-align:center">CI支持的默认状态码及描述信息</caption>
<tr><th width=80 style="text-align:center">code</th><th>text</th></tr>
<tr>
<td>100</td>
<td>Continue</td>
</tr>
<tr>
<td>101</td>
<td>Switching Protocols</td>
</tr>
<tr>
<td>200</td>
<td>OK</td>
</tr>
<tr>
<td>201</td>
<td>Created</td>
</tr>
<tr>
<td>202</td>
<td>Accepted</td>
</tr>
<tr>
<td>203</td>
<td>Non-Authoritative Information</td>
</tr>
<tr>
<td>204</td>
<td>No Content</td>
</tr>
<tr>
<td>205</td>
<td>Reset Content</td>
</tr>
<tr>
<td>206</td>
<td>Partial Content</td>
</tr>
<tr>
<td>300</td>
<td>Multiple Choices</td>
</tr>
<tr>
<td>301</td>
<td>Moved Permanently</td>
</tr>
<tr>
<td>302</td>
<td>Found</td>
</tr>
<tr>
<td>303</td>
<td>See Other</td>
</tr>
<tr>
<td>304</td>
<td>Not Modified</td>
</tr>
<tr>
<td>305</td>
<td>Use Proxy</td>
</tr>
<tr>
<td>307</td>
<td>Temporary Redirect</td>
</tr>
<tr>
<td>400</td>
<td>Bad Request</td>
</tr>
<tr>
<td>401</td>
<td>Unauthorized</td>
</tr>
<tr>
<td>402</td>
<td>Payment Required</td>
</tr>
<tr>
<td>403</td>
<td>Forbidden</td>
</tr>
<tr>
<td>404</td>
<td>Not Found</td>
</tr>
<tr>
<td>405</td>
<td>Method Not Allowed</td>
</tr>
<tr>
<td>406</td>
<td>Not Acceptable</td>
</tr>
<tr>
<td>407</td>
<td>Proxy Authentication Required</td>
</tr>
<tr>
<td>408</td>
<td>Request Timeout</td>
</tr>
<tr>
<td>409</td>
<td>Conflict</td>
</tr>
<tr>
<td>410</td>
<td>Gone</td>
</tr>
<tr>
<td>411</td>
<td>Length Required</td>
</tr>
<tr>
<td>412</td>
<td>Precondition Failed</td>
</tr>
<tr>
<td>413</td>
<td>Request Entity Too Large</td>
</tr>
<tr>
<td>414</td>
<td>Request-URI Too Long</td>
</tr>
<tr>
<td>415</td>
<td>Unsupported Media Type</td>
</tr>
<tr>
<td>416</td>
<td>Requested Range Not Satisfiable</td>
</tr>
<tr>
<td>417</td>
<td>Expectation Failed</td>
</tr>
<tr>
<td>422</td>
<td>Unprocessable Entity</td>
</tr>
<tr>
<td>426</td>
<td>Upgrade Required</td>
</tr>
<tr>
<td>428</td>
<td>Precondition Required</td>
</tr>
<tr>
<td>429</td>
<td>Too Many Requests</td>
</tr>
<tr>
<td>431</td>
<td>Request Header Fields Too Large</td>
</tr>
<tr>
<td>500</td>
<td>Internal Server Error</td>
</tr>
<tr>
<td>501</td>
<td>Not Implemented</td>
</tr>
<tr>
<td>502</td>
<td>Bad Gateway</td>
</tr>
<tr>
<td>503</td>
<td>Service Unavailable</td>
</tr>
<tr>
<td>504</td>
<td>Gateway Timeout</td>
</tr>
<tr>
<td>505</td>
<td>HTTP Version Not Supported</td>
</tr>
<tr>
<td>511</td>
<td>Network Authentication Required</td>
</tr>
</table>

---

#### _error_handler() ####
```text
if ( ! function_exists('_error_handler'))
{
	function _error_handler($severity, $message, $filepath, $line)
	{
		$is_error = (((E_ERROR | E_PARSE | E_COMPILE_ERROR | E_CORE_ERROR | E_USER_ERROR) & $severity) === $severity);
		if ($is_error)
		{
			set_status_header(500);
		}
		if (($severity & error_reporting()) !== $severity)
		{
			return;
		}
		$_error =& load_class('Exceptions', 'core');
		$_error->log_exception($severity, $message, $filepath, $line);
		if (str_ireplace(array('off', 'none', 'no', 'false', 'null'), '', ini_get('display_errors')))
		{
			$_error->show_php_error($severity, $message, $filepath, $line);
		}
		if ($is_error)
		{
			exit(1);
		}
	}
}
```
该函数作为`set_error_handler`的回调函数来处理PHP脚本中出现的错误。功能实现:
1. 当错误类型为`E_ERROR`、`E_EPARSE`、`E_COMPILE_ERROR`、`E_CORE_ERROR`、`E_USER_ERROR`时，HTTP头设置为500。相关错误说明请参考[PHP预定义常量](https://www.php.net/manual/zh/errorfunc.constants.php)
2. 错误类型低于错误报告的级别则退出，否则加载`Exceptions`组件并调用show_php_error()方法显示错误。
3. 错误类型符合过滤条件则退出。

<font color="#891717"><b>注意</b>: 官网在set_error_handler()函数说明说明以下级别的错误不能由用户定义的函数来处理： E_ERROR、 E_PARSE、 E_CORE_ERROR、 E_CORE_WARNING、 E_COMPILE_ERROR、 E_COMPILE_WARNING，和在 调用 set_error_handler() 函数所在文件中产生的大多数 E_STRICT。即set_error_handler()用来自定义用户级错误 E_USER_ERROR、E_USER_WARNING 、E_USER_NOTICE、E_USER_DEPRECATED 和 部分运行时系统错误、E_WARING、E_NOTICE、E_DEPRECATED 的捕获器</font>

---

#### _exception_handler() ####
```text
if ( ! function_exists('_exception_handler'))
{
	function _exception_handler($exception)
	{
		$_error =& load_class('Exceptions', 'core');
		$_error->log_exception('error', 'Exception: '.$exception->getMessage(), $exception->getFile(), $exception->getLine());
		is_cli() OR set_status_header(500);
		if (str_ireplace(array('off', 'none', 'no', 'false', 'null'), '', ini_get('display_errors')))
		{
			$_error->show_exception($exception);
		}
		exit(1); // EXIT_ERROR
	}
}
```
该函数用来记录并显示php异常的信息。功能实现:
1. 加载Exceptions组件，调用log_exception()方法打印异常信息。
2. 如果不是命令行环境下则设置500HTTP头信息。
3. 如果开启了display_errors则通过`show_exception()`方法显示异常信息，最后退出。

---

#### _shutdown_handler() ####
```text
if ( ! function_exists('_shutdown_handler'))
{
	function _shutdown_handler()
	{
		$last_error = error_get_last();
		if (isset($last_error) &&
			($last_error['type'] & (E_ERROR | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING)))
		{
			_error_handler($last_error['type'], $last_error['message'], $last_error['file'], $last_error['line']);
		}
	}
}
```
该函数在php脚本执行完成或exit()后被调用，用来处理中止后的一些操作。功能实现:
1. 获取最后法生的错误信息，得到一个数组。该错误的**type**、**message**、**file**、**line**为数组的键。
2. 如果错误类型为<b>E_ERROR</b>、<b>E_PARSE</b>、**E_CORE_ERROR**、**E_CORE_WARNING**、**E_COMPILE_ERROR**、**E_COMPILE_WARNING**时调用`_error_handler`函数进行错误处理。

---

#### remove_invisible_characters() ####
```text
if ( ! function_exists('remove_invisible_characters'))
{
	function remove_invisible_characters($str, $url_encoded = TRUE)
	{
		$non_displayables = array();
		if ($url_encoded)
		{
			$non_displayables[] = '/%0[0-8bcef]/i';	// url encoded 00-08, 11, 12, 14, 15
			$non_displayables[] = '/%1[0-9a-f]/i';	// url encoded 16-31
			$non_displayables[] = '/%7f/i';	// url encoded 127
		}
		$non_displayables[] = '/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]+/S';	// 00-08, 11, 12, 14-31, 127
		do
		{
			$str = preg_replace($non_displayables, '', $str, -1, $count);
		}
		while ($count);
		return $str;
	}
}
```
该函数的作用是除去字符串中的不可见字符。功能实现:
- 构造过滤条件，即整理一个不可见字符的集合，用于字符串过滤。不可见字符有: 00-08 11 12 14 15 16-31 127，注意过滤时过滤的是对应[ASCII码](https://zh.wikipedia.org/wiki/ASCII)表中的十六进制形式。
- 使用[preg_replace()](https://www.php.net/manual/zh/function.preg-replace)函数将搜索并将不可见字符替换为空的方式去除不可见字符。$count为匹配的个数，当字符串中没有不可见字符时停止匹配。

---

#### html_escape() ####
```text
if ( ! function_exists('html_escape'))
{
	function html_escape($var, $double_encode = TRUE)
	{
		if (empty($var))
		{
			return $var;
		}
		if (is_array($var))
		{
			foreach (array_keys($var) as $key)
			{
				$var[$key] = html_escape($var[$key], $double_encode);
			}
			return $var;
		}
		return htmlspecialchars($var, ENT_QUOTES, config_item('charset'), $double_encode);
	}
}
```
该函数的作用时对数组中的元素$var递归调用[htmlspecialchars](https://www.php.net/manual/zh/function.htmlspecialchars)函数`将特殊字符转为HTML实体`。`ENT_QUOTES`表示既转换双引号也转换单引号。

---

#### _stringify_attributes() ####
```text
if ( ! function_exists('_stringify_attributes'))
{
	function _stringify_attributes($attributes, $js = FALSE)
	{
		$atts = NULL;
		if (empty($attributes))
		{
			return $atts;
		}
		if (is_string($attributes))
		{
			return ' '.$attributes;
		}
		$attributes = (array) $attributes;
		foreach ($attributes as $key => $val)
		{
			$atts .= ($js) ? $key.'='.$val.',' : ' '.$key.'="'.$val.'"';
		}
		return rtrim($atts, ',');
	}
}
```
该函数用于将HTML标签熟悉、JavaScript，将字符串、数组或属性的对象转换为字符串。

---

#### function_usable() ####
```text
if ( ! function_exists('function_usable'))
{
	function function_usable($function_name)
	{
		static $_suhosin_func_blacklist;
		if (function_exists($function_name))
		{
			if ( ! isset($_suhosin_func_blacklist))
			{
				$_suhosin_func_blacklist = extension_loaded('suhosin')
					? explode(',', trim(ini_get('suhosin.executor.func.blacklist')))
					: array();
			}
			return ! in_array($function_name, $_suhosin_func_blacklist, TRUE);
		}
		return FALSE;
	}
}
```
改函数用来判断PHP的内置函数是否可用，如果php启用了[Subosin扩展](https://suhosin.org/stories/index.html)，则可以通过`suhosin.executor.func.blacklist`禁用某些内置函数，如:`suhosin.executor.eval.blacklist=phpinfo,fputs,fopen,fwrite`。

---

#### 参考连接 ####

[CI框架源码解析三之全局函数库文件Common.php](https://blog.csdn.net/Zhihua_W/article/details/52838358)
