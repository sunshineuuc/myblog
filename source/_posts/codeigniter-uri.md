---
title: CodeIgniter编码类文件URI.php
date: 2020-01-14 21:51:34
tags:
- php
- codeigniter
categories:
- web工作笔记
---

#### 引言 ####
URI类主要处理地址字符串，将**uri**分解成对应的片段并存到**segments**数组中。启用查询字符串则将**查询字符串**分解后存到**$_GET**数组中。**Router路由类**在之后的解析路由动作中，也主要依靠URI类的segments属性数组来获取当前上下文的请求URI信息。<font color="#891717">在CI框架中如果启用查询字符串，URI类将不做任何处理，Router类也只会匹配目录、控制器、方法。CI框架体系中的方法参数都是从URI片段中取的,并按**顺序**传递给方法参数。不支持将参数中的变量通过方法参数名传给方法，只能用$_GET获取。</font>
该类包含5个属性及22个方法，下面分别剖析。
<!-- more -->
---

#### 类属性 ####
```text
public $keyval = array();
public $uri_string = '';
public $segments = array();
public $rsegments = array();
protected $_permitted_uri_chars;
```
- `$keyval`表示
- `$uri_string`表示
- `$segments`表示
- `$rsegments`表示
- `$_permitted_uri_chars`表示URI中接受的字符，在config.php中定义:`$config['permitted_uri_chars'] = 'a-z 0-9~%.:_\-';`，为空表示允许所有字符！

---

#### 构造方法 ####
```text
public function __construct()
{
    $this->config =& load_class('Config', 'core');
    if (is_cli() OR $this->config->item('enable_query_strings') !== TRUE)
    {
        $this->_permitted_uri_chars = $this->config->item('permitted_uri_chars');
        if (is_cli())
        {
            $uri = $this->_parse_argv();
        }
        else
        {
            $protocol = $this->config->item('uri_protocol');
            empty($protocol) && $protocol = 'REQUEST_URI';
            switch ($protocol)
            {
                case 'AUTO': // For BC purposes only
                case 'REQUEST_URI':
                    $uri = $this->_parse_request_uri();
                    break;
                case 'QUERY_STRING':
                    $uri = $this->_parse_query_string();
                    break;
                case 'PATH_INFO':
                default:
                    $uri = isset($_SERVER[$protocol])
                        ? $_SERVER[$protocol]
                        : $this->_parse_request_uri();
                    break;
            }
        }
        $this->_set_uri_string($uri);
    }
    log_message('info', 'URI Class Initialized');
}
```
该方法注要是作用在运行在cli模式或未启用字符串查询的条件下。
1. 从配置文件中获取url允许的字符，即`$config['permitted_uri_chars']`，该属性在`filter_uri()`方法中用来过滤uri。
2. 如果是cli模式下则使用`_parse_argv()`方法解析命令行参数并整合为uri字符串。
3. 

##### 关于uri_protocol #####
`$config['uri_protocol']`配置不但决定以哪个函数处理URI，同时决定了从哪个全局变量里获取当前上下文的uri地址。uri_protocol可选项有 `AUTO`、`PATH_INFO`、`QUERY_STRING`、`REQUEST_URI`、`ORIG_PATH_INFO`，对应关系是：
1. `'REQUEST_URI'`使用 `$_SERVER['REQUEST_URI']`。
2. `'QUERY_STRING'`使用 `$_SERVER['QUERY_STRING']`。
3. `'PATH_INFO'`使用 `$_SERVER['PATH_INFO']`。

【注意】: **如果配置为PATH_INFO，则uri需要进行url_decode解码。**
那么这三个变量有什么区别呢？
1. `$_SERVER['REQUEST_URI']`获取的是**获取的是url地址中主机头后面所有的字符**。
2. `$_SERVER['QUERY_STRING']`获取的是**获取的url地址中"?"后面的部分**。
3. `$_SERVER['PATH_INFO']`获取的是**获取的是url地址中脚本文件($_SERVER['SCRIPT_NAME'])之后"?"之前的字符内容**。

**举例说明:**  `http://pc.local/index.php/product/pc/summary?a=1`
<b><font color="#891717">QUERY_STRING:</font></b> `a=1`
<b><font color="#891717">REQUEST_URI:</font></b> `/index.php/product/pc/summary?a=1`
<b><font color="#891717">PATH_INFO:</font></b>  `/product/pc/summary`

uri_protocol的值决定了**CI路由**和**参数**的获取方式，CI会通过这些值来判断解析到哪一个控制器，所以需要确保服务器配置了正确的值。大部分情况下设置AUTO即可，AUTO会依次检测`REQUEST_URI`、`PATH_INFO`、`QUERY_STRING`、`$_GET`的值，直到读到内容。

---

#### _set_uri_string() ####
```text
protected function _set_uri_string($str)
{
    $this->uri_string = trim(remove_invisible_characters($str, FALSE), '/');
    if ($this->uri_string !== '')
    {
        if (($suffix = (string) $this->config->item('url_suffix')) !== '')
        {
            $slen = strlen($suffix);
            if (substr($this->uri_string, -$slen) === $suffix)
            {
                $this->uri_string = substr($this->uri_string, 0, -$slen);
            }
        }
        $this->segments[0] = NULL;
        foreach (explode('/', trim($this->uri_string, '/')) as $val)
        {
            $val = trim($val);
            $this->filter_uri($val);
            if ($val !== '')
            {
                $this->segments[] = $val;
            }
        }
        unset($this->segments[0]);
    }
}
```

---

#### _parse_request_uri() ####
```text
protected function _parse_request_uri()
{
    if ( ! isset($_SERVER['REQUEST_URI'], $_SERVER['SCRIPT_NAME']))
    {
        return '';
    }
    $uri = parse_url('http://dummy'.$_SERVER['REQUEST_URI']);
    $query = isset($uri['query']) ? $uri['query'] : '';
    $uri = isset($uri['path']) ? $uri['path'] : '';
    if (isset($_SERVER['SCRIPT_NAME'][0]))
    {
        if (strpos($uri, $_SERVER['SCRIPT_NAME']) === 0)
        {
            $uri = (string) substr($uri, strlen($_SERVER['SCRIPT_NAME']));
        }
        elseif (strpos($uri, dirname($_SERVER['SCRIPT_NAME'])) === 0)
        {
            $uri = (string) substr($uri, strlen(dirname($_SERVER['SCRIPT_NAME'])));
        }
    }
    if (trim($uri, '/') === '' && strncmp($query, '/', 1) === 0)
    {
        $query = explode('?', $query, 2);
        $uri = $query[0];
        $_SERVER['QUERY_STRING'] = isset($query[1]) ? $query[1] : '';
    }
    else
    {
        $_SERVER['QUERY_STRING'] = $query;
    }
    parse_str($_SERVER['QUERY_STRING'], $_GET);
    if ($uri === '/' OR $uri === '')
    {
        return '/';
    }
    return $this->_remove_relative_directory($uri);
}
```
该方法用来解析`$_SERVER['REQUEST_URI']`并返回uri，功能实现：
1. 如果没用设置全局变量`$_SERVER['REQUEST_URI']`, `$_SERVER['SCRIPT_NAME']`则不做任何处理，直接返回。
2. 使用[parse_url](https://www.php.net/manual/zh/function.parse-url.php)解析URL(`'http://dummy'.$_SERVER['REQUEST_URI']`)之后得到一个关联数组，这里直接将数组赋值给变量$uri了。
3. 将数组中的`query`和`path`部分分别赋值给变量`$query`和`$uri`，即表示从`$_SERVER['REQUEST_URI']`取值，解析成`$uri`和`$query`两个字符串，分别存储请求的路径和get请求参数。举个栗子: path => `/pear/index.php` query => `googleguy=gooley`。
4. 去掉uri包含的`$_SERVER['SCRIPT_NAME']`，举个栗子: 比如uri是`/pear/index.php/news/view/crm`，经过处理后就变成`/news/view/crm`了
5. 对于请求服务器的具体URI包含在查询字符串这种情况，例如$uri以`?/`开头的 ，实际上if条件换种写法就是if(strncmp($uri, '?/', 2) === 0))，类似：`http://www.example.twm/index.php?/welcome/index`。其他情况直接`$_SERVER['QUERY_STRING'] = $query;` 如下面这种请求uri：`http://www.example.twm/mall/lists?page=7`。
6. 使用[parse_str()](https://www.php.net/manual/zh/function.parse-str)将查询字符串按键名存入`_GET`数组。
7. 调用`_remove_relative_directory()`方法作安全处理，移除$uri中的`../`相对路径字符和反斜杠`////`。
---

#### _parse_query_string() ####
```text
protected function _parse_query_string()
{
    $uri = isset($_SERVER['QUERY_STRING']) ? $_SERVER['QUERY_STRING'] : @getenv('QUERY_STRING');
    if (trim($uri, '/') === '')
    {
        return '';
    }
    elseif (strncmp($uri, '/', 1) === 0)
    {
        $uri = explode('?', $uri, 2);
        $_SERVER['QUERY_STRING'] = isset($uri[1]) ? $uri[1] : '';
        $uri = $uri[0];
    }
    parse_str($_SERVER['QUERY_STRING'], $_GET);
    return $this->_remove_relative_directory($uri);
}
```

---

#### _parse_argv() ####
```text
protected function _parse_argv()
{
    $args = array_slice($_SERVER['argv'], 1);
    return $args ? implode('/', $args) : '';
}
```
该方法将CLI默认下传递给脚本的参数数组整合为字符串uri并将其返回。
<font color="#891717">注意: [$_SERVER['argv']](https://www.php.net/manual/zh/reserved.variables.argv.php)第一个参数为脚本文件名，因此从第二个参数开始表示url传参。</font>

---

#### _remove_relative_directory() ####
```text
protected function _remove_relative_directory($uri)
{
    $uris = array();
    $tok = strtok($uri, '/');
    while ($tok !== FALSE)
    {
        if (( ! empty($tok) OR $tok === '0') && $tok !== '..')
        {
            $uris[] = $tok;
        }
        $tok = strtok('/');
    }
    return implode('/', $uris);
}
```

---

#### filter_uri() ####
```text
public function filter_uri(&$str)
{
    if ( ! empty($str) && ! empty($this->_permitted_uri_chars) && ! preg_match('/^['.$this->_permitted_uri_chars.']+$/i'.(UTF8_ENABLED ? 'u' : ''), $str))
    {
        show_error('The URI you submitted has disallowed characters.', 400);
    }
}
```

---

#### segment() ####
```text
public function segment($n, $no_result = NULL)
{
    return isset($this->segments[$n]) ? $this->segments[$n] : $no_result;
}
```

---

#### rsegment() ####
```text
public function rsegment($n, $no_result = NULL)
{
    return isset($this->rsegments[$n]) ? $this->rsegments[$n] : $no_result;
}
```

---

#### uri_to_assoc() ####
```text
public function uri_to_assoc($n = 3, $default = array())
{
    return $this->_uri_to_assoc($n, $default, 'segment');
}
```

---

#### ruri_to_assoc() ####
```text
public function ruri_to_assoc($n = 3, $default = array())
{
    return $this->_uri_to_assoc($n, $default, 'rsegment');
}
```

---

#### _uri_to_assoc() ####
```text
protected function _uri_to_assoc($n = 3, $default = array(), $which = 'segment')
{
    if ( ! is_numeric($n))
    {
        return $default;
    }
    if (isset($this->keyval[$which], $this->keyval[$which][$n]))
    {
        return $this->keyval[$which][$n];
    }
    $total_segments = "total_{$which}s";
    $segment_array = "{$which}_array";
    if ($this->$total_segments() < $n)
    {
        return (count($default) === 0)
            ? array()
            : array_fill_keys($default, NULL);
    }
    $segments = array_slice($this->$segment_array(), ($n - 1));
    $i = 0;
    $lastval = '';
    $retval = array();
    foreach ($segments as $seg)
    {
        if ($i % 2)
        {
            $retval[$lastval] = $seg;
        }
        else
        {
            $retval[$seg] = NULL;
            $lastval = $seg;
        }
        $i++;
    }
    if (count($default) > 0)
    {
        foreach ($default as $val)
        {
            if ( ! array_key_exists($val, $retval))
            {
                $retval[$val] = NULL;
            }
        }
    }
    isset($this->keyval[$which]) OR $this->keyval[$which] = array();
    $this->keyval[$which][$n] = $retval;
    return $retval;
}
```

---

#### assoc_to_uri() ####
```text
public function assoc_to_uri($array)
{
    $temp = array();
    foreach ((array) $array as $key => $val)
    {
        $temp[] = $key;
        $temp[] = $val;
    }
    return implode('/', $temp);
}
```

---

#### slash_segment() ####
```text
public function slash_segment($n, $where = 'trailing')
{
    return $this->_slash_segment($n, $where, 'segment');
}
```

---

#### slash_rsegment() ####
```text
public function slash_rsegment($n, $where = 'trailing')
{
    return $this->_slash_segment($n, $where, 'rsegment');
}
```

---

#### _slash_segment() ####
```text
protected function _slash_segment($n, $where = 'trailing', $which = 'segment')
{
    $leading = $trailing = '/';
    if ($where === 'trailing')
    {
        $leading	= '';
    }
    elseif ($where === 'leading')
    {
        $trailing	= '';
    }
    return $leading.$this->$which($n).$trailing;
}
```

---

#### segment_array() ####
```text
public function segment_array()
{
    return $this->segments;
}
```

---

#### rsegment_array() ####
```text
public function rsegment_array()
{
    return $this->rsegments;
}
```

---

#### total_segments() ####
```text
public function total_segments()
{
    return count($this->segments);
}
```

---

#### total_rsegments() ####
```text
public function total_rsegments()
{
    return count($this->rsegments);
}
```

---

#### uri_string() ####
```text
public function uri_string()
{
    return $this->uri_string;
}
```

---

#### ruri_string() ####
```text
public function ruri_string()
{
    return ltrim(load_class('Router', 'core')->directory, '/').implode('/', $this->rsegments);
}
```

---

#### 参考链接 #### 

[CI框架源码解析八之地址解析类文件URI.php](https://blog.csdn.net/Zhihua_W/article/details/52872407)
[CodeIgniter配置详解](https://itopic.org/codeigniter-config.html)
[CodeIgniter框架原码笔记(5)--识别多种URI风格：地址解析类URI.php](http://www.jeepxie.net/article/547745.html)
