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
限于篇幅，上面仅**手动**加上了`mysqli`目录下的文件，其实每个数据库都有相对应的`driver`, `forge`, `result`, `utility`等文件。CodeIgniter根据配置文件中的数据库信息加载对应的文件。

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

---

#### 连接过程分析 ####

当执行`$this->load->database()`语句时实际上执行的是`Loader类`中的`database()`方法，在[Loader类]()中有相关分析，这里单独拿出database()方法的代码
```php
/**
* @params - 数据库组名称或配置选项
* @return - 是否返回加载的数据库对象，false表示将数据库类加载到超级对象，true表示直接返回数据库类实例
* @query_builder 是否加载查询构造器
**/
public function database($params = '', $return = FALSE, $query_builder = NULL)
{
    // 获取超级对象
    $CI =& get_instance();

    // 如果要求返回数据库类实例，但是超级对象中已经加载并建立了到数据库的连接则直接返回false
    if ($return === FALSE && $query_builder === NULL && isset($CI->db) && is_object($CI->db) && ! empty($CI->db->conn_id))
    {
        return FALSE;
    }

    // 重点： 加载DB.php文件，该文件中只有一个DB方法，加载数据库类和加载构造器都是通过这个方法来加载的
    require_once(BASEPATH.'database/DB.php');

    // 这里判断如果要求返回数据库类的实例则直接通过DB()方法返回
    if ($return === TRUE)
    {
        return DB($params, $query_builder);
    }

    // Initialize the db variable. Needed to prevent
    // reference errors with some configurations
    $CI->db = '';

    // Load the DB class
    $CI->db =& DB($params, $query_builder);
    return $this;
}
```
下面再来看看DB方法，该方法也就是`BASEPATH . 'database/DB.php'`的内容
```php
/**
* @params - 数据库连接值，一般为数据库组名称或配置选项
* @query_builder_override - 是否加载查询构造器
**/
function &DB($params = '', $query_builder_override = NULL)
{
	// 如果数据连接值不是DSN字符串则加载配置文件database.php
    if (is_string($params) && strpos($params, '://') === FALSE)
    {
        // database.php文件不存在则报错
        if ( ! file_exists($file_path = APPPATH.'config/'.ENVIRONMENT.'/database.php')
            && ! file_exists($file_path = APPPATH.'config/database.php'))
        {
            show_error('The configuration file database.php does not exist.');
        }
    
        // 加载database.php文件
        include($file_path);
    
        // CI_Controller类中会调用$this->load->initialize();语句将autoload.php文件设置的默认加载项加载了
        // 因此如果存在CI_Controller说明已经加载了默认加载项
        if (class_exists('CI_Controller', FALSE))
        {
            // 如果默认加载项包含package，则需要判断package目录下有没有database.php配置文件，有则加载
            foreach (get_instance()->load->get_package_paths() as $path)
            {
                if ($path !== APPPATH)
                {
                    if (file_exists($file_path = $path.'config/'.ENVIRONMENT.'/database.php'))
                    {
                        include($file_path);
                    }
                    elseif (file_exists($file_path = $path.'config/database.php'))
                    {
                        include($file_path);
                    }
                }
            }
        }
    
        // database.php文件中定义了$db数组，加载完database.php文件后如果不存在$db数组保存退出
        if ( ! isset($db) OR count($db) === 0)
        {
            show_error('No database connection settings were found in the database config file.');
        }
    
        // $active_group表示要使用哪个数据库组
        // 如果指定了数据库组就使用指定的，不指定就使用默认的，通常在database.php文件中会通过$active_group = 'default';语句来设置
        if ($params !== '')
        {
            $active_group = $params;
        }
    
        // 如果不存在则说明没有指定要连接的数据库，保存退出
        if ( ! isset($active_group))
        {
            show_error('You have not specified a database connection group via $active_group in your config/database.php file.');
        }
        elseif ( ! isset($db[$active_group]))
        {   // 如果指定了数据库组，但是这个组内没有连接数据库的相关信息也会报错退出
            show_error('You have specified an invalid database connection group ('.$active_group.') in your config/database.php file.');
        }
    
        // 将连接数据库需要的信息赋值给$params， 这里的信息包括hostname、username、password、database、dbdriver、char_set...
        $params = $db[$active_group];
    }
    elseif (is_string($params))
    {
        /**
         * DSNs必须有以下属性: $dsn = 'driver://username:password@hostname/database';
         * 例如： $dsn = 'pgsql:host=localhost;port=5432;dbname=database_name';
         * 使用parse_url方法解析dsn，并将解析后的关联数组赋值给$dsn，对于严重不合格的URL，将返回false
         * 下面会看到解析失败则报错退出
         */
        if (($dsn = @parse_url($params)) === FALSE)
        {
            show_error('Invalid DB Connection String');
        }
    
        $params = array(
            'dbdriver'	=> $dsn['scheme'],
            // 这里要注意rawurldecode()方法对已编码的URL字符串进行解码
            'hostname'	=> isset($dsn['host']) ? rawurldecode($dsn['host']) : '',
            'port'		=> isset($dsn['port']) ? rawurldecode($dsn['port']) : '',
            'username'	=> isset($dsn['user']) ? rawurldecode($dsn['user']) : '',
            'password'	=> isset($dsn['pass']) ? rawurldecode($dsn['pass']) : '',
            'database'	=> isset($dsn['path']) ? rawurldecode(substr($dsn['path'], 1)) : ''
        );
    
        // 解析问号？之后的参数，如get请求后跟的参数
        if (isset($dsn['query']))
        {
            parse_str($dsn['query'], $extra);
    
            foreach ($extra as $key => $val)
            {
                if (is_string($val) && in_array(strtoupper($val), array('TRUE', 'FALSE', 'NULL')))
                {
                    $val = var_export($val, TRUE);
                }
    
                $params[$key] = $val;
            }
        }
    }
    
    // 没有指定数据库报错退出
    if (empty($params['dbdriver']))
    {
        show_error('You have not selected a database type to connect to.');
    }
    
    // $query_builder表示是否加载数据库构造类，一般从database.php定义好，不过可以动态的改变，
    // 比如这里通过$query_builder_override的值来覆盖
    if ($query_builder_override !== NULL)
    {
        $query_builder = $query_builder_override;
    }
    // $active_record变量在CodeIgniter2版本中设置，CodeIgniter3中删除了，这里做兼容处理
    elseif ( ! isset($query_builder) && isset($active_record))
    {
        $query_builder = $active_record;
    }
    
    // 重点： 加载DB_driver.php文件，这个文件是一个抽象类CI_DB_driver
    // 定义了数据库的连接、选择、字符集设置、sql语句执行...一个基本的方法。
    require_once(BASEPATH.'database/DB_driver.php');
    
    if ( ! isset($query_builder) OR $query_builder === TRUE)
    {
        // 如果需要加载数据库构造类则加载BASEPATH.'database/DB_query_builer.php'文件
        // 该文件定义了一个抽象类CI_DB_query_builder，继承自CI_DB_driver
        // 查询构造类增加了查询有关的条件方法，使用起来灰常方便
        // 详情参考官网: https://codeigniter.org.cn/user_guide/database/query_builder.html
        require_once(BASEPATH.'database/DB_query_builder.php');
        if ( ! class_exists('CI_DB', FALSE))
        {
            // 这里很明确了，如果加载查询构造类，则CI_DB继承CI_DB_query_builder
            class CI_DB extends CI_DB_query_builder { }
        }
    }
    elseif ( ! class_exists('CI_DB', FALSE))
    {
        // 如果不加载查询构造类则直接继承CI_DB_driver
        class CI_DB extends CI_DB_driver { }
    }
    
    // 根据配置信息加载对应的driver文件，比如BASEPATH . 'database/drivers/mysqli/mysqli_driver.php'文件
    // 该文件继承自CI_DB，具体实现了数据库的连接、选择、字符集设置、事务相关操作等等重要方法，
    // 因为每种数据库的这些方法不一样需要具体数据库具体设置
    $driver_file = BASEPATH.'database/drivers/'.$params['dbdriver'].'/'.$params['dbdriver'].'_driver.php';
    
    file_exists($driver_file) OR show_error('Invalid DB driver'); // 每种driver文件只能加载一次，重复加载则报错退出
    require_once($driver_file);
    
    // 实例化DB适配器
    $driver = 'CI_DB_'.$params['dbdriver'].'_driver';
    $DB = new $driver($params);
    
    // 如果存在subdrivers目录则加载subdrivers目录下的driver文件，比如pdo_mysql_driver.php文件
    if ( ! empty($DB->subdriver))
    {
        $driver_file = BASEPATH.'database/drivers/'.$DB->dbdriver.'/subdrivers/'.$DB->dbdriver.'_'.$DB->subdriver.'_driver.php';
    
        if (file_exists($driver_file))
        {
            require_once($driver_file);
            $driver = 'CI_DB_'.$DB->dbdriver.'_'.$DB->subdriver.'_driver';
            $DB = new $driver($params);
        }
    }
    
    // 重要： 初始化函数完成了数据库的连接和字符集的设置
    $DB->initialize();
    return $DB;
}
```
从代码中得知，**首**先通过`require_once(BASEPATH.'database/DB_driver.php');`语句加载了抽象类`CI_DB_driver`，该类中定义了数据库连接、选择、字符集设置、sql语句执行等基本方法，这些方法在数据库适配类中完整实现。**然**后如果加载查询构造器则通过`require_once(BASEPATH.'database/DB_query_builder.php');`语句加载`CI_DB_query_builder`抽象类，该类继承`CI_DB_driver`并定义了查询有关的方法，使用起来非常方便，**然**后根据是否加载查询构造器来定义`CI_DB`，**最**后实例化`CI_DB`。

如果加载了查询构造器就可以使用`$this->db->select()->where()->like()`等方法了，这是因为查询构造器中定义了这类方法。下面再来看看另一个常用数据库类`dbforge`。

---

#### 数据库工厂类 ####

在migrate文件中经常会用的`dbforge`，该类默认在迁移类(`CI_Migration`)中加载，用来对数据表做一些操作，这里的`dbforge`即[数据库工厂类](https://codeigniter.org.cn/user_guide/database/forge.html#id1)，该类主要完成一下功能：
- 创建和删除数据库
- 创建和删除数据表，包括添加字段、添加键、创建表、删除表、重命名表等
- 修改表，包括给表添加列、从表中删除列、修改表中的某个列等

下面来看代码实现：
```php
public function dbforge($db = NULL, $return = FALSE)
{
    $CI =& get_instance();
    if ( ! is_object($db) OR ! ($db instanceof CI_DB))
    {
        // 先要连接数据库才能后续操作
        class_exists('CI_DB', FALSE) OR $this->database();
        $db =& $CI->db;
    }

    // 加载BASEPATH . 'database/DB_forge.php'文件，即抽象类CI_DB_forge
    require_once(BASEPATH.'database/DB_forge.php');
    
    // 根据选择的数据库从适配器目录下加载对应的forge类，比如CI_DB_mysqli_forge类，该类继承自CI_DB_forge
    require_once(BASEPATH.'database/drivers/'.$db->dbdriver.'/'.$db->dbdriver.'_forge.php');

    if ( ! empty($db->subdriver))
    {
        // 例如pdo方式操作mysql，则要加载BASEPATH . 'database/drivers/pdo/subdrivers/pdo_mysql_forge.php'
        $driver_path = BASEPATH.'database/drivers/'.$db->dbdriver.'/subdrivers/'.$db->dbdriver.'_'.$db->subdriver.'_forge.php';
        if (file_exists($driver_path))
        {
            require_once($driver_path);
            $class = 'CI_DB_'.$db->dbdriver.'_'.$db->subdriver.'_forge';
        }
    }
    else
    {
        $class = 'CI_DB_'.$db->dbdriver.'_forge';
    }

    // 如果返回对象则返回CI_DB_mysqli_forge类的实例
    if ($return === TRUE)
    {
        return new $class($db);
    }

    // 否则将该实例加入超级对象$CI中
    $CI->dbforge = new $class($db);
    return $this;
}
```
当执行`$this->load->dbforge();`语句后就可以通过`$this->dbforge->...`来管理数据库了。

#### 数据库工具类 ####

数据库工具类暂时未用到，后续补上。
