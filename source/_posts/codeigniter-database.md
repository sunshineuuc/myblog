---
title: CodeIgniter数据库相关功能的实现机制
date: 2020-03-17 11:02:50
tags:
- Php
- Codeigniter
categories:
- Web工作笔记
---

#### 引言 ####

`PHP`操作数据库`如MySQL`的流程分为**连接数据库**、**设置字符编码**、**选择数据库**、**构造sql语句**、**执行sql语句**、**获取执行结果**、**关闭数据库连接**等。如下面一个分页的例子
<!-- more -->
```php
// 连接数据库
$link = mysqli_connect('localhost','root','xxxxxx');

if (!$link) {
    exit('connect database faild!');
}
// 设置字符编码
mysqli_set_charset($link,'utf8');
// 选择数据库
mysqli_select_db($link,'bbs');
// 构造sql
$get_count_sql = 'select count(*) as count from user';
// 执行sql
$count = mysqli_fetch_assoc(mysqli_query($link,$get_count_sql));

// 分页
$page = (isset($_GET['page']) && $_GET['page'] > 1) ? $_GET['page'] : 1;
$num = 4;
$start = ($page - 1) * $num;
$end = ceil($count['count']/$num);

// 构造sql
$sql = "select * from user limit $start , $num";
// 执行
$ret = mysqli_query($link,$sql);

// html呈现
echo "<html><table width='800' border='2'>";
echo "<th>编号</th><th>用户名</th><th>地址</th><th>性别</th><th>年龄</th>";
while($result = mysqli_fetch_assoc($ret)) {    $sex = $result['sex'] ? "男" : "女";
    echo "<tr><td>".$result['id']."</td><td>".$result['username']."</td><td>".$result['address']."</td><td>".$sex."</td><td>".$result['age']."</td></tr>";
}
echo "</table>";
$prev = ($page > 1) ? $page - 1 : 1;
$next = ($page < $end) ?  $page + 1 : $end;
echo "<a href='page.php?page=1'>首页</a> <a href='page.php?page=$prev'>上页</a> <a href='page.php?page=$next'>下页</a> <a href='page.php?page=$end'>尾页</a>";
for ($i = 1; $i <= $end; $i++) {
    echo " <a href='page.php?page=$i'>$i</a>";
}
echo "</html>";

// 关闭连接
mysqli_close($link);
```
这个例子有很多不足之处，比如分页不是从sql里分页而是拿出数据后使用php的逻辑来分页肯定有效率问题，这里不做讨论，主要是用来显示`PHP`操作`MySQL`的流程。明白了上面的流程就可以看CodeIgniter对数据库操作的实现机制了。详细的介绍可参考官网[数据库参考](https://codeigniter.org.cn/user_guide/database/index.html)。下面从`代码`的角度学习这部分。

---

#### 数据库配置 ####
APPPATH . 'config/database.php'为数据库的配置文件
```php
$db['default'] = array(
	'dsn'	=> '',
	'hostname' => 'localhost',
	'port' => 3306,
	'username' => 'root',
	'password' => 'root',
	'database' => '',
	'dbdriver' => 'mysqli',
	'dbprefix' => '',
	'pconnect' => FALSE,
	'db_debug' => (ENVIRONMENT !== 'production'),
	'cache_on' => FALSE,
	'cachedir' => '',
	'char_set' => 'utf8',
	'dbcollat' => 'utf8_general_ci',
	'swap_pre' => '',
	'encrypt' => FALSE,
	'compress' => FALSE,
	'stricton' => FALSE,
	'failover' => array(),
	'save_queries' => TRUE
);
$db['codeigniter'] = array(
    'dsn'	=> '',                   // DNS连接字符串（该字符串包含了所有的数据库配置信息）
    'hostname' => 'localhost',     // 数据库的主机名
    'port' => 3306,                 // 数据库端口号
    'username' => 'codeigniter',  // 需要连接到数据库的用户名
    'password' => 'helloworld',   // 登录数据库的密码
    'database' => 'codeigniter',  // 需要连接的数据库名
    'dbdriver' => 'mysqli',       // 数据库类型: mysqli postgres odbc
    'dbprefix' => '',             // 当使用查询构造器查询时，可以选择性的为表加个前缀
    'pconnect' => FALSE,          // 是否使用持续连接
    'db_debug' => (ENVIRONMENT !== 'production'), // 是否显示数据库错误信息
    'cache_on' => FALSE,             // 是否开启数据库查询缓存
    'cachedir' => '',                // 数据库查询缓存目录所在服务器的绝对路径
    'char_set' => 'utf8',           // 与数据库通信时所使用的字符集
    'dbcollat' => 'utf8_general_ci',// 只是用与mysql和mysqli数据库驱动
    'swap_pre' => '',     // 替换默认的 dbprefix 表前缀，该项设置对于分布式应用是非常有用的， 可以在查询中使用由最终用户定制的表前缀。
    'encrypt' => FALSE,  // 是否使用加密连接
    'compress' => FALSE, // 是否使用客户端压缩协议（只用于MySQL）
    'stricton' => FALSE, // 是否强制使用 "Strict Mode" 连接, 在开发程序时，使用 strict SQL 是一个好习惯。
    'failover' => array(),
    'save_queries' => TRUE
);

$active_group = 'codeigniter'; // 告訴系统要使用codeigniter数据库
$query_builder = TRUE;         // 数据库初始化时对查询构造器类进行全局设定
```
使用哪款**数据库**，使用哪个**端口**会根据项目需求具体情况具体分析，CodeIgniter将这些信息整合到具体的配置文件中来统一配置。然后根据配置信息选择对应的`数据库适配器`、`查询构造类`等。各类数据库适配器目录结构如下
```text
H:\CodeIgniter-3.1.11\system>tree
卷 test 的文件夹 PATH 列表
卷序列号为 AC46-F491
H:.
├─core
│  └─compat
├─database
│  └─drivers
│      ├─cubrid
│      ├─ibase
│      ├─mssql
│      ├─mysql
│      ├─mysqli
│      │      index.html
│      │      mysqli_driver.php
│      │      mysqli_forge.php
│      │      mysqli_result.php
│      │      mysqli_utility.php
│      ├─oci8
│      ├─odbc
│      ├─pdo
│      │  └─subdrivers
│      ├─postgre
│      ├─sqlite
│      ├─sqlite3
│      └─sqlsrv
├─fonts
├─...
```
限于篇幅，上面仅**手动**加上了`mysqli`目录下的文件，其实每个数据库都有相对应的`driver`, `forge`, `result`, `utility`等文件。

#### 连接数据库 ####

连接数据库有`自动连接`和`手动连接`两种方式，其中在加载`model`时可以设置同时连接数据库，在加载`dbutilh`和`dbforge`时则会间接的连接数据库。这里的连接数据库都是执行的`$this->load->database()`语句。

##### 自动连接 #####

`自动连接`特性将在每一个页面加载时自动实例化数据库类。要启用`自动连接`， 可在 `application/config/autoload.php`中的`library`数组里添加`database`:
```php
$autoload['libraries'] = array('database');
```
配置好后会在`初始化Loader类`时完成数据库的连接，可参考[Loader类](https://pureven.cc/2020/02/17/codeigniter-loader/)中`initialize()`的方法。通过该方法间接执行了`this->load->database()`
```php
if (isset($autoload['libraries']) && count($autoload['libraries']) > 0)
{
    // Load the database driver. 此处是指初始化时就加载数据库
    if (in_array('database', $autoload['libraries']))
    {
        // 加载DB类，只有加载了才能使用$this->db->...
        $this->database();
        // 返回不包含'database'的数组
        $autoload['libraries'] = array_diff($autoload['libraries'], array('database'));
    }

    // Load all other libraries
    $this->library($autoload['libraries']);
}
```

##### 手动连接 #####

`手动连接`是指可以手动执行`$this->load->database()`语句来连接数据库，详见[手动连接到数据库](https://codeigniter.org.cn/user_guide/database/connecting.html#id5)。

