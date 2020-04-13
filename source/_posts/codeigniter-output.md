---
title: CodeIgniter输出类Output.php
date: 2020-02-04 12:01:29
tags:
- PHP
- Codeigniter
categories:
- 开发者手册
---

#### 引言 ####

该类主要功能负责向浏览器输出最终结果，其中包括从缓存加载内容输出，根据控制器方法产生的内容输出，还包括写缓存、设置头信息、加载CI内部分析器。该类有11个成员变量和18个成员方法。下面逐个分析。

<!--more-->
---

#### 成员变量 ####
```text
public $final_output;
public $cache_expiration = 0;
public $headers = array();
public $mimes =	array();
protected $mime_type = 'text/html';
public $enable_profiler = FALSE;
protected $_zlib_oc = FALSE;
protected $_compress_output = FALSE;
protected $_profiler_sections =	array();
public $parse_exec_vars = TRUE;
protected static $func_overload;
```
$final_output表示最终输出结果字符串。
$cache_expiration表示缓存有效时间。
$headers用于存放头信息。
$mimes用于存放从配置文件中读取的mime列表。
$mime_type表示当前页面的mime类型。
$enable_profiler表示性能分析器开关。
$_zlib_oc表示Gzip压缩开关。
$_compress_output表示CI压缩开关。
$_profiler_sections表示分析器模块。
$parse_exec_vars表示分析器解析变量开关，比如解析`{elapsed_time}`、`{memory_usage}`等。
$func_overload表示启用[函数重载功能](https://www.php.net/manual/zh/mbstring.overload.php)开关。

---

#### __construct() ####
```text
public function __construct()
{
    $this->_zlib_oc = (bool) ini_get('zlib.output_compression');
    $this->_compress_output = (
        $this->_zlib_oc === FALSE
        && config_item('compress_output') === TRUE
        && extension_loaded('zlib')
    );
    isset(self::$func_overload) OR self::$func_overload = (extension_loaded('mbstring') && ini_get('mbstring.func_overload'));
    $this->mimes =& get_mimes();
    log_message('info', 'Output Class Initialized');
}
```
在构造函数中，CI通过ini_get('zlib.output_compression')获取当前php环境是否开启了GZIP压缩。如果PHP环境没有开启，那么判断配置文件中的压缩设置(compress_output=TRUE)，是不是要求框架压缩输出，如果要求的话，只要当前PHP是加载了zlib扩展的，那么就把$_compress_output标记设为TRUE。通常情况下，我们在使用过程中会开启WEB服务器的压缩功能，而关闭程序本身压缩功能。

---

#### get_output() ####
```text
public function get_output()
{
    return $this->final_output;
}
```
该方法用于获取最终输出信息。

---

#### set_output() ####
```text
public function set_output($output)
{
    $this->final_output = $output;
    return $this;
}
```
该方法用于设置$this->final_output允许你手工设置最终的输出字符串

---

#### append_output() ####
```text
public function append_output($output)
{
    $this->final_output .= $output;
    return $this;
}
```
该方法用于向输出字符串附加数据。

---

#### set_header() ####
```text
public function set_header($header, $replace = TRUE)
{
    if ($this->_zlib_oc && strncasecmp($header, 'content-length', 14) === 0)
    {
        return $this;
    }
    $this->headers[] = array($header, $replace);
    return $this;
}
```
该方法用于设置头信息，如果php开启了zlib.output_compression压缩，就跳过content-length头的设置这样做的理由是当压缩开启后，实际输出字节数比正常少，误设content-length头后，会使得客户端一直等待服务器发送足够字节的文本，造成无法正常响应。

---

#### set_content_type() ####
```text
public function set_content_type($mime_type, $charset = NULL)
{
    if (strpos($mime_type, '/') === FALSE)
    {
        $extension = ltrim($mime_type, '.');
        if (isset($this->mimes[$extension]))
        {
            $mime_type =& $this->mimes[$extension];
            if (is_array($mime_type))
            {
                $mime_type = current($mime_type);
            }
        }
    }
    $this->mime_type = $mime_type;
    if (empty($charset))
    {
        $charset = config_item('charset');
    }
    $header = 'Content-Type: '.$mime_type
        .(empty($charset) ? '' : '; charset='.$charset);

    $this->headers[] = array($header, TRUE);
    return $this;
}
```
该方法用于设置页面的 MIME 类型，可以很方便的提供 JSON 数据、JPEG、XML 等等格式,通过$charset设置文档的字符集。$mime_type是要设置MIME信息的文件扩展名，系统从$mimes数组中找出对应扩展名中的MIME信息。

---

#### get_content_type() ####
```text
public function get_content_type()
{
    for ($i = 0, $c = count($this->headers); $i < $c; $i++)
    {
        if (sscanf($this->headers[$i][0], 'Content-Type: %[^;]', $content_type) === 1)
        {
            return $content_type;
        }
    }
    return 'text/html';
}
```
该方法获取当前正在使用的 HTTP 头 Content-Type ，不包含字符集部分。从一堆header信息中匹配Content-Type信息，找到了就返回其中的MIME值，没找到，就返回默认的text/html。

---

#### get_header() ####
```text
public function get_header($header)
{
    $headers = array_merge(
        array_map('array_shift', $this->headers),
        headers_list()
    );
    if (empty($headers) OR empty($header))
    {
        return NULL;
    }
    for ($c = count($headers) - 1; $c > -1; $c--)
    {
        if (strncasecmp($header, $headers[$c], $l = self::strlen($header)) === 0)
        {
            return trim(self::substr($headers[$c], $l+1));
        }
    }
    return NULL;
}
```
该方法返回请求的 HTTP 头，如果 HTTP 头还没设置，返回 NULL。

---

#### set_status_header() ####
```text
public function set_status_header($code = 200, $text = '')
{
    set_status_header($code, $text);
    return $this;
}
```
该方法设置头信息状态。

---

#### enable_profiler() ####
```text
public function enable_profiler($val = TRUE)
{
    $this->enable_profiler = is_bool($val) ? $val : TRUE;
    return $this;
}
```
该方法用于设置禁用或开启分析器。

---

#### set_profiler_sections() ####
```text
public function set_profiler_sections($sections)
{
    if (isset($sections['query_toggle_count']))
    {
        $this->_profiler_sections['query_toggle_count'] = (int) $sections['query_toggle_count'];
        unset($sections['query_toggle_count']);
    }
    foreach ($sections as $section => $enable)
    {
        $this->_profiler_sections[$section] = ($enable !== FALSE);
    }
    return $this;
}
```
该方法用于设置分析器的内容，该类允许你启用或禁用程序分析器，它可以在你的页面底部显示，基准测试的结果或其他一些数据帮助你调试和优化程序。

---

#### cache() ####
```text
public function cache($time)
{
    $this->cache_expiration = is_numeric($time) ? $time : 0;
    return $this;
}
```
该方法用于设置缓存时长，开启文件缓存。

---

#### _display() ####
```text
public function _display($output = '')
{
    $BM =& load_class('Benchmark', 'core');
    $CFG =& load_class('Config', 'core');
    if (class_exists('CI_Controller', FALSE))
    {
        $CI =& get_instance();
    }
    if ($output === '')
    {
        $output =& $this->final_output;
    }
    if ($this->cache_expiration > 0 && isset($CI) && ! method_exists($CI, '_output'))
    {
        $this->_write_cache($output);
    }
    $elapsed = $BM->elapsed_time('total_execution_time_start', 'total_execution_time_end');
    if ($this->parse_exec_vars === TRUE)
    {
        $memory	= round(memory_get_usage() / 1024 / 1024, 2).'MB';
        $output = str_replace(array('{elapsed_time}', '{memory_usage}'), array($elapsed, $memory), $output);
    }
    if (isset($CI) // This means that we're not serving a cache file, if we were, it would already be compressed
        && $this->_compress_output === TRUE
        && isset($_SERVER['HTTP_ACCEPT_ENCODING']) && strpos($_SERVER['HTTP_ACCEPT_ENCODING'], 'gzip') !== FALSE)
    {
        ob_start('ob_gzhandler');
    }
    if (count($this->headers) > 0)
    {
        foreach ($this->headers as $header)
        {
            @header($header[0], $header[1]);
        }
    }
    if ( ! isset($CI))
    {
        if ($this->_compress_output === TRUE)
        {
            if (isset($_SERVER['HTTP_ACCEPT_ENCODING']) && strpos($_SERVER['HTTP_ACCEPT_ENCODING'], 'gzip') !== FALSE)
            {
                header('Content-Encoding: gzip');
                header('Content-Length: '.self::strlen($output));
            }
            else
            {
                $output = gzinflate(self::substr($output, 10, -8));
            }
        }
        echo $output;
        log_message('info', 'Final output sent to browser');
        log_message('debug', 'Total execution time: '.$elapsed);
        return;
    }
    if ($this->enable_profiler === TRUE)
    {
        $CI->load->library('profiler');
        if ( ! empty($this->_profiler_sections))
        {
            $CI->profiler->set_sections($this->_profiler_sections);
        }
        $output = preg_replace('|</body>.*?</html>|is', '', $output, -1, $count).$CI->profiler->run();
        if ($count > 0)
        {
            $output .= '</body></html>';
        }
    }
    if (method_exists($CI, '_output'))
    {
        $CI->_output($output);
    }
    else
    {
        echo $output; // Send it to the browser!
    }
    log_message('info', 'Final output sent to browser');
    log_message('debug', 'Total execution time: '.$elapsed);
}
```
该方法的功能主要是将最终结果输出到浏览器。功能实现：
1. 获取$BM、$CFG，注意这里使用的是load_class()而不直接用$CI =& get_instance()，因为有时候本方法是被缓存机制调用的，这时候$CI超级对象还无法使用。
2. 当然如果可能的话，获取超级对象$CI。
3. 获取需要最终输出的字符串$output。当$CI对象存在时证明我们不是在从缓存输出数据，这时如果Controller没有自定义_output方法就需要写缓存(调`_write_cache方法`)。
4. 如果分析器解析变量是开着的则替换系统的总体运行时间和内存消耗。
5. 如果满足条件（$CI对象存在、支持压缩输出、本地服务器支持`gzip`编码）则打开输出缓冲。当输出缓冲激活后，脚本将不会输出内容（除http标头外），相反需要输出的内容被存储在内部缓冲区中。`ob_gzhandler()`目的是用在ob_start()中作回调函数，以方便将gz编码的数据发送到支持压缩页面的浏览器。在ob_gzhandler()真正发送压缩过的数据之前，该 函数会确定（判定）浏览器可以接受哪种类型内容编码（"gzip","deflate",或者根本什么都不支持），然后 返回相应的输出。 所有可以发送正确头信息表明他自己可以接受压缩的网页的浏览器，都可以支持。
6. 如果存放头信息的数组`headers`不为空则设置头信息。
7. 如果没有超级控制器，可以证明当前是在处理一个缓存的输出。输出缓存内容并结束本函数。
8. 如果开启了分析器模块，会生成一些报告到页面尾部用于辅助我们调试。这里使用Profile显示所有基准点的时间消耗，同时还会显示出提交的数据和数据库查询的信息。

---

#### _write_cache() ####
```text
public function _write_cache($output)
{
    $CI =& get_instance();
    $path = $CI->config->item('cache_path');
    $cache_path = ($path === '') ? APPPATH.'cache/' : $path;
    if ( ! is_dir($cache_path) OR ! is_really_writable($cache_path))
    {
        log_message('error', 'Unable to write cache file: '.$cache_path);
        return;
    }
    $uri = $CI->config->item('base_url')
        .$CI->config->item('index_page')
        .$CI->uri->uri_string();

    if (($cache_query_string = $CI->config->item('cache_query_string')) && ! empty($_SERVER['QUERY_STRING']))
    {
        if (is_array($cache_query_string))
        {
            $uri .= '?'.http_build_query(array_intersect_key($_GET, array_flip($cache_query_string)));
        }
        else
        {
            $uri .= '?'.$_SERVER['QUERY_STRING'];
        }
    }
    $cache_path .= md5($uri);
    if ( ! $fp = @fopen($cache_path, 'w+b'))
    {
        log_message('error', 'Unable to write cache file: '.$cache_path);
        return;
    }
    if ( ! flock($fp, LOCK_EX))
    {
        log_message('error', 'Unable to secure a file lock for file at: '.$cache_path);
        fclose($fp);
        return;
    }
    if ($this->_compress_output === TRUE)
    {
        $output = gzencode($output);

        if ($this->get_header('content-type') === NULL)
        {
            $this->set_content_type($this->mime_type);
        }
    }
    $expire = time() + ($this->cache_expiration * 60);
    $cache_info = serialize(array(
        'expire'	=> $expire,
        'headers'	=> $this->headers
    ));
    $output = $cache_info.'ENDCI--->'.$output;
    for ($written = 0, $length = self::strlen($output); $written < $length; $written += $result)
    {
        if (($result = fwrite($fp, self::substr($output, $written))) === FALSE)
        {
            break;
        }
    }
    flock($fp, LOCK_UN);
    fclose($fp);
    if ( ! is_int($result))
    {
        @unlink($cache_path);
        log_message('error', 'Unable to write the complete cache content at: '.$cache_path);
        return;
    }
    chmod($cache_path, 0640);
    log_message('debug', 'Cache file written: '.$cache_path);
    $this->set_cache_header($_SERVER['REQUEST_TIME'], $expire);
}
```
该方法主要用于将缓存信息写入缓存文件。功能实现：
1. 获取缓存路径$cache_path并判断如果不是目录或不可写则返回。
2. 构造$uri，并对$uri进行md5加密，然后放到$cache_path后面作为缓存文件的完整路径。
3. 判断缓存文件完整路径$cache_path是否可写，不可写或无法上锁则返回。
4. 根据支持条件将输出内容进行压缩，这里用到了[gzencode](https://www.php.net/manual/zh/function.gzencode.php)，设置内容类型mime_type头信息。
5. 将$cache_info[序列化](https://www.php.net/manual/zh/function.serialize.php)，构造成`$cache_info.'ENDCI--->'.$output`的格式写入到缓存文件中，写入时将文件上锁，写入失败则删除该文件。
6. 设置缓存文件权限`0640`， 发送HTTP缓存控制头到浏览器以匹配文件缓存设置。

---

#### _display_cache() ####
```text
public function _display_cache(&$CFG, &$URI)
{
    $cache_path = ($CFG->item('cache_path') === '') ? APPPATH.'cache/' : $CFG->item('cache_path');
    $uri = $CFG->item('base_url').$CFG->item('index_page').$URI->uri_string;
    if (($cache_query_string = $CFG->item('cache_query_string')) && ! empty($_SERVER['QUERY_STRING']))
    {
        if (is_array($cache_query_string))
        {
            $uri .= '?'.http_build_query(array_intersect_key($_GET, array_flip($cache_query_string)));
        }
        else
        {
            $uri .= '?'.$_SERVER['QUERY_STRING'];
        }
    }
    $filepath = $cache_path.md5($uri);
    if ( ! file_exists($filepath) OR ! $fp = @fopen($filepath, 'rb'))
    {
        return FALSE;
    }
    flock($fp, LOCK_SH);
    $cache = (filesize($filepath) > 0) ? fread($fp, filesize($filepath)) : '';
    flock($fp, LOCK_UN);
    fclose($fp);
    if ( ! preg_match('/^(.*)ENDCI--->/', $cache, $match))
    {
        return FALSE;
    }
    $cache_info = unserialize($match[1]);
    $expire = $cache_info['expire'];
    $last_modified = filemtime($filepath);
    if ($_SERVER['REQUEST_TIME'] >= $expire && is_really_writable($cache_path))
    {
        @unlink($filepath);
        log_message('debug', 'Cache file has expired. File deleted.');
        return FALSE;
    }
    $this->set_cache_header($last_modified, $expire);
    foreach ($cache_info['headers'] as $header)
    {
        $this->set_header($header[0], $header[1]);
    }
    $this->_display(self::substr($cache, self::strlen($match[0])));
    log_message('debug', 'Cache file is current. Sending it to browser.');
    return TRUE;
}
```
该方法在CodeIgniter.php里面有调用，用来负责缓存的输出，如果在CodeIgniter.php中调用此方法有输出，则本次请求的运行将直接结束，直接以缓存输出作为响应。功能实现：
1. 获取保存缓存的路径`$cache_path`，如`G:\wamp\www\CodeIgniter_hmvc\application\cache/449a65bd3d6bad1ee34104f01d27cc26`。
2. 构造`$uri`并进行md5加密，附加在`$cache_path`后面作为缓存文件的完整路径`$filepath`。
3. 如果`$filepath`不存在或读取失败则返回false。否则读取缓存信息到`$cache`，读取期间[flock](https://www.php.net/manual/zh/function.flock.php)上锁。
4. 这个地方可参考_write_cache()方法中构造缓存的部分：`$output = $cache_info.'ENDCI--->'.$output;`。 <font color="#891717">下面这个ENDCI--->字样，只是因为CI的缓存文件里面的内容是规定以cache_info['expire', 'headers']＋ENDCI--->开头而已。</font>如果不符合此结构，可视为非CI的缓存文件，或者文件已损坏，获取缓存内容失败，返回FALSE。$match[0]是除页面内容之外的附加信息:`a:2:{s:6:"expire";i:1566534312;s:7:"headers";a:0:{}}ENDCI--->`，$match[1]是附加信息中和时间有关的信息:`a:2:{s:6:"expire";i:1566534312;s:7:"headers";a:0:{}}`缓存文件开头: `a:2:{s:6:"expire";i:1566534312;s:7:"headers";a:0:{}}ENDCI---><!DOCTYPE html>`。
5. 获取$cache_info，这里用到了[unserialize](https://www.php.net/manual/zh/function.unserialize.php)。可以通过[php在线反序列化工具](https://www.w3cschool.cn/tools/index?name=unserialize)在线反序列化试下，然后拿到`$expire`。
6. 使用[filemtime](https://www.php.net/manual/zh/function.filemtime.php)取得文件修改时间`$last_modified`。判断缓存是否过期，如果过期并且可写则删除，然后返回false。
7. 设置缓存头信息，调用`_display()`方法输出缓冲信息。

---

#### delete_cache() ####
```text
public function delete_cache($uri = '')
{
    $CI =& get_instance();
    $cache_path = $CI->config->item('cache_path');
    if ($cache_path === '')
    {
        $cache_path = APPPATH.'cache/';
    }
    if ( ! is_dir($cache_path))
    {
        log_message('error', 'Unable to find cache path: '.$cache_path);
        return FALSE;
    }
    if (empty($uri))
    {
        $uri = $CI->uri->uri_string();
        if (($cache_query_string = $CI->config->item('cache_query_string')) && ! empty($_SERVER['QUERY_STRING']))
        {
            if (is_array($cache_query_string))
            {
                $uri .= '?'.http_build_query(array_intersect_key($_GET, array_flip($cache_query_string)));
            }
            else
            {
                $uri .= '?'.$_SERVER['QUERY_STRING'];
            }
        }
    }
    $cache_path .= md5($CI->config->item('base_url').$CI->config->item('index_page').ltrim($uri, '/'));
    if ( ! @unlink($cache_path))
    {
        log_message('error', 'Unable to delete cache file for '.$uri);
        return FALSE;
    }
    return TRUE;
}
```
该方法提供删除缓存的功能，前提是已经有缓存了，否则会报错。功能实现：
1. 从配置文件中读取缓存路径，为空则默认为`APPPATH . cache/`。
2. 检查缓存目录是否存在，不存在则报错退出。
3. 构造缓存文件，然后删除。这里有三个php函数[array_intersect_key](https://www.php.net/manual/zh/function.array-intersect-key.php)、[array_flip](https://www.php.net/manual/zh/function.array-flip.php)、[http_build_query](https://www.php.net/manual/zh/function.http-build-query.php)。

---

#### set_cache_header() ####
```text
public function set_cache_header($last_modified, $expiration)
{
    $max_age = $expiration - $_SERVER['REQUEST_TIME'];
    if (isset($_SERVER['HTTP_IF_MODIFIED_SINCE']) && $last_modified <= strtotime($_SERVER['HTTP_IF_MODIFIED_SINCE']))
    {
        $this->set_status_header(304);
        exit;
    }
    header('Pragma: public');
    header('Cache-Control: max-age='.$max_age.', public');
    header('Expires: '.gmdate('D, d M Y H:i:s', $expiration).' GMT');
    header('Last-modified: '.gmdate('D, d M Y H:i:s', $last_modified).' GMT');
}
```
该方法用于设置缓存头信息。功能实现：
1. [HTTP_IF_MODIFIED_SINCE](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/If-Modified-Since)表示浏览器缓存页面的最后修改时间，如果设置了HTTP_IF_MODIFIED_SINCE头，且文件最后修改时间没有超过HTTP_IF_MODIFIED_SINCE时间，则直接发304状态码给客户端，让客户端调用本地缓存。
2. 如果文件修改时间超过了HTTP_IF_MODIFIED_SINCE时间，就重新发送头信息，告诉客户端缓存该次请求的结果到本地。下面是[Pragma](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/Pragma)、[Cache-Control](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/Pragma)、[Expires](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/Expires)、[Last-modified](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/Last-Modified)的相关说明。

---

#### strlen() ####
```text
protected static function strlen($str)
{
    return (self::$func_overload)
        ? mb_strlen($str, '8bit')
        : strlen($str);
}
```
该方法用于多字节安全处理，功能是获取字符串长度。如果启用了函数重载功能，则返回utf-8编码的字符串长度，详见[mb_strlen](https://www.php.net/manual/zh/function.mb-strlen.php)。举个例子，`$str='武汉加油';`，如果使用`strlen`计算时$str长度为4 x 3 = 12，如果使用的是`mb_strlen($str, '8bit')`则长度为4，因为这里会将中文字符当作1来计算而不是3。关于更多多字符的信息可参考[阮先生]的文章[字符编码笔记：ASCII，Unicode 和 UTF-8](http://www.ruanyifeng.com/blog/2007/10/ascii_unicode_and_utf-8.html)。

---

#### substr() ####
```text
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
该方法用于多字节安全处理，功能是截取字符串，如果开启函数重载功能，则需要先reset长度，然后使用[mb_substr](https://www.php.net/manual/zh/function.mb-substr.php)；否则使用[substr](https://www.php.net/manual/zh/function.substr.php)。

---

#### 参考链接 ####
[CI框架源码解析十之输出类文件Output.php](https://blog.csdn.net/Zhihua_W/article/details/52931581)
