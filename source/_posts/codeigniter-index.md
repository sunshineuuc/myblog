---
title: CodeIgniter入口文件index.php
date: 2019-12-16 21:33:50
tags:
- PHP
- Codeigniter
categories:
- 开发者手册
---

#### 引言 ####

index.php是CodeIgniter（简称CI）框架的入口文件，一共完成了四项工作：

- 设置框架应用的环境状态
- 配置系统、应用、视图等程序目录以及得到其路径
- 系统、应用、视图等目录的正确性验证
- 载入 core/CodeIgniter.php框架核心文件，启动框架

<!-- more -->

---

#### 设置框架应用的环境状态 ####

```gherkin
define('ENVIRONMENT', isset($_SERVER['CI_ENV']) ? $_SERVER['CI_ENV'] : 'development');
```
`CI_ENV`可在`.env`文件中定义，.env文件位于项目根目录下，作为全局环境配置文件，通过 .env文件 加载环境变量并且能够自动的通过 `getenv()`, `$_ENV`和 `$_SERVER` 自动调用,如文件内容`CI_ENV=production`表示将运行环境设置为production。如果没有指定则默认为`development`。

CI框架设置了三种应用场景状态，分别是：**开发**-`development`，**测试**-`testing`，**产品**-`production`，**开发**-`development`状态，**默认**的状态下会产生错误报告，**测试**，**产品**状态下则不会产生错误报告，否则CI框架会认为你没有配置好相应的环境，从而退出进程并给出对应的错误信息：
```gherkin
switch (ENVIRONMENT)
{
	case 'development':
		error_reporting(-1);
		ini_set('display_errors', 1);
	break;

	case 'testing':
	case 'production':
		ini_set('display_errors', 0);
		if (version_compare(PHP_VERSION, '5.3', '>='))
		{
			error_reporting(E_ALL & ~E_NOTICE & ~E_DEPRECATED & ~E_STRICT & ~E_USER_NOTICE & ~E_USER_DEPRECATED);
		}
		else
		{
			error_reporting(E_ALL & ~E_NOTICE & ~E_STRICT & ~E_USER_NOTICE);
		}
	break;

	default:
		header('HTTP/1.1 503 Service Unavailable.', TRUE, 503);
		echo 'The application environment is not set correctly.';
		exit(1); // EXIT_ERROR
}
```
设置ENVIRONMENT的一个好处是：可以很方便的切换系统的配置而不必修改系统代码。例如，在系统进入测试阶段时，database配置为测试的数据库，而在系统测试完毕时，database切换到线上的数据库。这好比是用一个开关控制了系统的环境切换，自然是非常方便的。

---

#### 配置系统、应用、视图等程序目录以及得到其路径 ####

 CI框架允许你将系统核心源码和应用程序代码进行分开放置，但是你必须设定好系统的system文件夹和application文件夹（同样，文件夹名字可以是任何合法的文件夹名称，而不一定使用’system’和’application’）的名称、路径等信息：
 ```gherkin
$system_path = 'system';
$application_folder = 'application';
$view_folder = '';
```

如果时CLI模式，运行的一般像`php filename.php`这样直接运行php脚本文件，因此需要将php脚本文件所在目录变为当前工作目录，如下：
```gherkin
// Set the current directory correctly for CLI requests
if (defined('STDIN'))
{
    chdir(dirname(__FILE__));
}
```

---

#### 系统、应用、视图等目录的正确性验证 ####

##### 系统(system)文件目录的正确性验证 #####
```gherkin
if (($_temp = realpath($system_path)) !== FALSE)
{
    $system_path = $_temp.DIRECTORY_SEPARATOR;
}
else
{
    // Ensure there's a trailing slash
    $system_path = strtr(
        rtrim($system_path, '/\\'),
        '/\\',
        DIRECTORY_SEPARATOR.DIRECTORY_SEPARATOR
    ).DIRECTORY_SEPARATOR;
}

// Is the system path correct?
if ( ! is_dir($system_path))
{
    header('HTTP/1.1 503 Service Unavailable.', TRUE, 503);
    echo 'Your system folder path does not appear to be set correctly. Please open the following file and correct this: '.pathinfo(__FILE__, PATHINFO_BASENAME);
    exit(3); // EXIT_CONFIG
}
```

##### 应用(application)文件目录的正确性验证 #####
```gherkin
// The path to the "application" directory
if (is_dir($application_folder))
{
    if (($_temp = realpath($application_folder)) !== FALSE)
    {
        $application_folder = $_temp;
    }
    else
    {
        $application_folder = strtr(
            rtrim($application_folder, '/\\'),
            '/\\',
            DIRECTORY_SEPARATOR.DIRECTORY_SEPARATOR
        );
    }
}
elseif (is_dir(BASEPATH.$application_folder.DIRECTORY_SEPARATOR))
{
    $application_folder = BASEPATH.strtr(
        trim($application_folder, '/\\'),
        '/\\',
        DIRECTORY_SEPARATOR.DIRECTORY_SEPARATOR
    );
}
else
{
    header('HTTP/1.1 503 Service Unavailable.', TRUE, 503);
    echo 'Your application folder path does not appear to be set correctly. Please open the following file and correct this: '.SELF;
    exit(3); // EXIT_CONFIG
}
```

##### 视图(view)文件目录的正确性验证 #####
```gherkin
// The path to the "views" directory
if ( ! isset($view_folder[0]) && is_dir(APPPATH.'views'.DIRECTORY_SEPARATOR))
{
    $view_folder = APPPATH.'views';
}
elseif (is_dir($view_folder))
{
    if (($_temp = realpath($view_folder)) !== FALSE)
    {
        $view_folder = $_temp;
    }
    else
    {
        $view_folder = strtr(
            rtrim($view_folder, '/\\'),
            '/\\',
            DIRECTORY_SEPARATOR.DIRECTORY_SEPARATOR
        );
    }
}
elseif (is_dir(APPPATH.$view_folder.DIRECTORY_SEPARATOR))
{
    $view_folder = APPPATH.strtr(
        trim($view_folder, '/\\'),
        '/\\',
        DIRECTORY_SEPARATOR.DIRECTORY_SEPARATOR
    );
}
else
{
    header('HTTP/1.1 503 Service Unavailable.', TRUE, 503);
    echo 'Your view folder path does not appear to be set correctly. Please open the following file and correct this: '.SELF;
    exit(3); // EXIT_CONFIG
}
```

##### 目录相关常量定义 #####
```gherkin
// The name of THIS file
define('SELF', pathinfo(__FILE__, PATHINFO_BASENAME));

// Path to the system directory
define('BASEPATH', $system_path);

// Path to the front controller (this file) directory
define('FCPATH', dirname(__FILE__).DIRECTORY_SEPARATOR);

// Name of the "system" directory
define('SYSDIR', basename(BASEPATH));

// APPPPATH
define('APPPATH', $application_folder.DIRECTORY_SEPARATOR);

// VIEWPATH
define('VIEWPATH', $view_folder.DIRECTORY_SEPARATOR);
```

`注`: 查看所有常量的方法：`var_dump(get_defined_constants());`

---

#### 载入 core/CodeIgniter.php框架核心文件，启动框架 ####

入口文件的最后一行，引入CodeIgniter.php框架核心文件（也是下一步框架执行的关键）。CodeIgniter.php被称为bootstrap file，也就是它是一个引导文件，是CI框架执行流程的核心文件。
```gherkin
/*
 * --------------------------------------------------------------------
 * LOAD THE BOOTSTRAP FILE
 * --------------------------------------------------------------------
 *
 * And away we go...
 */
require_once BASEPATH.'core/CodeIgniter.php';
```

---

#### 参考链接 ####

[《CI框架源码解析一之入口文件index.php》](https://blog.csdn.net/Zhihua_W/article/details/52815892)
