---
title: CodeIgniter基准测试类文件Benchmark.php
date: 2019-12-29 16:42:09
tags:
- PHP
- Codeigniter
categories:
- 开发者手册
---

#### 引言 ####

基准测试类文件Benchmark.php为CI框架第一个加载的core类组件，该组件的主要功能有:
- 记录程序运行时间。
- 记录程序运行内存、CPU使用情况。

该组件由三个方法组成，分别为`mark()`、`elapsed_time()`、`memory_usage()`。
<!-- more -->

---

#### mark() ####
```text
public function mark($name)
{
    $this->marker[$name] = microtime(TRUE);
}
```
该方法的作用是对$name做一个标记，以$name为key，使用[microtime(TRUE)](https://www.php.net/manual/zh/function.microtime)获取当前unix时间戳（单位:微秒数）作为value写入`$marker`数组中。

---

#### elapsed_time() ####
```text
public function elapsed_time($point1 = '', $point2 = '', $decimals = 4)
{
    if ($point1 === '')
    {
        return '{elapsed_time}';
    }
    if ( ! isset($this->marker[$point1]))
    {
        return '';
    }
    if ( ! isset($this->marker[$point2]))
    {
        $this->marker[$point2] = microtime(TRUE);
    }
    return number_format($this->marker[$point2] - $this->marker[$point1], $decimals);
}
```
该方法的功能是返回两个标记间的运行时间。该方法使用[number_format](https://www.php.net/manual/zh/function.number-format)函数格式化使用时间。功能实现:
- 如果没有指定标记则返回整个程序运行的时间。
- 如果指定了标记但未在$marker数组中则返回空。
- 如果未指定第二个参数则返回第一个标记到运行结束之间的时间。

mark()、elapsed_time()方法的使用流程如下：
```text
$BM =& load_class('Benchmark', 'core');
$BM->mark('total_execution_time_start');
// 程序执行代码块···
$BM->mark('total_execution_time_end');
$used_time = $BM->elapsed_time('total_execution_time_start', 'total_execution_time_end');
```

---

#### memory_usage() ####
```text
public function memory_usage()
{
    return '{memory_usage}';
}
```
此方法用来显示占用内存。<font color="#891717">**注意**: {elapsed_time} {memory_usage}是CI中的伪变量。这些伪变量将在Output类中进行解析。</font>

---

#### 参考链接 ####

[CI框架源码解析四之基准测试类文件Benchmark.php](https://blog.csdn.net/Zhihua_W/article/details/52846274)
