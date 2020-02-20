---
title: CodeIgniter加载类文件Loader.php
date: 2020-02-17 08:43:36
tags:
- php
- codeigniter
categories:
- web工作笔记
---

#### 引言 ####
加载类在控制器基类中引入并完成初始化，主要负责对package、library、view、driver、helper、model、config等文件的加载。在配置文件中可以设置自动加载，当然也可以在具体业务实现过程中手动加载需要的文件。
<!--more-->

---

#### 成员变量 ####
```php
protected $_ci_ob_level; // 缓冲机制的嵌套级别
protected $_ci_view_paths =	array(VIEWPATH	=> TRUE); // 待加载视图文件路径
protected $_ci_library_paths =	array(APPPATH, BASEPATH); // 待加载类库文件路径
protected $_ci_model_paths =	array(APPPATH);  // 待加载模型文件路径
protected $_ci_helper_paths =	array(APPPATH, BASEPATH); // 待加载帮助文件路径
protected $_ci_cached_vars =	array(); // 待加载缓存文件路径
protected $_ci_classes =	array(); // 用于保存已加载的类
protected $_ci_models =	array(); // 用于保存已加载的模型
protected $_ci_helpers =	array(); // 用于保存已加载的帮助文件
protected $_ci_varmap =	array( // 类的别名映射，名字太长的映射个短点儿的
    'unit_test' => 'unit',
    'user_agent' => 'agent'
);
```

---

#### __construct() ####
```php
public function __construct()
{
    // ob_get_level(): 输出缓冲机制的嵌套级别
    $this->_ci_ob_level = ob_get_level();

    // is_loaded(): 返回已加载的类，此处完成交接，此处_ci_classes也用来保管
    $this->_ci_classes =& is_loaded();

    log_message('info', 'Loader Class Initialized');
}
```

---

#### initialize() ####
```php
public function initialize()
{
    $this->_ci_autoloader();
}
```
该方法在控制器基类中调用，用于初始化加载类，根据配置的自动加载文件进行完成自动加载。

---

#### is_loaded() ####
```php
public function is_loaded($class)
{
    // 若加载了返回类名或者指定的名称，未加载则返回false
    return array_search(ucfirst($class), $this->_ci_classes, TRUE);
}
```

---

#### library() ####
```php
public function library($library, $params = NULL, $object_name = NULL)
{
    if (empty($library))
    {
        return $this;
    }
    elseif (is_array($library))
    { // 支持数组形式同时加载多个类库：$this->load->library(['test', 'database']);
        foreach ($library as $key => $value)
        {
            if (is_int($key))
            {
                $this->library($value, $params);
            }
            else
            {
                $this->library($key, $params, $value);
            }
        }

        return $this;
    }

    if ($params !== NULL && ! is_array($params))
    {
        $params = NULL;
    }

    $this->_ci_load_library($library, $params, $object_name);
    return $this;
}
```
当执行`$this->load->library('xxx');`时走的这个方法。

---

#### model() ####
```php
public function model($model, $name = '', $db_conn = FALSE)
{
    if (empty($model))
    {
        return $this;
    }
    elseif (is_array($model))
    { // 可以同时加载多个model
        foreach ($model as $key => $value)
        {
            is_int($key) ? $this->model($value, '', $db_conn) : $this->model($key, $value, $db_conn);
        }

        return $this;
    }

    $path = '';

    // 如果加载的model字符串中有子目录
    // 如:$this->load->model('user/base_model')表示加载的是user目录下的Base_model.php
    if (($last_slash = strrpos($model, '/')) !== FALSE)
    {
        // $last_slash为'/'最后一次出现的位置，$path即去掉文件名剩下的路径信息
        $path = substr($model, 0, ++$last_slash);

        // $model为文件名
        $model = substr($model, $last_slash);
    }

    // 有时候model文件名会很长，因此会映射一个简短的名称，也就是这里的$name
    // 比如： $this->load->model('hello_world_I_am_comming_model', 'hello_model');
    // 然后执行$this->hello_model->xxx()去调用其中的方法就ok了。
    // 如果不指定则使用$model，即'hello_world_I_am_comming_model'。
    if (empty($name))
    {
        $name = $model;
    }

    if (in_array($name, $this->_ci_models, TRUE))
    {
        return $this;
    }

    // 重复加载会抛出异常
    $CI =& get_instance();
    if (isset($CI->$name))
    {
        throw new RuntimeException('The model name you are loading is the name of a resource that is already being used: '.$name);
    }

    // 如果要求同时连接数据库则调用$this->database()加载数据库
    if ($db_conn !== FALSE && ! class_exists('CI_DB', FALSE))
    {
        if ($db_conn === TRUE)
        {
            $db_conn = '';
        }

        $this->database($db_conn, FALSE, TRUE);
    }

    if ( ! class_exists('CI_Model', FALSE))
    {
        // application目录下如果存在Model.php则加载此文件，这个文件代替system目录下的同名文件作为基类，因此类名为CI_Model
        $app_path = APPPATH.'core'.DIRECTORY_SEPARATOR;
        if (file_exists($app_path.'Model.php'))
        {
            require_once($app_path.'Model.php');
            // 如果加载后发现该文件类名不为CI_Model.php则报错
            if ( ! class_exists('CI_Model', FALSE))
            {
                throw new RuntimeException($app_path."Model.php exists, but doesn't declare class CI_Model");
            }

            log_message('info', 'CI_Model class loaded');
        }
        elseif ( ! class_exists('CI_Model', FALSE))
        {
            require_once(BASEPATH.'core'.DIRECTORY_SEPARATOR.'Model.php');
        }

         // 加载子类
        $class = config_item('subclass_prefix').'Model';
        if (file_exists($app_path.$class.'.php'))
        {
            require_once($app_path.$class.'.php');
            // 子类名与文件名不一致则抛出异常
            if ( ! class_exists($class, FALSE))
            {
                throw new RuntimeException($app_path.$class.".php exists, but doesn't declare class ".$class);
            }

            log_message('info', config_item('subclass_prefix').'Model class loaded');
        }
    }

    $model = ucfirst($model);
    if ( ! class_exists($model, FALSE))
    {
        foreach ($this->_ci_model_paths as $mod_path)
        {
            if ( ! file_exists($mod_path.'models/'.$path.$model.'.php'))
            {
                continue;
            }
            // 注意这里是'models/'.$path.$model.'.php'，子目录用在这。
            require_once($mod_path.'models/'.$path.$model.'.php');
            // 加载了但是类名不存在则抛出异常
            if ( ! class_exists($model, FALSE))
            {
                throw new RuntimeException($mod_path."models/".$path.$model.".php exists, but doesn't declare class ".$model);
            }

            break;
        }
        // 加了一遍发现类名不存在则抛出异常
        if ( ! class_exists($model, FALSE))
        {
            throw new RuntimeException('Unable to locate the model you have specified: '.$model);
        }
    }
    elseif ( ! is_subclass_of($model, 'CI_Model'))
    {
        // 如果该类存在但是不是CI_Model的子类则抛出异常
        throw new RuntimeException("Class ".$model." already exists and doesn't extend CI_Model");
    }
    
    // 加载完了将$name，也就是映射后的名称放入'_ci_models'
    $this->_ci_models[] = $name;
    $model = new $model();
    $CI->$name = $model; // 这里完成映射
    log_message('info', 'Model "'.get_class($model).'" initialized');
    return $this;
}
```

---

#### database() ####
```text
public function database($params = '', $return = FALSE, $query_builder = NULL)
{
    // Grab the super object
    $CI =& get_instance();

    // 已经加载了就不重复加载了
    if ($return === FALSE && $query_builder === NULL && isset($CI->db) && is_object($CI->db) && ! empty($CI->db->conn_id))
    {
        return FALSE;
    }

    require_once(BASEPATH.'database/DB.php');

    if ($return === TRUE)
    {
        // 这里DB是个方法
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

---

#### dbutil() ####
```text
public function dbutil($db = NULL, $return = FALSE)
{
    $CI =& get_instance();

    if ( ! is_object($db) OR ! ($db instanceof CI_DB))
    {
        class_exists('CI_DB', FALSE) OR $this->database();// 没有参数，这里加载的是数据库工具类
        $db =& $CI->db;
    }

    require_once(BASEPATH.'database/DB_utility.php');// dbdriver为mssql mysql postgre pdo ...
    require_once(BASEPATH.'database/drivers/'.$db->dbdriver.'/'.$db->dbdriver.'_utility.php');
    $class = 'CI_DB_'.$db->dbdriver.'_utility';

    if ($return === TRUE)
    {
        return new $class($db);
    }

    $CI->dbutil = new $class($db);
    return $this;
}
```

---

#### dbforge() ####
```text
public function dbforge($db = NULL, $return = FALSE)
{
    $CI =& get_instance();
    if ( ! is_object($db) OR ! ($db instanceof CI_DB))
    {
        class_exists('CI_DB', FALSE) OR $this->database();
        $db =& $CI->db;
    }

    require_once(BASEPATH.'database/DB_forge.php');
    require_once(BASEPATH.'database/drivers/'.$db->dbdriver.'/'.$db->dbdriver.'_forge.php');

    if ( ! empty($db->subdriver))
    {
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

    if ($return === TRUE)
    {
        return new $class($db);
    }

    $CI->dbforge = new $class($db);
    return $this;
}
```
加载数据库锻造类。

---

#### view() ####
```text
public function view($view, $vars = array(), $return = FALSE)
{
    return $this->_ci_load(array('_ci_view' => $view, '_ci_vars' => $this->_ci_prepare_view_vars($vars), '_ci_return' => $return));
}
```
加载视图。

---

#### file() ####
```text
public function file($path, $return = FALSE)
{
    return $this->_ci_load(array('_ci_path' => $path, '_ci_return' => $return));
}
```
加载文件。

---

#### vars() ####
```text
public function vars($vars, $val = '')
{
    $vars = is_string($vars)
        ? array($vars => $val)
        : $this->_ci_prepare_view_vars($vars);

    foreach ($vars as $key => $val)
    {
        $this->_ci_cached_vars[$key] = $val;
    }

    return $this;
}
```
设置变量。

---

#### clear_vars() ####
```text
public function clear_vars()
{
    $this->_ci_cached_vars = array();
    return $this;
}
```
清空缓存的变量。

---

#### get_var() ####
```text
public function get_var($key)
{
    return isset($this->_ci_cached_vars[$key]) ? $this->_ci_cached_vars[$key] : NULL;
}
```
检查并获取某个变量。

---

#### get_vars() ####
```text
public function get_vars()
{
    return $this->_ci_cached_vars;
}
```
获取设置的变量。

---

####  helper() ####
```text
public function helper($helpers = array())
{
    is_array($helpers) OR $helpers = array($helpers);// 如果是单个传入这里就要构造成数组
    foreach ($helpers as &$helper)
    {
        $filename = basename($helper);
        $filepath = ($filename === $helper) ? '' : substr($helper, 0, strlen($helper) - strlen($filename));
        $filename = strtolower(preg_replace('#(_helper)?(\.php)?$#i', '', $filename)).'_helper';// 加后缀 _helper,比如 array_helper
        $helper   = $filepath.$filename;

        if (isset($this->_ci_helpers[$helper]))
        {
            continue;
        }

        // Is this a helper extension request?
        $ext_helper = config_item('subclass_prefix').$filename; // $ext_helper = 'MY_array_helper'
        $ext_loaded = FALSE;
        foreach ($this->_ci_helper_paths as $path)
        {
            if (file_exists($path.'helpers/'.$ext_helper.'.php'))
            {
                include_once($path.'helpers/'.$ext_helper.'.php');
                $ext_loaded = TRUE;
            }
        }

        // If we have loaded extensions - check if the base one is here
        // 这里的意思是如果MY_array_helper.php存在但是array_helper.php不存在则报错
        if ($ext_loaded === TRUE)
        {
            $base_helper = BASEPATH.'helpers/'.$helper.'.php';
            if ( ! file_exists($base_helper))
            {
                show_error('Unable to load the requested file: helpers/'.$helper.'.php');
            }

            include_once($base_helper);
            $this->_ci_helpers[$helper] = TRUE;
            log_message('info', 'Helper loaded: '.$helper);
            continue;
        }

        // No extensions found ... try loading regular helpers and/or overrides
        // 没找到MY_array_helper.php,则加载array_helper.php
        foreach ($this->_ci_helper_paths as $path)
        {
            if (file_exists($path.'helpers/'.$helper.'.php'))
            {
                include_once($path.'helpers/'.$helper.'.php');

                $this->_ci_helpers[$helper] = TRUE;
                log_message('info', 'Helper loaded: '.$helper);
                break;
            }
        }

        // unable to load the helper
        // 没加载成功则报错
        if ( ! isset($this->_ci_helpers[$helper]))
        {
            show_error('Unable to load the requested file: helpers/'.$helper.'.php');
        }
    }

    return $this;
}
```

---

####  ####
```text

```

---

####  ####
```text

```

---

####  ####
```text

```

---

####  ####
```text

```

---

####  ####
```text

```

---

####  ####
```text

```

---

####  ####
```text

```

---

####  ####
```text

```

---

####  ####
```text

```

---

####  ####
```text

```

---

####  ####
```text

```

---

####  ####
```text

```

---

####  ####
```text

```

---

#### 参考链接 ####
[CI框架源码解析十六之加载器类文件Loader.php](https://blog.csdn.net/Zhihua_W/article/details/52956692)
