---
title: CodeIgniter配置类文件Config.php
date: 2019-12-31 18:40:47
tags:
- php
- codeigniter
categories:
- web工作笔记
---

#### 引言 ####
CodeIgniter的配置类有跟配置相关的属性和方法，比如:load()方法、item()方法等等。application/config目录下有好多配置文件，这些文件通过手工加载时会用到`load()`方法；当加载完某个配置文件后，可以通过`item()`方法获取某个配置项，当然也可以通过`set_item()`设置配置项。配置类主要完成下面几个功能:
- 加载配置文件。
- 获取配置项。
- 设置配置项。
- 一些url辅助函数的函数原型。

下面对配置类进行详细分析。
<!-- more -->
---

#### 相关属性 ####
```text
public $config = array();
public $is_loaded =	array();
public $_config_paths =	array(APPPATH);
```
- $config: [官网](https://codeigniter.org.cn/user_guide/libraries/config.html)的解释为 所有已加载的配置项组成的数组。
- $is_loaded: 所有已加载的配置文件组成的数组。
- $_config_paths: 默认时一个数组`array(APPPATH)`，当自动加载package时会将package的路径放入该数组中。
---

#### 构造方法 ####
```text
public function __construct()
{
    $this->config =& get_config();
    if (empty($this->config['base_url']))
    {
        if (isset($_SERVER['SERVER_ADDR']))
        {
            if (strpos($_SERVER['SERVER_ADDR'], ':') !== FALSE)
            {
                $server_addr = '['.$_SERVER['SERVER_ADDR'].']';
            }
            else
            {
                $server_addr = $_SERVER['SERVER_ADDR'];
            }
            $base_url = (is_https() ? 'https' : 'http').'://'.$server_addr
                .substr($_SERVER['SCRIPT_NAME'], 0, strpos($_SERVER['SCRIPT_NAME'], basename($_SERVER['SCRIPT_FILENAME'])));
        }
        else
        {
            $base_url = 'http://localhost/';
        }
        $this->set_item('base_url', $base_url);
    }
    log_message('info', 'Config Class Initialized');
}
```
该方法的功能实现:
1. 由[全局函数库文件](https://pureven.cc/2019/12/23/codeigniter-common/)可知`get_config()`函数返回的是config文件中$config的引用。这里在Config组件实例化时，要将所有的配置存放到属性$config中，便于之后的访问和处理。
2. 如果配置文件中`base_url`设置为空，即`$config['base_url'] = '';`，这时该方法会根据服务器和执行环境信息来设置此配置项，不满足条件时设置为`http://localhost/`。

---

#### load() ####
```text
public function load($file = '', $use_sections = FALSE, $fail_gracefully = FALSE)
{
    $file = ($file === '') ? 'config' : str_replace('.php', '', $file);
    $loaded = FALSE;
    foreach ($this->_config_paths as $path)
    {
        foreach (array($file, ENVIRONMENT.DIRECTORY_SEPARATOR.$file) as $location)
        {
            $file_path = $path.'config/'.$location.'.php';
            if (in_array($file_path, $this->is_loaded, TRUE))
            {
                return TRUE;
            }
            if ( ! file_exists($file_path))
            {
                continue;
            }
            include($file_path);
            if ( ! isset($config) OR ! is_array($config))
            {
                if ($fail_gracefully === TRUE)
                {
                    return FALSE;
                }
                show_error('Your '.$file_path.' file does not appear to contain a valid configuration array.');
            }
            if ($use_sections === TRUE)
            {
                $this->config[$file] = isset($this->config[$file])
                    ? array_merge($this->config[$file], $config)
                    : $config;
            }
            else
            {
                $this->config = array_merge($this->config, $config);
            }
            $this->is_loaded[] = $file_path;
            $config = NULL;
            $loaded = TRUE;
            log_message('debug', 'Config file loaded: '.$file_path);
        }
    }
    if ($loaded === TRUE)
    {
        return TRUE;
    }
    elseif ($fail_gracefully === TRUE)
    {
        return FALSE;
    }
    show_error('The configuration file '.$file.'.php does not exist.');
}
```
该方法的功能是**include**默认或指定的配置文件并将完整路径放入`is_loaded`。功能实现:
1. 明确要加载的配置文件名，如果没有指定则为`config`。这里需要去掉`.php`扩展名。
2. 定义局部变量`$loaded`为FALSE。
3. 遍历数组`_config_paths`来判断要加载的文件是否存在，不存在则第三个参数`$fail_gracefully`为true的情况下返回false，否则**报错**。这里需要加载的文件也可能为对应当前运行环境的配置文件，即`ENVIRONMENT.DIRECTORY_SEPARATOR.$file`，因此也是要遍历来判断的。
4. 如果配置文件存在则加载，加载后发现$config遍历不为数组则报错返回，若为数组继续。
5. 第二个参数`$use_sections`如果为true会对该配置文件启用独立的key存储，并且对于相同键名的项用新加载的覆盖主配置文件中的，<font color="#891717"><b>注意</b>:这里赋值时指定了文件名`$this->config[$file]`</font>。然后将文件路径赋值给数组`is_loaded`便于加载文件的追踪。

---

#### item() ####
```text
public function item($item, $index = '')
{
    if ($index == '')
    {
        return isset($this->config[$item]) ? $this->config[$item] : NULL;
    }
    return isset($this->config[$index], $this->config[$index][$item]) ? $this->config[$index][$item] : NULL;
}
```
该方法用于获取某个配置项。第二个参数`$index`表示使用`load()`方法加载文件时`$use_sections`参数为true，写入config数组用文件名当作key了。因此当$index不为空时表示获取的是`$this->config[$index][$item]`。

---

#### slash_item() ####
```text
public function slash_item($item)
{
    if ( ! isset($this->config[$item]))
    {
        return NULL;
    }
    elseif (trim($this->config[$item]) === '')
    {
        return '';
    }
    return rtrim($this->config[$item], '/').'/';
}
```
该方法值判断主配置文件中项，并在配置项最后加上反斜杠，通常用于base_url和index_page这两个配置项的处理。

---

#### site_url() ####
```text
public function site_url($uri = '', $protocol = NULL)
{
    $base_url = $this->slash_item('base_url');
    if (isset($protocol))
    {
        if ($protocol === '')
        {
            $base_url = substr($base_url, strpos($base_url, '//'));
        }
        else
        {
            $base_url = $protocol.substr($base_url, strpos($base_url, '://'));
        }
    }
    if (empty($uri))
    {
        return $base_url.$this->item('index_page');
    }
    $uri = $this->_uri_string($uri);
    if ($this->item('enable_query_strings') === FALSE)
    {
        $suffix = isset($this->config['url_suffix']) ? $this->config['url_suffix'] : '';
        if ($suffix !== '')
        {
            if (($offset = strpos($uri, '?')) !== FALSE)
            {
                $uri = substr($uri, 0, $offset).$suffix.substr($uri, $offset);
            }
            else
            {
                $uri .= $suffix;
            }
        }
        return $base_url.$this->slash_item('index_page').$uri;
    }
    elseif (strpos($uri, '?') === FALSE)
    {
        $uri = '?'.$uri;
    }
    return $base_url.$this->item('index_page').$uri;
}
```
官网给出的解释是: 根据配置文件返回你的站点 URL 。index.php （获取其他你在配置文件中设置的 index_page 参数） 将会包含在你的 URL 中，另外再加上你传给函数的 URI 参数，以及配置文件中设置的 url_suffix 参数。<font color="#891717">推荐在任何时候都使用这种方法来生成你的 URL ，这样在你的 URL 变动时你的代码将具有可移植性。</font>
通常通过[URL辅助函数](https://codeigniter.org.cn/user_guide/helpers/url_helper.html)中函数`site_url()`来访问。
```text
function site_url($uri = '', $protocol = NULL)
{
    return get_instance()->config->site_url($uri, $protocol);
}
```
功能实现:
1. 

---

#### base_url() ####

---

#### _uri_string() ####

---

#### system_url() ####

---

#### set_item() ####
```text
public function set_item($item, $value)
{
    $this->config[$item] = $value;
}
```
该方法用于手动设置配置项，如果配置项已存在则将其覆盖。

---

#### 参考链接 ####
[CI框架源码解析六之配置类文件Config.php](https://blog.csdn.net/Zhihua_W/article/details/52859824)
---
