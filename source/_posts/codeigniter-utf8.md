---
title: CodeIgniter编码类文件Utf8.php
date: 2020-01-13 21:02:32
tags:
- PHP
- Codeigniter
categories:
- 开发者手册
---

#### 引言 ####
ASCII字符的编号从1到128 az，AZ，0-9和标点符号。这对于英语很好，但是那里几乎所有其他语言的字符都不适合那里。为了解决这个问题，我们提供了UTF-8，它可以将额外的字符存储为多位，并向后兼容ASCII。CodeIgniter的Utf8类除构造方法外有`clean_string()`、`safe_ascii_for_xml()`、`convert_to_utf8()`、`is_ascii()`。
<!-- more -->

---

#### __construct() ####
```text
public function __construct()
{
    if (
        defined('PREG_BAD_UTF8_ERROR')				// PCRE must support UTF-8
        && (ICONV_ENABLED === TRUE OR MB_ENABLED === TRUE)	// iconv or mbstring must be installed
        && strtoupper(config_item('charset')) === 'UTF-8'	// Application charset must be UTF-8
        )
    {
        define('UTF8_ENABLED', TRUE);
        log_message('debug', 'UTF-8 Support Enabled');
    }
    else
    {
        define('UTF8_ENABLED', FALSE);
        log_message('debug', 'UTF-8 Support Disabled');
    }
    log_message('info', 'Utf8 Class Initialized');
}
```
该构造方法的功能首先判断如果正则表达式支持utf8，iconv库或mbstring库已经安装，应用程序字符集是utf8,那么定义常量UTF8_ENABLED 值为 true，记录日志：UTF-8 Support Enabled。否则设置常量UTF8_ENABLED 为false，记录日志：UTF-8 Support Disabled。最后记录日志信息 Utf8 Class Initialized。

----

#### clean_string() ####
```text
public function clean_string($str)
{
    if ($this->is_ascii($str) === FALSE)
    {
        if (MB_ENABLED)
        {
            $str = mb_convert_encoding($str, 'UTF-8', 'UTF-8');
        }
        elseif (ICONV_ENABLED)
        {
            $str = @iconv('UTF-8', 'UTF-8//IGNORE', $str);
        }
    }
    return $str;
}
```
该方法默认在输入类`Input`中使用，用于判断字符串不为ASCII码的情况下使用[mb_convert_encoding()](https://www.php.net/manual/zh/function.mb-convert-encoding)或[iconv()](https://www.php.net/manual/zh/function.iconv)函数将字符串转换为`UTF-8`。


----

#### safe_ascii_for_xml() ####
```text
public function safe_ascii_for_xml($str)
{
    return remove_invisible_characters($str, FALSE);
}
```
该方法用于删除所有在xml中可能导致问题的ASCII码字符，除了**水平制表符**、**换行**、**回车**。直接调用[remove_invisible_characters()](https://pureven.cc/2019/12/23/codeigniter-common/)来删除无效的字符并返回。

----

#### convert_to_utf8() ####
```text
public function convert_to_utf8($str, $encoding)
{
    if (MB_ENABLED)
    {
        return mb_convert_encoding($str, 'UTF-8', $encoding);
    }
    elseif (ICONV_ENABLED)
    {
        return @iconv($encoding, 'UTF-8', $str);
    }
    return FALSE;
}
```
该方法用于将字符串转换为UTF-8编码，如果支持mbstring则使用mb_convert_encoding()进行转换、否则如果支持iconv则使用iconv()进行转换。

----

#### is_ascii() ####
```text
public function is_ascii($str)
{
    return (preg_match('/[^\x00-\x7F]/S', $str) === 0);
}
```
该方法用于检测字符串是不是ASCII码。`[^\x00-\x7F]`匹配ASCII值从0-127的单字节字符，也就是数字、英文字母、半角符号以及某些控制字符。`/S`表示非空白字符。

----


#### 参考链接 ####
[CI框架源码解析七之编码类文件Utf8.php](https://blog.csdn.net/Zhihua_W/article/details/52868786)
