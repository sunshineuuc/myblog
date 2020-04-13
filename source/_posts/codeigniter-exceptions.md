---
title: CodeIgniter异常类文件Exceptions.php
date: 2020-02-22 16:37:52
tags:
- PHP
- Codeigniter
categories:
- 开发者手册
---

#### 引言 ####
异常类用于异常提示，该类定义了三种类型或级别的异常提示，即错误类型的消息、调试类型的消息和信息类型的消息。
<!--more-->

---

#### 成员变量 ####
```php
public $ob_level; // 嵌套的输出缓冲处理程序的级别；如果输出缓冲区不起作用，返回零。
public $levels = array(
    E_ERROR                 =>	'Error',   // 致命错误
    E_WARNING               =>	'Warning', // 非致命运行错误
    E_PARSE                 =>	'Parsing Error', // 编译错误
    E_NOTICE                =>	'Notice',        // notice错误
    E_CORE_ERROR            =>	'Core Error',   // php启动时致命错误
    E_CORE_WARNING          =>	'Core Warning', // php启动时非致命错误
    E_COMPILE_ERROR         =>	'Compile Error',  // php致命编译错误
    E_COMPILE_WARNING       =>	'Compile Warning',// php非致命编译错误
    E_USER_ERROR            =>	'User Error',  // 致命的用户错误
    E_USER_WARNING          =>	'User Warning',// 非致命的用户警告
    E_USER_NOTICE           =>	'User Notice', // 用户生成的通知
    E_STRICT                =>	'Runtime Notice'   // Run-time通知，提高代码稳定可靠性
);
```

---

#### __construct() ####
```php
public function __construct()
{
    $this->ob_level = ob_get_level();// 输出缓冲机制的嵌套级别
    // Note: Do not log messages from this constructor.
}
```
[ob_get_level](https://www.php.net/manual/zh/function.ob-get-level.php)

---

#### log_exception() ####
```php
public function log_exception($severity, $message, $filepath, $line)
{
    $severity = isset($this->levels[$severity]) ? $this->levels[$severity] : $severity;
    log_message('error', 'Severity: '.$severity.' --> '.$message.' '.$filepath.' '.$line); // 记录错误日志
}
```

---

#### show_404() ####
```php
/*show_404()是show_error()中的一种特殊情况，就是请求不存在的情况，响应一个404错误*/
public function show_404($page = '', $log_error = TRUE)
{
    if (is_cli())
    {
        $heading = 'Not Found';
        $message = 'The controller/method pair you requested was not found.';
    }
    else
    {
        $heading = '404 Page Not Found';
        $message = 'The page you requested was not found.';
    }

    // By default we log this, but allow a dev to skip it
    if ($log_error)
    {
        log_message('error', $heading.': '.$page);
    }

    echo $this->show_error($heading, $message, 'error_404', 404); // 调的show_error()方法
    exit(4); // EXIT_UNKNOWN_FILE
}
```

---

#### show_error() ####
```php
/*
* show_error()是有意识触发的错误，不是代码写错，
* 而是代码不当，或者用户操作不当，比如找不到控制器，指定方法之类的，
* CI就show一个错误出来，当然开发者也可以调用此方法响应一个错误信息，
* 某种程度上类似于catch到一个exception之后的处理，然后根据exception发出不同的提示信息。
*/
public function show_error($heading, $message, $template = 'error_general', $status_code = 500)
{
    $templates_path = config_item('error_views_path');
    if (empty($templates_path))
    {
        $templates_path = VIEWPATH.'errors'.DIRECTORY_SEPARATOR;
    }

    //默认是500，内部服务错误。是指由于程序代码写得不恰当而引起的，因此向浏览器回应一个内部错误。
    if (is_cli())
    {
        $message = "\t".(is_array($message) ? implode("\n\t", $message) : $message);
        $template = 'cli'.DIRECTORY_SEPARATOR.$template;
    }
    else
    {
        set_status_header($status_code);
        $message = '<p>'.(is_array($message) ? implode('</p><p>', $message) : $message).'</p>';
        $template = 'html'.DIRECTORY_SEPARATOR.$template;
    }

    // 缓冲机制是有嵌套级别的，
    // 这个if判断是说发生错误的缓冲级别和Exception被加载【刚开始】的缓冲级别相差1以上
    // 看core/Loader.php中的_ci_load() CI在加载view的时候先ob_start(),然后由output处理输出，
    // 因此，如果是在视图文件发生错误，则就会出现缓冲级别相差1的情况，此时先把输出的内容给flush出来，然后再把错误信息输出。
    // 此处的作用与show_php_error()中的相应位置作用一样
    if (ob_get_level() > $this->ob_level + 1)
    {
        ob_end_flush();
    }
    ob_start();
    //错误信息模板，位于应用目录errors/下。
    include($templates_path.$template.'.php');
    $buffer = ob_get_contents();
    ob_end_clean();
    //这里是return，因为一般情况下，是使用core/Common.php中，
    //全局函数show_error()间接使用当前Exception::show_error()方法。
    return $buffer;
}
```

---

#### show_exception() ####
```php
public function show_exception($exception)
{
    $templates_path = config_item('error_views_path');
    if (empty($templates_path))
    {
        $templates_path = VIEWPATH.'errors'.DIRECTORY_SEPARATOR;
    }

    $message = $exception->getMessage();
    if (empty($message))
    {
        $message = '(null)';
    }
    if (is_cli())
    {
        $templates_path .= 'cli'.DIRECTORY_SEPARATOR;
    }
    else
    {
        $templates_path .= 'html'.DIRECTORY_SEPARATOR;
    }
    if (ob_get_level() > $this->ob_level + 1)
    {
        ob_end_flush();
    }

    ob_start();
    include($templates_path.'error_exception.php');
    $buffer = ob_get_contents();
    ob_end_clean();
    echo $buffer;
}
```

---

#### show_php_error() ####
```php
public function show_php_error($severity, $message, $filepath, $line)
{
    $templates_path = config_item('error_views_path');
    if (empty($templates_path))
    {
        $templates_path = VIEWPATH.'errors'.DIRECTORY_SEPARATOR;
    }

    // 取得对应错误级别相对的说明。在$this->levels中定义。
    $severity = isset($this->levels[$severity]) ? $this->levels[$severity] : $severity;

    // For safety reasons we don't show the full file path in non-CLI requests
    // 为了安全起见，只显示错误文件最后两段路径信息。
    if ( ! is_cli())
    {
        $filepath = str_replace('\\', '/', $filepath);
        if (FALSE !== strpos($filepath, '/'))
        {
            $x = explode('/', $filepath);
            $filepath = $x[count($x)-2].'/'.end($x);
        }

        $template = 'html'.DIRECTORY_SEPARATOR.'error_php';
    }
    else
    {
        $template = 'cli'.DIRECTORY_SEPARATOR.'error_php';
    }
    // ob_get_level()是取得当前缓冲机制的嵌套级别。（缓冲是可以一层嵌一层的。）
    // 右边的$this->ob_level是在__construct()里面同样通过ob_get_level()被赋值的。
    // 也就是说，有可能出现：Exception组件被加载时（也就是应用刚开始运行时）的缓冲级别
    // （其实也就是程序最开始的时候的缓冲级别，那时候是还没有ob_start()过的），
    // 与发生错误的时候的缓冲级别相差1。
    // 在控制器执行$this->load->view("xxx");的时候，实质，Loader引入并执行这个视图文件的时候，
    // 是先把缓冲打开，即先ob_start()，所有输出放到缓冲区（详见：core/Loader.php中的_ci_load()）,
    // 然后再由Output处理输出。因此，如果是在视图文件发生错误，则就会出现缓冲级别相差1的情况，
    // 此时先把输出的内容给flush出来，然后再把错误信息输出。
    if (ob_get_level() > $this->ob_level + 1)
    {
        ob_end_flush();
    }
    ob_start();
    include($templates_path.$template.'.php');
    $buffer = ob_get_contents();
    ob_end_clean();
    echo $buffer;
}
```

---

#### 参考链接 ####
[CI框架源码解析十七之异常处理类文件Exceptions.php](https://blog.csdn.net/Zhihua_W/article/details/52962786)
