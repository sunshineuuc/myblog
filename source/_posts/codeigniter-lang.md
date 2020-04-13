---
title: CodeIgniter语言类文件Lang.php
date: 2020-02-10 19:45:39
tags:
- PHP
- Codeigniter
categories:
- 开发者手册
---

#### 引言 ####
语言类提供了一些方法用于获取语言文件和不同语言的文本来实现国际化。该类包含两个成员变量`language`、`is_loaded`和三个成员方法`__construct()`、`load()`、`line()`。
<!--more-->
---

#### 成员方法 ####
```text
public $language = array();// 语言列表
public $is_loaded = array();// 加载的语言文件列表
```

#### __construct() ####
```text
public function __construct()
{
    log_message('info', 'Language Class Initialized');
}
```
---

#### load() ####
```text
public function load($langfile, $idiom = '', $return = FALSE, $add_suffix = TRUE, $alt_path = '')
{
    /**
     * 加载语言包
     * $LANG = & load_class('Lang', 'core');
     * $LANG->load('test'); 英文
     * // $LANG->load('test', 'zh_cn'); 中文
     * var_dump($LANG->line('test.successful'));
     */
    if (is_array($langfile)) // 支持按组加载，即 $this->lang->load(['test', 'welcome']);
    {
        foreach ($langfile as $value)
        {
            $this->load($value, $idiom, $return, $add_suffix, $alt_path);
        }

        return;
    }

    // 去除.php，即$this->lang->load('test.php')跟$this->lang->load('test')效果一样
    $langfile = str_replace('.php', '', $langfile);

    if ($add_suffix === TRUE)
    {
        // preg_replace()的作用是去除_lang字符串，即$this->lang->load('test_lang')跟$this->lang->load('test')效果一样
        $langfile = preg_replace('/_lang$/', '', $langfile).'_lang';
    }

    // 至此$langfile = test_lang.php
    $langfile .= '.php';

    if (empty($idiom) OR ! preg_match('/^[a-z_-]+$/i', $idiom))
    {
        // 若没有指定$idiom, 则首先使用配置文件中指定的语言类型，如果没有配置则使用english
        $config =& get_config();
        $idiom = empty($config['language']) ? 'english' : $config['language'];
    }

    // 已加载则返回，避免重复加载
    if ($return === FALSE && isset($this->is_loaded[$langfile]) && $this->is_loaded[$langfile] === $idiom)
    {
        return;
    }

    // Load the base file, so any others found can override it
    $basepath = BASEPATH.'language/'.$idiom.'/'.$langfile;
    //  $basepath = 'G:\wamp\www\CodeIgniter_hmvc\system\language/zh_cn/test_lang.php'
    if (($found = file_exists($basepath)) === TRUE)
    {
        include($basepath);
    }

    // Do we have an alternative path to look in?
    // $alt_path 默认为''，是个目录，也就是说要加载的语言文件可能在这个目录下
    if ($alt_path !== '')
    {
        $alt_path .= 'language/'.$idiom.'/'.$langfile;
        if (file_exists($alt_path))
        {
            include($alt_path);
            $found = TRUE;
        }
    }
    else
    {
        /**
         * var_dump(get_instance()->load->get_package_paths(TRUE)) = [
         *      0 => string 'G:\wamp\www\CodeIgniter_hmvc\application\' (length=41)
         *      1 => string 'G:\wamp\www\CodeIgniter_hmvc\system\' (length=36)
         * ]
         */
        foreach (get_instance()->load->get_package_paths(TRUE) as $package_path)
        {
            $package_path .= 'language/'.$idiom.'/'.$langfile;
            // $package_path = 'G:\wamp\www\CodeIgniter_hmvc\application\language/zh_cn/test_lang.php'
            if ($basepath !== $package_path && file_exists($package_path))
            {
                include($package_path);
                $found = TRUE;
                break;
            }
        }
    }

    if ($found !== TRUE)
    {
        show_error('Unable to load the requested language file: language/'.$idiom.'/'.$langfile);
    }

    // 语言文件内容：$lang['test_failed'] = '测试成功';
    if ( ! isset($lang) OR ! is_array($lang))
    {
        log_message('error', 'Language file contains no data: language/'.$idiom.'/'.$langfile);

        if ($return === TRUE)
        {
            return array();
        }
        return;
    }

    // $return 默认为false， 如果为true直接返回
    if ($return === TRUE)
    {
        return $lang;
    }

    /**
     *  var_dump($this->is_loaded) = [
     *       'test_lang.php' => string 'zh_cn' (length=5)
     * ]
     */
    $this->is_loaded[$langfile] = $idiom;
    /**
     * var_dump($this->language) = [
     *        'test.successful' => string '测试成功' (length=12)
     *        'test_failed' => string '测试失败' (length=12)
     * ]
     */
    $this->language = array_merge($this->language, $lang);

    log_message('info', 'Language file loaded: language/'.$idiom.'/'.$langfile);
    return TRUE;
}
```
加载语言文件。

---

#### line() ####
```text
public function line($line, $log_errors = TRUE)
{
    // $line = string 'test.successful' (length=15) 找到返回$value找不到返回false
    $value = isset($this->language[$line]) ? $this->language[$line] : FALSE;

    // Because killer robots like unicorns!
    if ($value === FALSE && $log_errors === TRUE)
    {
        log_message('error', 'Could not find the language line "'.$line.'"');
    }

    return $value;
}
```
从一个已加载的语言文件中，通过行名获取一行该语言的文本。

---

#### 参考链接 ####
[CI框架源码解析十三之语言类文件Lang.php](https://blog.csdn.net/Zhihua_W/article/details/52945358)
