---
title: CodeIgniter RESTful API实现
date: 2020-04-17 10:39:12
tags:
- PHP
- Codeigniter
categories:
- 开发者手册
---

#### 引言 ####

利用一个库文件、一个配置文件以及一个控制器就可以实现完整的CodeIgniter开发RESTful架构API的一个工具。
<!-- more -->
----

#### 认识RESTful ####

参考**阮一峰**先生的三篇文章: [理解RESTful架构](http://www.ruanyifeng.com/blog/2011/09/restful.html)、[RESTful API 设计指南](http://www.ruanyifeng.com/blog/2014/05/restful_api.html)、[RESTful API 最佳实践](http://www.ruanyifeng.com/blog/2018/10/restful-api-best-practices.html)

#### 实现REST API ####

##### 安装配置 #####

1. 下载[codeigniter-restserver](https://github.com/chriskacerguis/codeigniter-restserver/releases/tag/3.0.0)，该版本为`3.0.0`版本，最新版本`4.0.0`的安装方法可参考[https://github.com/chriskacerguis/codeigniter-restserver](https://github.com/chriskacerguis/codeigniter-restserver)。
2. 将`3.0.0`版本下载后解压会看到`libraries`目录下有两个文件(一个库文件、一个控制器文件)`Format.php`和`REST_Controller.php`，移动到CI中的`application/libraries`目录下。
3. 将解压目录下`config`目录下的`rest.php`文件移至CI的`application/config`目录下。

将三个文件拷贝到指定目录后就配置完了。

##### 示例 #####

写一个漏洞百出的`^_^`Blog控制器:
```php
defined('BASEPATH') or exit("No direct script access allowed");

require_once APPPATH . 'libraries/REST_Controller.php';

class Blog extends REST_Controller
{
    public function __construct()
    {
        parent::__construct();
        $this->load->model('blog_model');
    }

    // 新建资源
    public function index_post()
    {
        $input = $this->post();
        $result = $this->blog_model->add_blog($input);

        $this->response([
            'ret' => REST_Controller::HTTP_OK,
            'msg' => '',
            'data' => [
                'code' => SUCCESS,
                'message' => 'Blog create successfully.',
            ],
        ], REST_Controller::HTTP_OK);
    }

    // 获取资源列表
    public function index_get()
    {
        $page = $this->get('page') ?: 1;
        $limit = $this->get('limit') ?: 10;

        $result = $this->blog_model->get_list($limit, $page);

        $this->response([
            'ret' => REST_Controller::HTTP_OK,
            'msg' => '',
            'data' => [
                'code' => SUCCESS,
                'message' => '',
                'total' => $result['total'],
                'list' => $result['list'],
            ],
        ], REST_Controller::HTTP_OK);
    }

    // 获取单个资源
    public function id_get($id)
    {
        $result = $this->blog_model->get_by_id($id);

        $this->response([
            'ret' => REST_Controller::HTTP_OK,
            'msg' => '',
            'data' => [
                'code' => SUCCESS,
                'message' => '',
                'info' => $result,
            ],
        ], REST_Controller::HTTP_OK);
    }

    // 更新单个资源
    public function id_put($id)
    {
        $where['blog_id'] = $id;
        $input = $this->put();
        $result = $this->blog_model->update_blog($input, $where); // 成功返回true

        $this->response([
            'ret' => REST_Controller::HTTP_OK,
            'msg' => '',
            'data' => [
                'code' => SUCCESS,
                'message' => 'Blog update successfully.',
            ],
        ], REST_Controller::HTTP_OK);
    }
}
```

`/api/blog`获取列表接口返回：
```json
{
  "ret": 200,
  "msg": "",
  "data": {
    "code": 0,
    "message": "",
    "total": 3,
    "list": [
      {
        "blog_id": "1",
        "blog_title": "咏鹅",
        "blog_description": "鹅鹅鹅，曲项向天歌，白毛浮绿水，红掌拨清波"
      },
      {
        "blog_id": "2",
        "blog_title": "春晓",
        "blog_description": "春眠不觉晓，处处闻啼鸟。夜来风雨声，花落知多少。"
      },
      {
        "blog_id": "3",
        "blog_title": "登鹳雀楼",
        "blog_description": "白日依山尽，黄河入海流。欲穷千里目，更上一层楼。"
      }
    ]
  }
}
```

`api/blog/3`获取单个接口返回：
```json
{
  "ret": 200,
  "msg": "",
  "data": {
    "code": 0,
    "message": "",
    "info": {
      "blog_id": "3",
      "blog_title": "登鹳雀楼",
      "blog_description": "白日依山尽，黄河入海流。欲穷千里目，更上一层楼。"
    }
  }
}
```

##### 源码分析 #####

###### REST_Controller ######

<b><font color="#891717">HTTP status codes const</font></b>
```php
const HTTP_CONTINUE = 100;
const HTTP_SWITCHING_PROTOCOLS = 101;
const HTTP_PROCESSING = 102;            // RFC2518

// Success
const HTTP_OK = 200;
const HTTP_CREATED = 201;
const HTTP_ACCEPTED = 202;
const HTTP_NON_AUTHORITATIVE_INFORMATION = 203;
const HTTP_NO_CONTENT = 204;
const HTTP_RESET_CONTENT = 205;
const HTTP_PARTIAL_CONTENT = 206;
const HTTP_MULTI_STATUS = 207;          // RFC4918
const HTTP_ALREADY_REPORTED = 208;      // RFC5842
const HTTP_IM_USED = 226;               // RFC3229

// Redirection
const HTTP_MULTIPLE_CHOICES = 300;
const HTTP_MOVED_PERMANENTLY = 301;
const HTTP_FOUND = 302;
const HTTP_SEE_OTHER = 303;
const HTTP_NOT_MODIFIED = 304;
const HTTP_USE_PROXY = 305;
const HTTP_RESERVED = 306;
const HTTP_TEMPORARY_REDIRECT = 307;
const HTTP_PERMANENTLY_REDIRECT = 308;  // RFC7238

// Client Error
const HTTP_BAD_REQUEST = 400;
const HTTP_UNAUTHORIZED = 401;
const HTTP_PAYMENT_REQUIRED = 402;
const HTTP_FORBIDDEN = 403;
const HTTP_NOT_FOUND = 404;
const HTTP_METHOD_NOT_ALLOWED = 405;
const HTTP_NOT_ACCEPTABLE = 406;
const HTTP_PROXY_AUTHENTICATION_REQUIRED = 407;
const HTTP_REQUEST_TIMEOUT = 408;
const HTTP_CONFLICT = 409;
const HTTP_GONE = 410;
const HTTP_LENGTH_REQUIRED = 411;
const HTTP_PRECONDITION_FAILED = 412;
const HTTP_REQUEST_ENTITY_TOO_LARGE = 413;
const HTTP_REQUEST_URI_TOO_LONG = 414;
const HTTP_UNSUPPORTED_MEDIA_TYPE = 415;
const HTTP_REQUESTED_RANGE_NOT_SATISFIABLE = 416;
const HTTP_EXPECTATION_FAILED = 417;
const HTTP_I_AM_A_TEAPOT = 418;                                               // RFC2324
const HTTP_UNPROCESSABLE_ENTITY = 422;                                        // RFC4918
const HTTP_LOCKED = 423;                                                      // RFC4918
const HTTP_FAILED_DEPENDENCY = 424;                                           // RFC4918
const HTTP_RESERVED_FOR_WEBDAV_ADVANCED_COLLECTIONS_EXPIRED_PROPOSAL = 425;   // RFC2817
const HTTP_UPGRADE_REQUIRED = 426;                                            // RFC2817
const HTTP_PRECONDITION_REQUIRED = 428;                                       // RFC6585
const HTTP_TOO_MANY_REQUESTS = 429;                                           // RFC6585
const HTTP_REQUEST_HEADER_FIELDS_TOO_LARGE = 431;                             // RFC6585

// Server Error
const HTTP_INTERNAL_SERVER_ERROR = 500;
const HTTP_NOT_IMPLEMENTED = 501;
const HTTP_BAD_GATEWAY = 502;
const HTTP_SERVICE_UNAVAILABLE = 503;
const HTTP_GATEWAY_TIMEOUT = 504;
const HTTP_VERSION_NOT_SUPPORTED = 505;
const HTTP_VARIANT_ALSO_NEGOTIATES_EXPERIMENTAL = 506;                        // RFC2295
const HTTP_INSUFFICIENT_STORAGE = 507;                                        // RFC4918
const HTTP_LOOP_DETECTED = 508;                                               // RFC5842
const HTTP_NOT_EXTENDED = 510;                                                // RFC2774
const HTTP_NETWORK_AUTHENTICATION_REQUIRED = 511;
```

<b><font color="#891717">变量</font></b>
```php
// 默认的REST输出格式，必须在控制器中进行重新覆盖以便进行设置
// 一般客户端通过"Content-Type"来进行设置用不到此变量
protected $rest_format = NULL;

/**
 * 在控制器中进行设置，用来设置某个方法['token_post' => ['level' => 10, 'limit' => 300]]
 * ①limit 每小时请求次数限制
 *②level 设置等级，小于某个等级将不验证token
 * ③log   是否将请求进行记录
 * ④key   是否使用token
 */
protected $methods = [];

// 支持的请求方法
protected $allowed_http_methods = ['get', 'delete', 'post', 'put', 'options', 'patch', 'head'];

/**
 * 是一个对象，包含四个变量
 * body    请求体信息，可理解为请求参数
 * format  请求内容格式，在客户端通过Content-Type来设置，比如json、xml
 * method  请求方法
 * ssl     是否为https
 */
protected $request = NULL;

/**
 * 是一个对象，包含两个变量
 * format 响应内容格式
 * lang   响应内容语言
 */
protected $response = NULL;

/**
 * REST API的详细信息，包含五个变量
 * db            将请求写入日志或验证token时需要加载配置的数据库对象，否则使用系统使用已存在的数据库对象
 * key           token值
 * level         token等级
 * user_id       token对应的用户名，通过token来判断登录用户
 * ignore_limits token是否忽略限制
 */
protected $rest = NULL;

// 请求参数
protected $_get_args = [];
protected $_post_args = [];
protected $_put_args = [];
protected $_delete_args = [];
protected $_patch_args = [];
protected $_head_args = [];
protected $_options_args = [];

// 查询参数，即$this->input->get();
protected $_query_args = [];

// 请求参数集合
protected $_args = [];

// 将请求写入日志后会返回insert id，用来更新本条记录
protected $_insert_id = '';

// 请求是否被允许，当使用token验证时如果没通过验证则不被允许
protected $_allow = TRUE;

/**
 * 轻量级目录访问协议验证时用，用户名
 */
protected $_user_ldap_dn = '';

// 服务器响应的开始时间
protected $_start_rtime;

// 服务器响应结束的时间
protected $_end_rtime;

/**
 * 支持的响应信息格式
 */
protected $_supported_formats = [
	'json' => 'application/json',
	'array' => 'application/json',
	'csv' => 'application/csv',
	'html' => 'text/html',
	'jsonp' => 'application/javascript',
	'php' => 'text/plain',
	'serialized' => 'application/vnd.php.serialized',
	'xml' => 'application/xml'
];

/**
 * 根据token获取用户信息，保存到该变量中
 */
protected $_apiuser;

// 检查cors
protected $check_cors = NULL;

// xss 过滤
protected $_enable_xss = FALSE;

// 表示请求是否有效
private $is_valid_request = TRUE;

// 响应状态码
protected $http_status_codes = [
	self::HTTP_OK => 'OK',
	self::HTTP_CREATED => 'CREATED',
	self::HTTP_NO_CONTENT => 'NO CONTENT',
	self::HTTP_NOT_MODIFIED => 'NOT MODIFIED',
	self::HTTP_BAD_REQUEST => 'BAD REQUEST',
	self::HTTP_UNAUTHORIZED => 'UNAUTHORIZED',
	self::HTTP_FORBIDDEN => 'FORBIDDEN',
	self::HTTP_NOT_FOUND => 'NOT FOUND',
	self::HTTP_METHOD_NOT_ALLOWED => 'METHOD NOT ALLOWED',
	self::HTTP_NOT_ACCEPTABLE => 'NOT ACCEPTABLE',
	self::HTTP_CONFLICT => 'CONFLICT',
	self::HTTP_INTERNAL_SERVER_ERROR => 'INTERNAL SERVER ERROR',
	self::HTTP_NOT_IMPLEMENTED => 'NOT IMPLEMENTED'
];

// Format对象
private $format;

// 请求方法重新定义验证方式，可在rest配置文件中定义
private $auth_override;
```

<b><font color="#891717">部分方法</font></b>
```php
/**
 * 检测PHP和CI是否符合要求
 * 设置_enable_xss
 * 禁用解析伪变量，如{elapsed_time} {memory_usage}
 * 设置请求时间
 * 获取rest配置信息
 * 加载Format类库
 * 从配置信息中确定支持的输出格式
 * 如果缺少默认输出格式则进行添加
 * 从配置信息中获取语言类型，默认为'simplified-chinese'，若没有设置则为'english'，根据该类型加载rest语言文件
 * 初始化response、request、rest对象
 * 配置文件rest_ip_blacklist_enabled设置为true则检查当前的IP地址是否被列入黑名单，默认为false
 * 确定连接是否为HTTPS
 * 确定请求方法，根据请求方法创建请求参数容器，如_get_args
 * 检查CORS访问请求
 * 解析查询参数
 * 设置_get_args
 * 解析请求格式、请求体以及获取请求参数
 * 确定响应格式、响应语言类型
 * 如果配置了rest_database_group并且使用密钥或者需要写入日志则加载数据库类
 * 请求API如果在rest文件中进行了相关设置，比如none basic digest library则进行相关验证准备
 * 解析密钥
 * rest设置不支持Ajax请求，如果发现请求是Ajax请求则报错
 * 根据rest_enable_keys、allow_auth_and_keys、rest_auth进行相关验证
 * 根据rest_ip_whitelist_enabled进行白名单验证
 */
__construct()

get_local_config() // 加载rest配置文件，即rest.php

__destruct() // 日志更新响应结束时间

preflight_checks() // 检测PHP和CI的版本是否符合要求

/**
 * 重定向方法，由CodeIgniter.php文件调用，该方法实现过程
 * 根据force_https配置项检测当前请求是否为https
 * 去掉请求方法中的文件扩展名，加上请求动词，如:index_get，请求方法不存在则默认为index_get
 * 判断请求方法是否要写入日志，若需要则写入日志
 * 判断请求方法是否使用密钥，若使用了则检查该密钥是否有权限访问请求控制器
 * 如果有权限访问该控制器则判断请求方法是否存在
 * 若存在密钥则判断请求是否限制次数
 * 调用更新后的控制器-方法
 */
_remap()

// 设置响应、返回响应
response()
set_response()


_get_default_output_format() // 获取默认响应格式，默认由rest_default_format进行配置，默认值为json

_detect_input_format()    // 检测请求内容格式
_detect_output_format()    // 检测响应内容格式
_detect_method()           // 检测请求方法
_detect_api_key()          // 根据API KEY确定登录用户，API KEY的类型由rest_key_name定义，可为Authorization、X-API-KEY
_detect_lang()             // 检测客户端支持的语言

_log_request() // 请求api写入log

_check_limit() // 请求数检查

// 请求API在auth_override_class_method配置了none、digest、basic、session、whitelist时会调用对应的验证方法
_auth_override_check() 

_parse_get()     // 解析GET请求参数
_parse_post()    // 解析POST请求参数
_parse_put()     // 解析PUT请求参数
_parse_head()    // 解析HEAD请求参数
_parse_options() // 解析OPTIONS请求参数
_parse_patch()   // 解析PATCH请求参数
_parse_delete()  // 解析DELETE请求参数
_parse_query()   // 解析查询参数

// 获取请求参数方法
get()      // $this->get('xxx') or $this->get()
options()  // $this->options('xxx') or $this->options()
head()     // $this->head('xxx') or $this->head()
post()     // $this->post('xxx') or $this->post()
put()      // $this->put('xxx') or $this->put()
delete()   // $this->delete('xxx') or $this->delete()
patch()    // $this->patch('xxx') or $this->patch()
query()    // $this->query('xxx') or $this->query()


_xss_clean() // xss过滤方法

validation_errors() // 表单验证产生的错误信息

_perform_ldap_auth()    // ldap登录验证，auth_source配置为ldap时调用
_perform_library_auth() // library登录验证，auth_source配置为library时调用
_check_login() // 登录验证 digest、ldap、library

_check_php_session()    // rest_auth配置为session时调用
_prepare_basic_auth()   // rest_auth配置为basic时调用
_prepare_digest_auth()  // rest_auth配置为digest时调用

_check_blacklist_auth() // 黑名单验证，默认开关未打开
_check_whitelist_auth() // 白名单验证，默认开关未打开

_force_login() // 验证失败，给出响应

_log_access_time()   // 更新请求处理时间
_log_response_code() // 更新请求结果，状态码

_check_access() // 检查API密钥是否有权限访问控制器和方法，需要在rest配置文件总设置
_check_cors()   // 检查跨域请求是否合法
```
