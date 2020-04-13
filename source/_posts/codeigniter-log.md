---
title: CodeIgniter日志类文件Log.php
date: 2020-02-22 18:27:35
tags:
- PHP
- Codeigniter
categories:
- 开发者手册
---

#### 引言 ####
日志记录类用于记录CI框架信息的一些操作日志(错误日志、调试日志、信息日志等等)。
<!--more-->

---

#### 成员变量 ####
```php
protected $_log_path; // 日志存放路径
protected $_file_permissions = 0644; // 写入的日志文件权限，默认0644，即rw-r--r--
protected $_threshold = 1;           // 允许写日志的阈值，默认为1。
/*
* 0 = Disables logging, Error logging TURNED OFF
* 1 = Error Messages (including PHP errors)
* 2 = Debug Messages
* 3 = Informational Messages
* 4 = All Messages
*/
// 也是允许写日志的阀值，但与$_threshold有些不同。
// 比如设置配置文件$config['log_threshold'] = 3，这个值会读到$_threshold属性中。
// 那么写日志允许的level可以是1，2，3；可是如果设置$config['log_threshold'] = [3],
// 那么系统会把这个3读到$_threshold_array数组中，写日志level只允许3，其它的1和2不允许。
protected $_threshold_array = array();
// 日志的时间格式，由$config['log_date_format']决定。默认'Y-m-d H:i:s'。
// 主要用于$date->format的参数。
protected $_date_fmt = 'Y-m-d H:i:s';
protected $_file_ext; // 日志文件的扩展名
protected $_enabled = TRUE; // 标记字段。标记是否有权限写日志。
// 预定义的level级别数组。
protected $_levels = array('ERROR' => 1, 'DEBUG' => 2, 'INFO' => 3, 'ALL' => 4);
protected static $func_overload;// 表示启用函数重载功能。
```

---

#### __construct() ####
```php
public function __construct()
{
    $config =& get_config();// 读取配置文件，获取$config数组。

    isset(self::$func_overload) OR self::$func_overload = (extension_loaded('mbstring') && ini_get('mbstring.func_overload')); // 确定是否支持函数重载

    // 确定日志文件路径
    $this->_log_path = ($config['log_path'] !== '') ? $config['log_path'] : APPPATH.'logs/';
    // 确定日志文件扩展名
    $this->_file_ext = (isset($config['log_file_extension']) && $config['log_file_extension'] !== '')
        ? ltrim($config['log_file_extension'], '.') : 'php';
    // 设置日志文件所在目录权限
    file_exists($this->_log_path) OR mkdir($this->_log_path, 0755, TRUE);
    // 确定日志文件所在目录是否可读以及是否是个目录
    if ( ! is_dir($this->_log_path) OR ! is_really_writable($this->_log_path))
    {
        $this->_enabled = FALSE;
    }
    // 确定设置的日志级别
    if (is_numeric($config['log_threshold']))
    {
        $this->_threshold = (int) $config['log_threshold'];
    }
    elseif (is_array($config['log_threshold']))
    {
        $this->_threshold = 0;
        $this->_threshold_array = array_flip($config['log_threshold']);
    }
    // 确定日志日期格式
    if ( ! empty($config['log_date_format']))
    {
        $this->_date_fmt = $config['log_date_format'];
    }
    // 确定创建的日志文件权限
    if ( ! empty($config['log_file_permissions']) && is_int($config['log_file_permissions']))
    {
        $this->_file_permissions = $config['log_file_permissions'];
    }
}
```

---

#### write_log() ####
```php
/**
* 写日志方法
* 该方法以下几种情况下不写：
* ① 目录没有写权限时。$this->_enabled===FALSE时。
* ② 阀值与Log记录等级不匹配时。
* ③ 文件打开失败时。
**/
public function write_log($level, $msg)
{
    // 目录没有写权限时，返回false退出。
    if ($this->_enabled === FALSE)
    {
        return FALSE;
    }

    $level = strtoupper($level);
    //写日志的level级别大于阈值设置值，同时level级别也不能匹配阈值数组中设置的值，返回FALSE退出
    if (( ! isset($this->_levels[$level]) OR ($this->_levels[$level] > $this->_threshold))
        && ! isset($this->_threshold_array[$this->_levels[$level]]))
    {
        return FALSE;
    }
    //设置文件全路径及名称
    $filepath = $this->_log_path.'log-'.date('Y-m-d').'.'.$this->_file_ext;
    $message = '';
    
    //新创建并且后缀为php的文件，系统首先在前面加上
    //"<?php defined('BASEPATH') OR exit('No direct script access allowed');\n\n"
    if ( ! file_exists($filepath))
    {
        $newfile = TRUE;
        // Only add protection to php files
        if ($this->_file_ext === 'php')
        {
            $message .= "<?php defined('BASEPATH') OR exit('No direct script access allowed'); ?>\n\n";
        }
    }
    //无法打开文件，返回FALSE退出
    if ( ! $fp = @fopen($filepath, 'ab'))
    {
        return FALSE;
    }

    flock($fp, LOCK_EX);
    //实例化时间
    // Instantiating DateTime with microseconds appended to initial date is needed for proper support of this format
    if (strpos($this->_date_fmt, 'u') !== FALSE)
    {
        $microtime_full = microtime(TRUE);
        $microtime_short = sprintf("%06d", ($microtime_full - floor($microtime_full)) * 1000000);
        $date = new DateTime(date('Y-m-d H:i:s.'.$microtime_short, $microtime_full));
        $date = $date->format($this->_date_fmt);
    }
    else
    {
        $date = date($this->_date_fmt);
    }
    //合成日志内容
    $message .= $this->_format_line($level, $date, $msg);
    // 写入文件
    for ($written = 0, $length = self::strlen($message); $written < $length; $written += $result)
    {
        if (($result = fwrite($fp, self::substr($message, $written))) === FALSE)
        {
            break;
        }
    }

    flock($fp, LOCK_UN);
    fclose($fp);
    // 更改文件权限
    if (isset($newfile) && $newfile === TRUE)
    {
        chmod($filepath, $this->_file_permissions);
    }

    return is_int($result);
}
```

---

#### _format_line() ####
```php
protected function _format_line($level, $date, $message)
{
    return $level.' - '.$date.' --> '.$message."\n";
}
```

---

#### strlen() ####
```php
protected static function strlen($str)
{
    return (self::$func_overload)
        ? mb_strlen($str, '8bit')
        : strlen($str);
}
```

---

#### substr() ####
```php
protected static function substr($str, $start, $length = NULL)
{
    if (self::$func_overload)
    {
        // mb_substr($str, $start, null, '8bit') returns an empty
        // string on PHP 5.3
        isset($length) OR $length = ($start >= 0 ? self::strlen($str) - $start : -$start);
        return mb_substr($str, $start, $length, '8bit');
    }

    return isset($length)
        ? substr($str, $start, $length)
        : substr($str, $start);
}
```

---

#### 参考链接 ####
[CI框架源码解析十八之日志记录类文件Log.php](https://blog.csdn.net/Zhihua_W/article/details/52964513)
