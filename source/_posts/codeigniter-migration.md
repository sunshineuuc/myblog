---
title: CodeIgniter迁移类文件Migration.php
date: 2020-03-15 14:33:32
tags:
- Php
- Codeigniter
categories:
- Web工作笔记
---

#### 引言 ####
使用迁移类可以很方便的组织和管理数据库的变更，该类包含8个成员变量和11个成员方法。
<!-- more -->

---

#### 成员变量 ####
```php
// 启用或禁用迁移，默认为禁用
protected $_migration_enabled = FALSE;
// 迁移文件的命名规则， 默认为'sequential'， 其实'timestamp'更常用一些
protected $_migration_type = 'sequential';
// 迁移目录所在位置，默认为APPPATH . 'migrations/'
protected $_migration_path = NULL;
// 当前数据库所使用的版本，默认0
protected $_migration_version = 0;
// 用于存储当前版本的数据库表名
protected $_migration_table = 'migrations';
// 启用或禁用自动迁移，默认不启用
protected $_migration_auto_latest = FALSE;
// migrate文件的正则匹配模式，有两种，'/^\d{14}_(\w+)$/'和'/^\d{3}_(\w+)$/'分别对应'timestamp'和'sequential'
protected $_migration_regex;
// 表示迁移过程中的错误信息
protected $_error_string = '';
```

---

#### __construct() ####
```php
public function __construct($config = array())
{
    // 如果不是CI_Migration类或者CI_Migration类的子类则退出，即只能在CI_Migration类及其子类加载该构造方法
    if ( ! in_array(get_class($this), array('CI_Migration', config_item('subclass_prefix').'Migration'), TRUE))
    {
        return;
    }

    // 可选参数$config用来覆盖成员变量的默认值
    foreach ($config as $key => $val)
    {
        $this->{'_'.$key} = $val;
    }

    log_message('info', 'Migrations Class Initialized');

    // 如果迁移功能处于禁用状态则报错退出
    if ($this->_migration_enabled !== TRUE)
    {
        show_error('Migrations has been loaded but is disabled or set up incorrectly.');
    }

    // 获取迁移文件路径，默认为APPPATH . 'migrations/'
    $this->_migration_path !== '' OR $this->_migration_path = APPPATH.'migrations/';

    // 迁移文件路径格式化
    $this->_migration_path = rtrim($this->_migration_path, '/').'/';

    // 加载BASEPATH . '/language/english/migration_lang.php'
    $this->lang->load('migration');

    // 加载数据库工厂类
    $this->load->dbforge();

    // 如果数据库中没有migrations表则报错退出
    if (empty($this->_migration_table))
    {
        show_error('Migrations configuration file (migration.php) must have "migration_table" set.');
    }

    // 根据迁移文件的命名规则来确定用哪种正则匹配模式
    $this->_migration_regex = ($this->_migration_type === 'timestamp')
        ? '/^\d{14}_(\w+)$/'
        : '/^\d{3}_(\w+)$/';

    // 如果迁移文件的命名规则既不是'sequential'也不是'timestamp'则报错退出
    if ( ! in_array($this->_migration_type, array('sequential', 'timestamp')))
    {
        show_error('An invalid migration numbering type was specified: '.$this->_migration_type);
    }

    // 如果migrations表不存在则创建
    if ( ! $this->db->table_exists($this->_migration_table))
    {
        // 一般来说，在调用 create_table() 方法的后面使用 $this->dbforge->add_field($fields); 方法来添加字段
        $this->dbforge->add_field(array(
            'version' => array('type' => 'BIGINT', 'constraint' => 20),
        ));

        $this->dbforge->create_table($this->_migration_table, TRUE);

        $this->db->insert($this->_migration_table, array('version' => 0));
    }

    // 如果启用了自动迁移，但是发现当前并不是最新版本则报错退出
    if ($this->_migration_auto_latest === TRUE && ! $this->latest())
    {
        show_error($this->error_string());
    }
}
```

---

#### version() ####
```php
public function version($target_version)
{
    // 获取当前版本
    $current_version = $this->_get_version();

    // 格式化目标版本
    if ($this->_migration_type === 'sequential')
    {
        $target_version = sprintf('%03d', $target_version);
    }
    else
    {
        $target_version = (string) $target_version;
    }

    // 返回 migration_path 目录下的所有迁移文件的数组
    $migrations = $this->find_migrations();

    // 指定的版本并没有在迁移文件数组中则报错退出
    if ($target_version > 0 && ! isset($migrations[$target_version]))
    {
        $this->_error_string = sprintf($this->lang->line('migration_not_found'), $target_version);
        return FALSE;
    }

    if ($target_version > $current_version)
    {
        // 指定的目标版本大于当前版本说明要做升级
        $method = 'up';
    }
    elseif ($target_version < $current_version)
    {
        // 小于当前版本说明要做回退
        $method = 'down';
        // 这里按照键名逆向排序， 这里排完序后便于回退处理
        krsort($migrations);
    }
    else
    {
        // 相等则说明不用迁移了
        return TRUE;
    }

    // 用来存放要迁移的migrate文件
    $pending = array();
    foreach ($migrations as $number => $file)
    {
        if ($method === 'up')
        {
            // 这里要做升级，当$number小于等于当前版本时继续下次循环，大于指定版本时退出，也就是说大于当前版本小于指定版本的$number继续下面的流程
            if ($number <= $current_version)
            {
                continue;
            }
            elseif ($number > $target_version)
            {
                break;
            }
        }
        else
        {
            // 这里要做回退，当$number大于当前版本时继续下次循环，小于等于指定版本时退出，也就是说小于当前版本大于指定版本的$number继续下面的流程
            if ($number > $current_version)
            {
                continue;
            }
            elseif ($number <= $target_version)
            {
                break;
            }
        }


        if ($this->_migration_type === 'sequential')
        {
            // 每个迁移文件以数字序列格式递增命名，从 001 开始，每个数字都需要占三位，序列之间不能有间隙。
            if (isset($previous) && abs($number - $previous) > 1)
            {
                $this->_error_string = sprintf($this->lang->line('migration_sequence_gap'), $number);
                return FALSE;
            }

            // 记录当前序列号，跟下次比较时使用
            $previous = $number;
        }

        // 加载migrate文件
        include_once($file);
        
        // migrate文件跟类名不一致： 20200315195100_add_user_table ==> Migration_add_user_table
        // 这里$class = Migration_Add_user_table，解释了为什么创建migrate文件时要把Migrate改成时间戳或序列号了
        $class = 'Migration_'.ucfirst(strtolower($this->_get_migration_name(basename($file, '.php'))));

        // 不区分大小写，就上面的例子来说所以Migration_add_user_table也能匹配到
        // 如果匹配不到说明加载的migrate文件不包括指定的类，报错退出
        if ( ! class_exists($class, FALSE))
        {
            $this->_error_string = sprintf($this->lang->line('migration_class_doesnt_exist'), $class);
            return FALSE;
        }
        elseif ( ! is_callable(array($class, $method)))
        {
            // 类存在了，但是没有升级(up)或回退(down)对应的方法也要报错
            $this->_error_string = sprintf($this->lang->line('migration_missing_'.$method.'_method'), $class);
            return FALSE;
        }

        // 如果符合条件，将migrate文件加入到$pending数组中
        $pending[$number] = array($class, $method);
    }

    // 遍历执行符合条件的migrate文件
    foreach ($pending as $number => $migration)
    {
        log_message('debug', 'Migrating '.$method.' from version '.$current_version.' to version '.$number);

        // migration数组首元素时类名，这里改成实际的对象然后调用call_user_func()来执行就ok了
        $migration[0] = new $migration[0];
        call_user_func($migration);
        
        执行完成后$number即当前版本了，更新到数据库
        $current_version = $number;
        $this->_update_version($current_version);
    }

    // 执行完成后发现当前版本跟指定版本不一致，再次更新数据库，将migrate版本号设置为指定版本
    if ($current_version <> $target_version)
    {
        $current_version = $target_version;
        $this->_update_version($current_version);
    }

    log_message('debug', 'Finished migrating to '.$current_version);
    return $current_version;
}
```
迁移(`升级或回退`)到指定版本。

---

#### latest() ####
```php
public function latest()
{
    $migrations = $this->find_migrations();

    if (empty($migrations))
    {
        $this->_error_string = $this->lang->line('migration_none_found');
        return FALSE;
    }

    // 获取migrations最后一个元素，也就是最新版本migrate文件
    $last_migration = basename(end($migrations));

    // 升级到最新版本
    return $this->version($this->_get_migration_number($last_migration));
}
```

---

#### current() ####
```php
public function current()
{
    return $this->version($this->_migration_version);
}
```
升级到指定版本，默认0，可以在配置文件中指定具体版本来覆盖默认版本即可。

---

#### error_string() ####
```php
public function error_string()
{
    return $this->_error_string;
}
```
返回错误信息。

---

#### find_migrations() ####
```php
public function find_migrations()
{
    $migrations = array();

    // globglob — 寻找与模式(*_*.php)匹配的文件路径
    foreach (glob($this->_migration_path.'*_*.php') as $file)
    {
        $name = basename($file, '.php');

        // 拿到文件之后使用migrate文件的正则匹配模式过滤文件
        if (preg_match($this->_migration_regex, $name))
        {
            // 拿到migrate文件的序列号或时间戳
            $number = $this->_get_migration_number($name);

            // 时间戳或序列号不能重复，否则报错退出
            if (isset($migrations[$number]))
            {
                $this->_error_string = sprintf($this->lang->line('migration_multiple_version'), $number);
                show_error($this->_error_string);
            }

            // 将过滤后的文件放入$migration数组中，将时间戳或序列号作为key
            $migrations[$number] = $file;
        }
    }

    // 根据key值排序-顺序排序
    ksort($migrations);
    return $migrations;
}
```

---

####  _get_migration_number() ####
```php
protected function _get_migration_number($migration)
{
    return sscanf($migration, '%[0-9]+', $number)
        ? $number : '0';
}
```
从migrate文件名中拿到数字部分。

---

#### _get_migration_name() ####
```php
protected function _get_migration_name($migration)
{
    $parts = explode('_', $migration);
    array_shift($parts);
    return implode('_', $parts);
}
```
从migrate文件名中去掉数字部分。

---

#### _get_version() ####
```php
protected function _get_version()
{
    $row = $this->db->select('version')->get($this->_migration_table)->row();
    return $row ? $row->version : '0';
}
```
获取数据库中保存的版本号，即当前版本。

---

#### _update_version() ####
```php
protected function _update_version($migration)
{
    $this->db->update($this->_migration_table, array(
        'version' => $migration
    ));
}
```
将指定版本更新到数据库中。

---

#### __get() ####
```php
public function __get($var)
{
    return get_instance()->$var;
}
```
魔术方法，用于使用超级对象CI。
