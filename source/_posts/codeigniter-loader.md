---
title: CodeIgniter加载类文件Loader.php
date: 2020-02-17 08:43:36
tags:
- Php
- Codeigniter
categories:
- Web工作笔记
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
```php
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
```php
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
```php
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
```php
public function view($view, $vars = array(), $return = FALSE)
{
    return $this->_ci_load(array('_ci_view' => $view, '_ci_vars' => $this->_ci_prepare_view_vars($vars), '_ci_return' => $return));
}
```
加载视图。

---

#### file() ####
```php
public function file($path, $return = FALSE)
{
    return $this->_ci_load(array('_ci_path' => $path, '_ci_return' => $return));
}
```
加载文件。

---

#### vars() ####
```php
public function vars($vars, $val = '')
{
    // 确保参数为数组格式
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
```php
public function clear_vars()
{
    $this->_ci_cached_vars = array();
    return $this;
}
```
清空缓存的变量。

---

#### get_var() ####
```php
public function get_var($key)
{
    return isset($this->_ci_cached_vars[$key]) ? $this->_ci_cached_vars[$key] : NULL;
}
```
检查并获取某个变量。

---

#### get_vars() ####
```php
public function get_vars()
{
    return $this->_ci_cached_vars;
}
```
获取设置的变量。

---

####  helper() ####
```php
public function helper($helpers = array())
{
    is_array($helpers) OR $helpers = array($helpers);// 如果是单个传入这里就要构造成数组
    foreach ($helpers as &$helper)
    {
        $filename = basename($helper);// 获取文件名
        $filepath = ($filename === $helper) ? '' : substr($helper, 0, strlen($helper) - strlen($filename));// 文件名如果跟参数一致说明没有路径，不一致需要分割获取
        $filename = strtolower(preg_replace('#(_helper)?(\.php)?$#i', '', $filename)).'_helper';// 加后缀 _helper,比如 array_helper
        $helper   = $filepath.$filename;// 重组

        // 已经加载过则判断下一个
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
上面用到的php内置函数：
1. [basename: 返回路径中的文件名部分](https://www.php.net/manual/zh/function.basename.php)

---

#### helpers() ####
```php
public function helpers($helpers = array())
{
    return $this->helper($helpers);
}
```
作用跟helper方法一致。

---

#### language() ####
```php
// 加载language文件
public function language($files, $lang = '')
{
    get_instance()->lang->load($files, $lang);
    return $this;
}
```

---

#### config() ####
```php
public function config($file, $use_sections = FALSE, $fail_gracefully = FALSE)
{
    // 调的是CI_Config类中的load()方法
    return get_instance()->config->load($file, $use_sections, $fail_gracefully);
}
```

---

#### driver() ####
```php
public function driver($library, $params = NULL, $object_name = NULL)
{
    if (is_array($library))
    {
        foreach ($library as $key => $value)
        {
            if (is_int($key))
            {
                $this->driver($value, $params);
            }
            else
            {
                $this->driver($key, $params, $value);
            }
        }

        return $this;
    }
    elseif (empty($library))
    {
        return FALSE;
    }

    if ( ! class_exists('CI_Driver_Library', FALSE))
    {
        // We aren't instantiating an object here, just making the base class available
        // 加载/system/libraries/Driver.php，该文件内有俩类: CI_Driver_Library作为缓存类的基类、 CI_Driver作为Nosql(redis、memcached)的基类.
        // 这里没有实例化对象，只是require文件
        require BASEPATH.'libraries/Driver.php';
    }

    // We can save the loader some time since Drivers will *always* be in a subfolder,
    // and typically identically named to the library
    if ( ! strpos($library, '/'))
    {
        // /system/libraries/Cache/Cache.php
        $library = ucfirst($library).'/'.$library;
    }

    return $this->library($library, $params, $object_name);
}
```

---

#### add_package_path() ####
```php
public function add_package_path($path, $view_cascade = TRUE)
{
    $path = rtrim($path, '/').'/';
    // $path = 'G:\wamp\www\CodeIgniter_hmvc\application\third_party/MX/'

    // 将$path分别加入到_ci_library_paths/_ci_model_paths/_ci_helper_paths中
    // array_unshift()的作用是开头加入，后面foreach的时候也是先判断这个目录下有没有，因为自定义的文件通常继承core里的类
    array_unshift($this->_ci_library_paths, $path);
    array_unshift($this->_ci_model_paths, $path);
    array_unshift($this->_ci_helper_paths, $path);

    // 两个数组相加：如果键名为字符，且键名相同，数组相加会将最先出现的值作为结果
    $this->_ci_view_paths = array($path.'views/' => $view_cascade) + $this->_ci_view_paths;

    // Add config file path 加载MX_Config, 即(& get_instance())->config;
    $config =& $this->_ci_get_component('config');
    $config->_config_paths[] = $path;

    return $this;
}
```

---

#### get_package_paths() ####
```php
public function get_package_paths($include_base = FALSE)
{
    // 返回已加载的package paths
    return ($include_base === TRUE) ? $this->_ci_library_paths : $this->_ci_model_paths;
}
```

---

#### remove_package_path() ####
```php
public function remove_package_path($path = '')
{
    $config =& $this->_ci_get_component('config');// 配置类组件

    if ($path === '')
    {
        // _ci_(library/model/helper/view)_paths在开头移除元素
        // $config->_config_paths在末尾移除元素
        array_shift($this->_ci_library_paths);
        array_shift($this->_ci_model_paths);
        array_shift($this->_ci_helper_paths);
        array_shift($this->_ci_view_paths);
        array_pop($config->_config_paths);
    }
    else
    {
        $path = rtrim($path, '/').'/';
        foreach (array('_ci_library_paths', '_ci_model_paths', '_ci_helper_paths') as $var)
        {
            if (($key = array_search($path, $this->{$var})) !== FALSE)
            {
                unset($this->{$var}[$key]);
            }
        }

        if (isset($this->_ci_view_paths[$path.'views/']))
        {
            unset($this->_ci_view_paths[$path.'views/']);
        }

        if (($key = array_search($path, $config->_config_paths)) !== FALSE)
        {
            unset($config->_config_paths[$key]);
        }
    }

    // make sure the application default paths are still in the array
    $this->_ci_library_paths = array_unique(array_merge($this->_ci_library_paths, array(APPPATH, BASEPATH)));
    $this->_ci_helper_paths = array_unique(array_merge($this->_ci_helper_paths, array(APPPATH, BASEPATH)));
    $this->_ci_model_paths = array_unique(array_merge($this->_ci_model_paths, array(APPPATH)));
    $this->_ci_view_paths = array_merge($this->_ci_view_paths, array(APPPATH.'views/' => TRUE));
    $config->_config_paths = array_unique(array_merge($config->_config_paths, array(APPPATH)));

    return $this;
}
```

---

#### _ci_load() ####
```php
// view()、file()方法中调用
// view: array('_ci_view' => $view, '_ci_vars' => $this->_ci_prepare_view_vars($vars), '_ci_return' => $return)
// file: array('_ci_path' => $path, '_ci_return' => $return)
protected function _ci_load($_ci_data)
{
    // Set the default data variables
    foreach (array('_ci_view', '_ci_vars', '_ci_path', '_ci_return') as $_ci_val)
    {
        $$_ci_val = isset($_ci_data[$_ci_val]) ? $_ci_data[$_ci_val] : FALSE;
    }

    $file_exists = FALSE;

    // Set the path to the requested file
    if (is_string($_ci_path) && $_ci_path !== '')
    {
        $_ci_x = explode('/', $_ci_path);
        $_ci_file = end($_ci_x);// $_ci_x中最后一个元素是文件名
    }
    else
    {
        $_ci_ext = pathinfo($_ci_view, PATHINFO_EXTENSION);// 返回文件名，带有扩展名
        $_ci_file = ($_ci_ext === '') ? $_ci_view.'.php' : $_ci_view;

        foreach ($this->_ci_view_paths as $_ci_view_file => $cascade)
        {
            if (file_exists($_ci_view_file.$_ci_file))
            {
                $_ci_path = $_ci_view_file.$_ci_file;
                $file_exists = TRUE;
                break;
            }

            if ( ! $cascade)
            {
                break;
            }
        }
    }

    if ( ! $file_exists && ! file_exists($_ci_path))
    {
        show_error('Unable to load the requested file: '.$_ci_file);
    }

    $_ci_CI =& get_instance();
    // get_object_vars：返回由对象属性组成的关联数组
    foreach (get_object_vars($_ci_CI) as $_ci_key => $_ci_var)
    {
        if ( ! isset($this->$_ci_key))
        {
            $this->$_ci_key =& $_ci_CI->$_ci_key;
        }
    }

    empty($_ci_vars) OR $this->_ci_cached_vars = array_merge($this->_ci_cached_vars, $_ci_vars);
    extract($this->_ci_cached_vars);// 从数组中将变量导入到当前的符号表
    
    //我们在控制器中调用$this->load->view()方法，
    //实质视图并没有马上输出来，而是先将它放到缓冲区。
    ob_start();
    //就是这个地方，下面if中有一句eval(xxxx)以及else中有include;而里面的xxxx正是我们要加载的视图文件，
    //所以这就是为什么在视图文件里，var_dump($this)，会告诉你当前这个$this是Loader组件，因为视图的代码都是相当于嵌入这个地方。
    // 从 PHP 5.4.0 起， <?= 总是可用的，但是小于php5.4需要替换
    if ( ! is_php('5.4') && ! ini_get('short_open_tag') && config_item('rewrite_short_tags') === TRUE)
    {
        // '<?='替换为'<? echo'， 去掉注释，将字符串作为php代码执行
        echo eval('?>'.preg_replace('/;*\s*\?>/', '; ?>', str_replace('<?=', '<?php echo ', file_get_contents($_ci_path))));
    }
    else
    {
        include($_ci_path); // include() vs include_once() allows for multiple views with the same name
    }
    // 经过上面的代码，我们的视图文件的内容已经放到了缓冲区了。
    log_message('info', 'File loaded: '.$_ci_path);

    //一般情况下，$_ci_return都为FLASE，即不要求通过$this->load->view()返回输出内容，而是直接放到缓冲区静候处理;
    //当然你也可以先拿出数据，在控制器里面处理一下，再输出，例如在控制器中$output=$this->load->view("x",$data,TRUE);，当为TRUE的时候，下面的代码就起作用了。
    if ($_ci_return === TRUE)
    {
        $buffer = ob_get_contents();
        @ob_end_clean();
        return $buffer;
    }
    /*
    * 下面这个很关键，因为有可能当前这个视图文件是被另一个视图文件通过$this->view()方法引入，
    * 即视图文件嵌入视图文件，从而导致多了一层缓冲。为了保证缓冲内容最后交给Output处理时，
    * 缓冲级别只比Loader组件加载时多1（这个1就是最父层的视图文件引起的）这里必须先flush掉当前层视图引起的这次缓冲，
    * 以保证Output正常工作。
     */
    if (ob_get_level() > $this->_ci_ob_level + 1)
    {
        ob_end_flush();
    }
    else
    {
        /* 
        * 如果不是多1，则说明当前引入的视图文件就是直接在控制器里面引入的那个，
        * 而不是由某个视图文件再引入的。把缓冲区的内容交给Output组件并清空关闭缓冲区。
        */
        $_ci_CI->output->append_output(ob_get_contents());
        @ob_end_clean();
    }

    return $this;
}
```
相关概念：
1. [short_open_tag](https://www.php.net/manual/zh/ini.core.php#ini.short-open-tag)
2. [ob_start](https://www.php.net/manual/zh/function.ob-start.php)
3. [extract](https://www.php.net/manual/zh/function.extract.php)
4. [eval](https://www.php.net/manual/zh/function.eval.php)

---

#### _ci_load_library() ####
```php
protected function _ci_load_library($class, $params = NULL, $object_name = NULL)
{
    // Get the class name, and while we're at it trim any slashes.
    // The directory path can be included as part of the class name,
    // but we don't want a leading slash
    // 若$class字符串中存在.php，去掉。。。
    $class = str_replace('.php', '', trim($class, '/'));

    // Was the path included with the class name?
    // We look for a slash to determine this
    // $class收尾去掉/后发现还有/就说明在子目录下了，这时要获取子目录
    if (($last_slash = strrpos($class, '/')) !== FALSE)
    {
        // Extract the path
        $subdir = substr($class, 0, ++$last_slash);

        // Get the filename from the path
        $class = substr($class, $last_slash);
    }
    else
    {
        $subdir = '';
    }

    // 类名首字符大写，这里再给格式化下
    $class = ucfirst($class);

    // Is this a stock library? There are a few special conditions if so ...
    // BASEPATH.'libraries/'.$subdir.$class.'.php' = 'G:\wamp\www\CodeIgniter_hmvc\system\libraries/My_class.php'
    if (file_exists(BASEPATH.'libraries/'.$subdir.$class.'.php'))
    {
        return $this->_ci_load_stock_library($class, $subdir, $params, $object_name);
    }

    // Safety: Was the class already loaded by a previous call?
    if (class_exists($class, FALSE))
    {
        // 这里$property是类的别名，可能由于源类名太长另外指定一个名称来表示，如果没有单独指定则由源类名表示 $this->{$property}->...
        $property = $object_name;
        if (empty($property))
        {
            $property = strtolower($class);
            isset($this->_ci_varmap[$property]) && $property = $this->_ci_varmap[$property];
        }

        $CI =& get_instance();
        if (isset($CI->$property))
        {
            log_message('debug', $class.' class already loaded. Second attempt ignored.');
            return;
        }

        return $this->_ci_init_library($class, '', $params, $object_name);
    }

    // Let's search for the requested library file and load it.
    foreach ($this->_ci_library_paths as $path)
    {
        // BASEPATH has already been checked for // if (file_exists(BASEPATH.'libraries/'.$subdir.$class.'.php'))...
        if ($path === BASEPATH)
        {
            continue;
        }

        $filepath = $path.'libraries/'.$subdir.$class.'.php';
        // Does the file exist? No? Bummer...
        if ( ! file_exists($filepath))
        {
            continue;
        }

        // $filepath = 'G:\wamp\www\CodeIgniter_hmvc\application\libraries/My_class.php'
        include_once($filepath);
        return $this->_ci_init_library($class, '', $params, $object_name);
    }

    // One last attempt. Maybe the library is in a subdirectory, but it wasn't specified? 最后的努力，当成子目录来尝试加载
    if ($subdir === '')
    {
        // $this->_ci_load_library('My_class/My_class', null, null); 其实前面就已经返回了，这个值是前面打印出来的。。。
        return $this->_ci_load_library($class.'/'.$class, $params, $object_name);
    }

    // If we got this far we were unable to find the requested class.
    log_message('error', 'Unable to load the requested class: '.$class);
    show_error('Unable to load the requested class: '.$class);
}
```

---

#### _ci_load_stock_library() ####
```php
protected function _ci_load_stock_library($library_name, $file_path, $params, $object_name)
{
    /**
     * 比如参数可能是：
     * $library_name = "Xmlrpc"
     * $file_path = ''
     * $params = [ 'xss_clean' => false, 'debug' => false]
     * $object_name = NULL
     */
    $prefix = 'CI_';

    if (class_exists($prefix.$library_name, FALSE))
    {
        // 若一定义MY_Xmlrpc类, 则加载此类
        if (class_exists(config_item('subclass_prefix').$library_name, FALSE))
        {
            $prefix = config_item('subclass_prefix');
        }

        $property = $object_name;
        if (empty($property))
        {
            $property = strtolower($library_name);
            isset($this->_ci_varmap[$property]) && $property = $this->_ci_varmap[$property];
        }

        $CI =& get_instance();
        if ( ! isset($CI->$property))
        {
            return $this->_ci_init_library($library_name, $prefix, $params, $object_name);
        }

        log_message('debug', $library_name.' class already loaded. Second attempt ignored.');
        return;
    }

    $paths = $this->_ci_library_paths;
    array_pop($paths); // BASEPATH
    array_pop($paths); // APPPATH (needs to be the first path checked)
    array_unshift($paths, APPPATH);

    foreach ($paths as $path)
    {
        if (file_exists($path = $path.'libraries/'.$file_path.$library_name.'.php'))
        {
            // Override
            include_once($path);
            if (class_exists($prefix.$library_name, FALSE))
            {
                return $this->_ci_init_library($library_name, $prefix, $params, $object_name);
            }

            log_message('debug', $path.' exists, but does not declare '.$prefix.$library_name);
        }
    }

    include_once(BASEPATH.'libraries/'.$file_path.$library_name.'.php');

    // Check for extensions
    $subclass = config_item('subclass_prefix').$library_name;
    foreach ($paths as $path)
    {
        if (file_exists($path = $path.'libraries/'.$file_path.$subclass.'.php'))
        {
            include_once($path);
            if (class_exists($subclass, FALSE))
            {
                $prefix = config_item('subclass_prefix');
                break;
            }

            log_message('debug', $path.' exists, but does not declare '.$subclass);
        }
    }

    return $this->_ci_init_library($library_name, $prefix, $params, $object_name);
}
```

---

#### _ci_init_library() ####
```php
protected function _ci_init_library($class, $prefix, $config = FALSE, $object_name = NULL)
{
    // Is there an associated config file for this class? Note: these should always be lowercase
    if ($config === NULL)
    {
        // Fetch the config paths containing any package paths
        $config_component = $this->_ci_get_component('config');// 返回的是MX_Config

        if (is_array($config_component->_config_paths))
        {
            $found = FALSE;
            foreach ($config_component->_config_paths as $path)
            {
                // We test for both uppercase and lowercase, for servers that
                // are case-sensitive with regard to file names. Load global first,
                // override with environment next
                /**
                 * 在config目录下寻找library...
                 * $path.'config/'.strtolower($class).'.php' = 'G:\wamp\www\CodeIgniter_hmvc\application\config/my_class.php';
                 * $path.'config/'.ucfirst(strtolower($class)).'.php' = 'G:\wamp\www\CodeIgniter_hmvc\application\config/My_class.php'
                 */
                if (file_exists($path.'config/'.strtolower($class).'.php'))
                {
                    include($path.'config/'.strtolower($class).'.php');
                    $found = TRUE;
                }
                elseif (file_exists($path.'config/'.ucfirst(strtolower($class)).'.php'))
                {
                    include($path.'config/'.ucfirst(strtolower($class)).'.php');
                    $found = TRUE;
                }

                if (file_exists($path.'config/'.ENVIRONMENT.'/'.strtolower($class).'.php'))
                {
                    include($path.'config/'.ENVIRONMENT.'/'.strtolower($class).'.php');
                    $found = TRUE;
                }
                elseif (file_exists($path.'config/'.ENVIRONMENT.'/'.ucfirst(strtolower($class)).'.php'))
                {
                    include($path.'config/'.ENVIRONMENT.'/'.ucfirst(strtolower($class)).'.php');
                    $found = TRUE;
                }

                // Break on the first found configuration, thus package
                // files are not overridden by default paths
                if ($found === TRUE)
                {
                    break;
                }
            }
        }
    }

    $class_name = $prefix.$class;

    // Is the class name valid?
    if ( ! class_exists($class_name, FALSE))
    {
        log_message('error', 'Non-existent class: '.$class_name);
        show_error('Non-existent class: '.$class_name);
    }

    // Set the variable name we will assign the class to
    // Was a custom class name supplied? If so we'll use it
    if (empty($object_name))
    {
        $object_name = strtolower($class);
        if (isset($this->_ci_varmap[$object_name]))
        {
            $object_name = $this->_ci_varmap[$object_name];
        }
    }

    // Don't overwrite existing properties
    $CI =& get_instance();
    if (isset($CI->$object_name))
    {
        if ($CI->$object_name instanceof $class_name)
        {
            log_message('debug', $class_name." has already been instantiated as '".$object_name."'. Second attempt aborted.");
            return;
        }

        show_error("Resource '".$object_name."' already exists and is not a ".$class_name." instance.");
    }

    // Save the class name and object name
    $this->_ci_classes[$object_name] = $class;

    // Instantiate the class 实例化类，这一步很关键，完成最后的加载， $CI->my_class = new My_class();
    $CI->$object_name = isset($config)
        ? new $class_name($config)
        : new $class_name();
}
```

---

#### _ci_autoloader() ####
```php
protected function _ci_autoloader()
{
    // include G:\wamp\www\CodeIgniter_hmvc\application\config/autoload.php
    if (file_exists(APPPATH.'config/autoload.php'))
    {
        include(APPPATH.'config/autoload.php');
    }

    // include G:\wamp\www\CodeIgniter_hmvc\application\config/development/autoload.php
    if (file_exists(APPPATH.'config/'.ENVIRONMENT.'/autoload.php'))
    {
        include(APPPATH.'config/'.ENVIRONMENT.'/autoload.php');
    }

    /**
     * 如果需要自动加载的文件，提前写入autoload.php,比如My_class.php
     * $autoload = [
     *      'packages' => [],
     *      'libraries' => [
     *          0 => string 'my_class' (length=8)
     *      ],
     *      'drivers' => [],
     *      'helper' => [],
     *      'config' => [],
     *      'language' => [],
     *      'model' => [],
     * ]
     */
    if ( ! isset($autoload))
    {
        return;
    }

    // Autoload packages
    /**
     * $autoload['packages'] = [
     *      0 => string 'G:\wamp\www\CodeIgniter_hmvc\application\third_party/MX' (length=55)
     * ]
     */
    if (isset($autoload['packages']))
    {
        foreach ($autoload['packages'] as $package_path)
        {
            $this->add_package_path($package_path);
        }
    }

    // Load any custom config file 加载autoload.php中配置的config文件，即$autoload['config'] = array('codeigniter');
    if (count($autoload['config']) > 0)
    {
        /**
         * $autoload['config'] = [
         *      0 => string 'codeigniter'
         * ]
         */
        foreach ($autoload['config'] as $val)
        {
            // $this->config('codeigniter');
            $this->config($val);
        }
    }

    // Autoload helpers and languages
    foreach (array('helper', 'language') as $type)
    {
        if (isset($autoload[$type]) && count($autoload[$type]) > 0)
        {
            /**
             * $autoload['helper'] = [
             *      0 => string 'array' (length=5)
             *      1 => string 'language' (length=8)
             * ]
             */
            $this->$type($autoload[$type]);
        }
    }

    // Autoload drivers
    if (isset($autoload['drivers']))
    {
        $this->driver($autoload['drivers']);
    }

    // Load libraries
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

    // Autoload models
    if (isset($autoload['model']))
    {
        $this->model($autoload['model']);
    }
}
```

---

#### _ci_prepare_view_vars() ####
```php
protected function _ci_prepare_view_vars($vars)
{
    if ( ! is_array($vars))
    {
        $vars = is_object($vars)
            ? get_object_vars($vars)
            : array();
    }

    foreach (array_keys($vars) as $key)
    {
        if (strncmp($key, '_ci_', 4) === 0)
        {
            unset($vars[$key]);
        }
    }

    return $vars;
}
```

---

#### _ci_get_component() ####
```php
protected function &_ci_get_component($component)
{
    $CI =& get_instance();
    return $CI->$component;
}
```

---

#### 参考链接 ####
[CI框架源码解析十六之加载器类文件Loader.php](https://blog.csdn.net/Zhihua_W/article/details/52956692)
