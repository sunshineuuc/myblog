---
title: CodeIgniter输入类文件Input.php
date: 2020-02-09 09:57:53
tags:
- PHP
- Codeigniter
categories:
- 开发者手册
---

#### 引言 ####
输入类通过对输入数据进行预处理来提高安全性，同时提供了一些辅助方法来获取输入数据。该类包含10个成员变量和22个成员方法。
<!--more-->
---

#### 成员变量 ####
```text
/*当前用户ip地址*/
protected $ip_address = FALSE;

/*是否允许获取$_GET超级全局变量*/
protected $_allow_get_array = TRUE;

/*是否标准化换行符*/
protected $_standardize_newlines;

/*是否开启全局xss过滤*/
protected $_enable_xss = FALSE;

/*是否开启CSRF过滤*/
protected $_enable_csrf = FALSE;

/*记录HTTP Request信息*/
protected $headers = array();

/*原始输入流数据*/
protected $_raw_input_stream;

/*解析的输入流数据*/
protected $_input_stream;

/*安全类实例*/
protected $security;

/*utf8类实例*/
protected $uni;
```

---

#### __construct() ####
```text
public function __construct()
{
    // 表示是否允许用户使用$_GET全局变量，如果设置为不允许将$_GET清空。
    $this->_allow_get_array = (config_item('allow_get_array') !== FALSE);

    // $config['global_xss_filtering']表示是否开启XSS全局防御的标志位，如果设置为允许，则会对用户输入和Cookie的内容中进行XSS过滤。
    $this->_enable_xss = (config_item('global_xss_filtering') === TRUE);

    // $config['csrf_protection']表示是否开启CSRF防御，如果设置为允许，则会在对表单数据进行处理时进行CSRF方法的检查。
    $this->_enable_csrf = (config_item('csrf_protection') === TRUE);

    // $config['standardize_newlines']表示是否标准化换行符，如果设置为允许，则会在对表单数据进行处理时用PHP_EOL代替数据中的换行符。
    $this->_standardize_newlines = (bool) config_item('standardize_newlines');

    $this->security =& load_class('Security', 'core');

    // Do we need the UTF-8 class?
    if (UTF8_ENABLED === TRUE)
    {
        $this->uni =& load_class('Utf8', 'core');
    }

    // Sanitize global arrays 清理全局数组，即处理表单数据,$_GET,$_POST,$_COOKIE去掉不合要求的字符
    $this->_sanitize_globals();

    // CSRF Protection check
    if ($this->_enable_csrf === TRUE && ! is_cli())
    {
        $this->security->csrf_verify();
    }

    log_message('info', 'Input Class Initialized');
}
```

---

#### _fetch_from_array() ####
```text
protected function _fetch_from_array(&$array, $index = NULL, $xss_clean = NULL)
{
    is_bool($xss_clean) OR $xss_clean = $this->_enable_xss;

    // $index = NULL 表示获取所有, 比如$this->input->get()表示获取所有$_GET参数
    isset($index) OR $index = array_keys($array);

    // 如果Index是数组则递归调用该方法过滤，比如$this->input->get(['a', 'b'])获取的是$_GET['a']、$_GET['b']
    if (is_array($index))
    {
        $output = array();
        foreach ($index as $key)
        {
            $output[$key] = $this->_fetch_from_array($array, $key, $xss_clean);
        }

        return $output;
    }

    if (isset($array[$index]))
    {
        $value = $array[$index];
    }
    elseif (($count = preg_match_all('/(?:^[^\[]+)|\[[^]]*\]/', $index, $matches)) > 1) // 索引是否包含数组符号，比如$this->input->get([])
    {
        $value = $array;
        for ($i = 0; $i < $count; $i++)
        {
            $key = trim($matches[0][$i], '[]');
            if ($key === '') // 如果索引是[]则返回的是个数组，即$array,这里跟参数为null是一样的，只不过这里直接返回不用递归处理了
            {
                break;
            }

            if (isset($value[$key]))
            {
                $value = $value[$key];
            }
            else
            {
                return NULL;
            }
        }
    }
    else
    {
        return NULL;
    }

    return ($xss_clean === TRUE)
        ? $this->security->xss_clean($value)
        : $value;
}
```
该方法的功能为从数组中获取某个值并设置是否进行xss过滤。代码中的`?:`表示非捕获数组，作用可参考[https://blog.csdn.net/Raynaing/article/details/79140018](https://blog.csdn.net/Raynaing/article/details/79140018)。

---

#### get() ####
```text
public function get($index = NULL, $xss_clean = NULL)
{
    return $this->_fetch_from_array($_GET, $index, $xss_clean);
}
```
该方法用于获取$_GET值，并可进行xss过滤。

---

#### post() ####
```text
public function post($index = NULL, $xss_clean = NULL)
{
    return $this->_fetch_from_array($_POST, $index, $xss_clean);
}
```
该方法用于获取$_POST值，并可进行xss过滤。

---

#### post_get() ####
```text
public function post_get($index, $xss_clean = NULL)
{
    return isset($_POST[$index])
        ? $this->post($index, $xss_clean)
        : $this->get($index, $xss_clean);
}
```
该方法用于$_POST值或$_GET值，从$_POST中获取，如果获取到了直接返回；如果没有获取到再从$_GET中获取。

---

#### get_post() ####
```text
public function get_post($index, $xss_clean = NULL)
{
    return isset($_GET[$index])
        ? $this->get($index, $xss_clean)
        : $this->post($index, $xss_clean);
}
```
该方法和 post_get() 方法一样，只是它先查找 GET 数据。

---

#### cookie() ####
```text
public function cookie($index = NULL, $xss_clean = NULL)
{
    return $this->_fetch_from_array($_COOKIE, $index, $xss_clean);
}
```
该方法和 post() 和 get() 方法一样，只是它用于获取 COOKIE 数据。

---

#### server() ####
```text
public function server($index, $xss_clean = NULL)
{
    return $this->_fetch_from_array($_SERVER, $index, $xss_clean);
}
```
该方法和 post() 、 get() 和 cookie() 方法一样，只是它用于获取 SERVER 数据。

---

#### input_stream() ####
```text
public function input_stream($index = NULL, $xss_clean = NULL)
{
    // Prior to PHP 5.6, the input stream can only be read once,
    // so we'll need to check if we have already done that first.
    if ( ! is_array($this->_input_stream))
    {
        // $this->raw_input_stream will trigger __get().
        parse_str($this->raw_input_stream, $this->_input_stream);
        is_array($this->_input_stream) OR $this->_input_stream = array();
    }

    return $this->_fetch_from_array($this->_input_stream, $index, $xss_clean);
}
```
该方法和 get() 、 post() 和 cookie() 方法一样，只是它用于获取 [php://input](https://www.php.net/manual/zh/wrappers.php.php)流数据。

---

#### set_cookie() ####
```text
public function set_cookie($name, $value = '', $expire = '', $domain = '', $path = '/', $prefix = '', $secure = NULL, $httponly = NULL)
{
    if (is_array($name))
    {
        // always leave 'name' in last place, as the loop will break otherwise, due to $$item
        // 这里调用方式类似$this->input->set_cookie([ 'name' => 'a', 'value' => 'dd']);
        foreach (array('value', 'expire', 'domain', 'path', 'prefix', 'secure', 'httponly', 'name') as $item)
        {
            if (isset($name[$item]))
            {
                $$item = $name[$item];// 这里是将数组中的参数转为从调用方法传入的形式
            }
        }
    }

    //是否配置cookie前缀
    if ($prefix === '' && config_item('cookie_prefix') !== '')
    {
        $prefix = config_item('cookie_prefix');
    }

    //是否配置cookie有效域名
    if ($domain == '' && config_item('cookie_domain') != '')
    {
        $domain = config_item('cookie_domain');
    }

    //是否配置cookie的有效路径，默认是当前目录
    if ($path === '/' && config_item('cookie_path') !== '/')
    {
        $path = config_item('cookie_path');
    }

    //规定是否通过安全的 HTTPS 连接来传输 cookie。
    $secure = ($secure === NULL && config_item('cookie_secure') !== NULL)
        ? (bool) config_item('cookie_secure')
        : (bool) $secure;

   // 是否设置cookie_httponly
    $httponly = ($httponly === NULL && config_item('cookie_httponly') !== NULL)
        ? (bool) config_item('cookie_httponly')
        : (bool) $httponly;

    //设置cookie的过期时间，默认：默认在会话结束【浏览器关闭】失效
    if ( ! is_numeric($expire))
    {
        $expire = time() - 86500;
    }
    else
    {
        $expire = ($expire > 0) ? time() + $expire : 0;
    }

    setcookie($prefix.$name, $value, $expire, $path, $domain, $secure, $httponly);
}
```
该方法用于[设置cookie](https://www.php.net/manual/zh/function.setcookie)。

---

#### ip_address() ####
```text
public function ip_address()
{
    if ($this->ip_address !== FALSE)
    {
        return $this->ip_address;
    }

    /**
     * 当服务器使用了代理时，REMOTER_ADDR获取的就是代理服务器的IP了，
     * 需要从HTTP_X_FORWARDED_FOR、HTTP_CLIENT_IP、HTTP_X_CLIENT_IP、HTTP_X_CLUSTER_CLIENT_IP或其他设定的值中获取。
     * 这里设定的就是代理服务器的IP，逗号分隔。
     */
    $proxy_ips = config_item('proxy_ips');
    if ( ! empty($proxy_ips) && ! is_array($proxy_ips))
    {
        $proxy_ips = explode(',', str_replace(' ', '', $proxy_ips));
    }

    /**
     * REMOTE_ADDR代表着客户端的IP，但是这个客户端是相对服务器而言的，也就是实际上与服务器相连的机器的IP（建立tcp连接的那个），这个值是不可伪造的，
     * 如果没有代理的话，这个值就是用户实际的IP值，有代理的话，用户的请求会经过代理再到服务器，这个时候REMOTE_ADDR会被设置为代理机器的IP值。
     */
    $this->ip_address = $this->server('REMOTE_ADDR');

    if ($proxy_ips)
    {
        /**
         * HTTP_X_FORWARDED_FOR: 是有标准定义,用来识别通过HTTP代理或负载均衡方式连接到Web服务器的客户端最原始的IP地址,
         *      有了代理就获取不了用户的真实IP，由此X-Forwarded-For应运而生，它是一个非正式协议，
         *      在请求转发到代理的时候代理会添加一个X-Forwarded-For头，将连接它的客户端IP（也就是你的上网机器IP）加到这个头信息里，
         *      这样末端的服务器就能获取真正上网的人的IP了
         * HTTP_CLIENT_IP: 头是有的，只是未成标准，不一定服务器都实现了
         * HTTP_X_CLIENT_IP:
         * HTTP_X_CLUSTER_CLIENT_IP:
         */
        foreach (array('HTTP_X_FORWARDED_FOR', 'HTTP_CLIENT_IP', 'HTTP_X_CLIENT_IP', 'HTTP_X_CLUSTER_CLIENT_IP') as $header)
        {
            if (($spoof = $this->server($header)) !== NULL)
            {
                // 有些代理通常会列出客户端通过其与我们联系的IP地址的整个链。 例如 client_ip，proxy_ip1，proxy_ip2等
                // 这里的目的是从列表中取一个可用的ip，ipv4 或 ipv6
                sscanf($spoof, '%[^,]', $spoof);

                // 非ipv4/ipv6则返回false
                if ( ! $this->valid_ip($spoof))
                {
                    $spoof = NULL;
                }
                else
                {
                    break;
                }
            }
        }

        if ($spoof)
        {
            for ($i = 0, $c = count($proxy_ips); $i < $c; $i++)
            {
                // 检查是否有IP地址或子网
                if (strpos($proxy_ips[$i], '/') === FALSE)
                {
                    // 指定了IP地址（而不是子网） 可以立即进行比较。
                    if ($proxy_ips[$i] === $this->ip_address)
                    {
                        $this->ip_address = $spoof;
                        break;
                    }
                    continue;
                }

                // We have a subnet ... now the heavy lifting begins
                // ipv6:    xxxx:xxxx:xxxx:xxxx:xxxx:xxxx:xxxx:xxxx
                // ipv4:    10.120.78.40
                isset($separator) OR $separator = $this->valid_ip($this->ip_address, 'ipv6') ? ':' : '.';

                // If the proxy entry doesn't match the IP protocol - skip it
                if (strpos($proxy_ips[$i], $separator) === FALSE)
                {
                    continue;
                }

                // 如果需要，将REMOTE_ADDR IP地址转换为二进制
                // isset()只有在$ip, $sprintf全部设置时才返回true，这里返回的是false，因为$ip $sprintf未被设置
                if ( ! isset($ip, $sprintf))
                {
                    // : 表示IPv6
                    if ($separator === ':')
                    {
                        // Make sure we're have the "full" IPv6 format
                        /**
                         *  str_repeat() 重复一个字符串
                         *  substr_count() 计算字符串出现次数
                         *  :: 表示0位压缩，比如FF01::1101表示FF01:0:0:0:0:0:0:1101
                         */
                        $ip = explode(':',
                            str_replace('::',
                                str_repeat(':', 9 - substr_count($this->ip_address, ':')),
                                $this->ip_address
                            )
                        );

                        for ($j = 0; $j < 8; $j++)
                        {
                            $ip[$j] = intval($ip[$j], 16);
                        }

                        $sprintf = '%016b%016b%016b%016b%016b%016b%016b%016b';
                    }
                    else
                    {
                        $ip = explode('.', $this->ip_address);
                        $sprintf = '%08b%08b%08b%08b';
                    }

                    // vsprintf(): 返回格式化字符串
                    $ip = vsprintf($sprintf, $ip);
                }

                // Split the netmask length off the network address
                // sscanf根据format将$proxy_ips[$i]格式化为$netaddr和$masklen
                sscanf($proxy_ips[$i], '%[^/]/%d', $netaddr, $masklen);

                // Again, an IPv6 address is most likely in a compressed form
                if ($separator === ':')
                {
                    $netaddr = explode(':', str_replace('::', str_repeat(':', 9 - substr_count($netaddr, ':')), $netaddr));
                    for ($j = 0; $j < 8; $j++)
                    {
                        $netaddr[$j] = intval($netaddr[$j], 16);
                    }
                }
                else
                {
                    $netaddr = explode('.', $netaddr);
                }

                // 转换为二进制再比较一次
                if (strncmp($ip, vsprintf($sprintf, $netaddr), $masklen) === 0)
                {
                    $this->ip_address = $spoof;
                    break;
                }
            }
        }
    }

    // 如果 IP 地址无效，则返回 '0.0.0.0'
    if ( ! $this->valid_ip($this->ip_address))
    {
        return $this->ip_address = '0.0.0.0';
    }

    return $this->ip_address;
}
```

---

#### valid_ip() ####
```text
public function valid_ip($ip, $which = '')
{
    switch (strtolower($which))
    {
        case 'ipv4':
            $which = FILTER_FLAG_IPV4;
            break;
        case 'ipv6':
            $which = FILTER_FLAG_IPV6;
            break;
        default:
            $which = NULL;
            break;
    }

    /**
     * filter_var(): 使用特定的过滤器过滤一个变量，详见https://www.php.net/manual/zh/function.filter-var.php
     * $ip: 待过滤的变量。注意：标量的值在过滤前，会被转换成字符串。
     * FILTER_VALIDATE_IP: validate ip,詳見https://www.php.net/manual/zh/filter.filters.validate.php
     * $witch: 一个选项的关联数组，或者按位区分的标示。如果过滤器接受选项，可以通过数组的 "flags" 位去提供这些标示。
     */
    return (bool) filter_var($ip, FILTER_VALIDATE_IP, $which);
}
```

---

#### user_agent() ####
```text
public function user_agent($xss_clean = NULL)
{
    // HTTP_USER_AGENT: 获取用户的所有信息， 比如，Mozilla/5.0 平台操作系统（包括版本号） 引擎版本  浏览器（包括版本号）
    return $this->_fetch_from_array($_SERVER, 'HTTP_USER_AGENT', $xss_clean);
}
```

---

#### _sanitize_globals() ####
```text
protected function _sanitize_globals()
{
    // 表示是否允许用户使用$_GET全局变量，如果设置为不允许，会在输入类构造函数处理中将$_GET清空。
    if ($this->_allow_get_array === FALSE)
    {
        $_GET = array();
    }
    elseif (is_array($_GET))
    {
        // ?k=aa&v=bb&**(*=$%##
        /**
         * $_GET = [
         *      'k' => string 'aa' (length=2)
         *      'v' => string 'bb' (length=2)
         *      '**(*' => string '$%' (length=2)
         * ]
         */
        foreach ($_GET as $key => $val)
        {
            $_GET[$this->_clean_input_keys($key)] = $this->_clean_input_data($val);
        }
        /**
         * $_GET = [
         *      'k' => string 'aa'
         *      'v' => string 'bb'
         *      '**(*' => string '$%'
         *      0 => string '$%'
         * ]
         */
    }

    // Clean $_POST Data
    if (is_array($_POST))
    {
        /**
         * $_POST  = [
         *      'k' => string 'aa'
         *      'v' => string 'bb'
         *      '**(*' => string '$%##'
         * ]
         */
        foreach ($_POST as $key => $val)
        {
            $_POST[$this->_clean_input_keys($key)] = $this->_clean_input_data($val);
        }
        /**
         *  $POST = [
         *      'k' => string 'aa'
         *      'v' => string 'bb'
         *      '**(*' => string '$%##'
         *      0 => string '$%##'
         * ]
         */
    }

    // Clean $_COOKIE Data
    if (is_array($_COOKIE))
    {
        // 注意下面unset的不是变量，单引号括起来了。
        unset(
            $_COOKIE['$Version'],
            $_COOKIE['$Path'],
            $_COOKIE['$Domain']
        );

        // $_COOKIE 的话不符合的key直接删掉
        foreach ($_COOKIE as $key => $val)
        {
            if (($cookie_key = $this->_clean_input_keys($key)) !== FALSE)
            {
                                        // 将换行符标准化为PHP_EOL
                $_COOKIE[$cookie_key] = $this->_clean_input_data($val);
            }
            else
            {
                unset($_COOKIE[$key]);
            }
        }
    }

    // Sanitize PHP_SELF
    // strip_tags(): 去除 HTML 和 PHP 标记
    $_SERVER['PHP_SELF'] = strip_tags($_SERVER['PHP_SELF']);

    log_message('debug', 'Global POST, GET and COOKIE data sanitized');
}
```
该方法用于过滤全局变量，如果未启用查询字符串，则取消设置$ _GET数据、清除POST，COOKIE和SERVER数据、将换行符标准化为PHP_EOL。

---

#### _clean_input_data() ####
```text
protected function _clean_input_data($str)
{
    // 如果$str是个数组，则对数组的键和值进行过滤
    if (is_array($str))
    {
        $new_array = array();
        foreach (array_keys($str) as $key)
        {
            $new_array[$this->_clean_input_keys($key)] = $this->_clean_input_data($str[$key]);
        }
        return $new_array;
    }

    /* 5.4.0開始 魔术引号功能从PHP中移除！小于5.4的版本如果magic_quotes_gpc的配置选项开启则反引用一个引用字符串 */
    if ( ! is_php('5.4') && get_magic_quotes_gpc())
    {
        // stripslashes(): 返回一个去除转义反斜线后的字符串（\' 转换为 ' 等等）。
        // 双反斜线（\\）被转换为单个反斜线（\）。
        $str = stripslashes($str);
    }

    // Clean UTF-8 if supported
    if (UTF8_ENABLED === TRUE)
    {
               // 确保字符串仅包含有效的UTF-8字符
        $str = $this->uni->clean_string($str);
    }

    // 删除不可见字符
    $str = remove_invisible_characters($str, FALSE);

    // Standardize newlines if needed 默认不进行替换，参考$config['standardize_newlines']
    if ($this->_standardize_newlines === TRUE)
    {
        return preg_replace('/(?:\r\n|[\r\n])/', PHP_EOL, $str);
    }

    return $str;
}
```
该方法用于过滤输入的值。

---

#### _clean_input_keys() ####
```text
protected function _clean_input_keys($str, $fatal = TRUE)
{
    //如果$str中有不允许的字符串则根据$fatal取值返回false活着直接报503，exit
    if ( ! preg_match('/^[a-z0-9:_\/|-]+$/i', $str))
    {
        if ($fatal === TRUE)
        {
            return FALSE;
        }
        else
        {
            set_status_header(503);
            echo 'Disallowed Key Characters.';
            exit(7); // EXIT_USER_INPUT
        }
    }

    // Clean UTF-8 if supported
    if (UTF8_ENABLED === TRUE)
    {
        return $this->uni->clean_string($str);
    }

    return $str;
}
```
过滤键值。

---

#### request_headers() ####
```text
/* 获取http 请求头信息 */
public function request_headers($xss_clean = FALSE)
{
    // If header is already defined, return it immediately
    if ( ! empty($this->headers))
    {
        return $this->_fetch_from_array($this->headers, NULL, $xss_clean);
    }

    // In Apache, you can simply call apache_request_headers()
    if (function_exists('apache_request_headers'))
    {
        // 获取全部http头信息： https://www.php.net/manual/zh/function.apache-request-headers.php
        $this->headers = apache_request_headers();
    }
    else
    {
        isset($_SERVER['CONTENT_TYPE']) && $this->headers['Content-Type'] = $_SERVER['CONTENT_TYPE'];

        foreach ($_SERVER as $key => $val)
        {
            // HTTP_ACCEPT_CHARSET
            if (sscanf($key, 'HTTP_%s', $header) === 1)
            {
                // take SOME_HEADER and turn it into Some-Header
                $header = str_replace('_', ' ', strtolower($header));// accept charset
                $header = str_replace(' ', '-', ucwords($header));   // Accept-Charset

                $this->headers[$header] = $_SERVER[$key];            // $this->headers['Accept-Charset'] = $_SERVER['HTTP_ACCEPT_CHARSET'];
            }
        }
    }

    return $this->_fetch_from_array($this->headers, NULL, $xss_clean);
}
```

---

#### get_request_header() ####
```text
public function get_request_header($index, $xss_clean = FALSE)
{
    static $headers;

    // 如果未定义$headers则定义并赋值头信息
    if ( ! isset($headers))
    {
        empty($this->headers) && $this->request_headers();
        foreach ($this->headers as $key => $value)
        {
            // $headers['accept-charset']
            $headers[strtolower($key)] = $value;
        }
    }

    $index = strtolower($index);

    // 没有则返回NULL
    if ( ! isset($headers[$index]))
    {
        return NULL;
    }

    // 如果存在则返回对应的值，当然根据需求进行xss滤波
    return ($xss_clean === TRUE)
        ? $this->security->xss_clean($headers[$index])
        : $headers[$index];
}
```

---

#### is_ajax_request() ####
```text
public function is_ajax_request()
{
    return ( ! empty($_SERVER['HTTP_X_REQUESTED_WITH']) && strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) === 'xmlhttprequest');
}
```
判断是否为ajax请求，通过`$_SERVER['HTTP_X_REQUESTED_WITH'])`来判断。

---

#### is_cli_request() ####
```text
public function is_cli_request()
{
    return is_cli();
}
```
判断是否为CLI【命令行执行方式】请求。

---

#### method() ####
```text
public function method($upper = FALSE)
{
    return ($upper)
        ? strtoupper($this->server('REQUEST_METHOD'))
        : strtolower($this->server('REQUEST_METHOD'));
}
```

---

#### __get() ####
```text
public function __get($name)
{
    if ($name === 'raw_input_stream')
    {
        isset($this->_raw_input_stream) OR $this->_raw_input_stream = file_get_contents('php://input');
        return $this->_raw_input_stream;
    }
    elseif ($name === 'ip_address')
    {
        return $this->ip_address;
    }
}
```
用来获取受保护属性  ip_address | _raw_input_stream。

---


#### 参考链接 ####
[CI框架源码解析十二之输入类文件Input.php](https://blog.csdn.net/Zhihua_W/article/details/52943007)
