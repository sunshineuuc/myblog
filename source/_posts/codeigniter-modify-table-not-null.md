---
title: codeIgniter将字段类型改为null
date: 2019-11-27 10:11:12
tags:
- Php
- Codeigniter
categories:
- Web工作笔记
---

#### 问题 ####

因项目需要需要修改字段类型修改为支持null，因为codeigniter添加字段时如果不指定'null' => true，则默认是not null类型的，也就是不支持内容为null。当我使用`$this->dbforge->modify_column()`去修改的时候发现不起作用。

<!-- more -->

#### 解决方案 ####

去查手册modify_column()为啥不能将字段修改为`'null' => true`，手册没有说明：
```php
$fields = array(
    'old_name' => array(
        'name' => 'new_name',
        'type' => 'TEXT',
    ),
);
$this->dbforge->modify_column('table_name', $fields);
// gives ALTER TABLE table_name CHANGE old_name new_name TEXT
```
没有更多的说明了，下面说下我的解决方案：`先删除再添加`:
```php
<?php
/**
 * Created by PhpStorm.
 * User: pureven
 * Date: 2019/11/30
 * Time: 12:51
 */
defined('BASEPATH') or exit('No direct script access allowed');

class Migration_modify_users_table extends CI_Migration
{
    public function up()
    {
        if ($this->db->table_exists('users')) {
            $this->dbforge->drop_column('users', 'comment');
            $this->dbforge->add_column('users', [
                'comment' => [
                    'type' => 'text',
                    'null' => true,
                ],
            ]);
        }
    }

    public function down()
    {
    }
}
```
