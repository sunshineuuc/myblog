---
title: CodeIgniter-base-model使用文档
date: 2020-04-17 08:51:47
tags:
- PHP
- Codeigniter
categories:
- 开发者手册
---

#### 引言 ####

阮一峰先生在[《ORM实例教程》](http://www.ruanyifeng.com/blog/2019/02/orm-tutorial.html)一文中写到过`面向对象编程把所有实体看成对象（object），关系型数据库则是采用实体之间的关系（relation）连接数据。ORM 就是通过实例对象的语法，完成关系型数据库的操作的技术，是"对象-关系映射"（Object/Relational Mapping） 的缩写，ORM 把数据库映射成对象。`，CI针对数据库实现了`构造器类`用来进行CRUD操作，`工厂类`用来对数据表和字段进行增删改等操作。当对业务进行查询的时候通常通过构造器进行查询，即通过`$this->db->...`语句，这需要掌握查询构造器的诸多方法才能运用自如，最近发现一个CI的模型扩展，更简单的实现了ORM查询。
<!--- more -->
---

#### ORM与其他查询的区别 ####

```php
//正常SQL
$result = $this->db->query("select * from table_name")->result_array();
//查询构造器
$result = $this->db->get(table_name)->result_array();
//ORM
$result = $this->model->get_all();
```

#### 模型扩展介绍 ####

##### 下载地址 ##### 

[jamierumbelow/codeigniter-base-model](https://github.com/jamierumbelow/codeigniter-base-model)

##### 使用举例 #####

将`MY_model.php`文件放入放至`application/core`目录下，然后在`models`目录下创建`Blog_model.php`
```php
class Blog_model extends MY_model{

    //表示要操作的表，如果不设置则为blog，该扩展会获取类名，然后去掉'_m'或'_model'作为表名
    protected $_table = 'blog'; 
    
    //可以不写  默认当前库
    public $_database = '切换其他库'; 
    
    //可以不写 默认表主键
    protected $primary_key ='当前表查询primary_key'; 
    
    //下面开启 每个SQL都会拼接where 下面全部可以不写
    //where  deleted = 0;  //=1 修改$_temporary_only_deleted=true
    protected $soft_delete = true;
    protected $soft_delete_key = 'deleted';
    protected $_temporary_with_deleted = FALSE; //  0
    protected $_temporary_only_deleted = FALSE;  // 1
    
    //生命周期钩子 全部可以不写
    protected $before_create = array(); //数据创建之前
    protected $after_create = array();  //数据创建之后
    protected $before_update = array();  //数据更新之前
    protected $after_update = array();  //数据更新之后
    protected $before_get = array();  //数据获取之前
    protected $after_get = array(); //数据获取之后 存在值
    protected $before_delete = array(); //数据删除之前
    protected $after_delete = array(); //数据删除之后
    
    //比如 数据里面增加一个时间，然后增加条目之前就会调用该方法，这里在insert方法中触发了该钩子方法
    // public $before_create = array( 'timestamps' );
    protected function timestamps($blog){
        $blog['created_at'] = $blog['updated_at'] = date('Y-m-d H:i:s');
        return $blog;
    }
    
    //更新/新增 数据 删除数组中的key
    public $protected_attributes = array('id');
    
}
```

##### 控制器调用 #####

```php
$this->load->model('blog_model');
$list = $this->blog_model->get_all();// 获取blog表中所有记录
```

##### CRUD方法 #####

**获取数据**
```php
get($id)            // 通过主键获取一条记录
get_by($where)      // 过滤获取一条记录
get_many($where)    // 获取多条数据where in
get_many_by($where) // 获取多条数据 where and
get_all()           // 获取表全部数据
dropdown($field)    // 获取字段的一个数组集合
```

**插入数据**
```php
insert($data)      // 插入一条数据
insert_many($data) // 插入多少数据
```

**更新数据**
```php
update('10',$arr)            // 更新一条数据 $primary_key = 'id'; where id=10
update_many('11,12,13',$arr) // 更新多条数据 where in(11,12,13)
update_by($where,$data)  // 根据条件更新数据
update_all($data)        // 更新全部数据
```

**删除数据**
```php
delete($id)         // 根据主键删除一条数据
delete_by($where)   // 删除满足条件数据 ['title'=>'1111']
delete_many($where) // 删除主键数据 [1,2,3]
truncate()          // 清空表
```

**统计数据**
```php
count_by($where) // count(*) where
count_all()      // 统计全部数据
```

**排序**
```php
order_by(['id'=>'desc','title'=>'desc'])
order_by('id','desc')
```

**分页**
```php
limit($limit,$offset)
```

**分组**
```php
group_by($field)
```

#### 参考链接 ####

[codeigniter-base-model 中文文档](https://www.cnblogs.com/phper8/p/9802772.html)
[jamierumbelow/codeigniter-base-model](https://github.com/jamierumbelow/codeigniter-base-model)
