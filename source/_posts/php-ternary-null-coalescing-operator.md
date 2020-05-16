---
title: PHP的?:与??
date: 2020-05-16 19:05:05
tags:
- PHP
categories:
- 开发者手册
---

#### 引言 ####

适当的使用三元运算符`?:`和NULL合并运算符`??`可以替换不少`if ... else ...`。
<!-- more -->

---

#### 三元运算符 ####

表达式 (expr1) ? (expr2) : (expr3) 在 expr1 求值为 TRUE 时的值为 expr2，在 expr1 求值为 FALSE 时的值为 expr3。
```php
// Example usage for: Ternary Operator
$action = (empty($_POST['action'])) ? 'default' : $_POST['action'];

// The above is identical to this if/else statement
if (empty($_POST['action'])) {
    $action = 'default';
} else {
    $action = $_POST['action'];
}
```

<font color="#891717">自 PHP 5.3 起，可以省略三元运算符中间那部分。表达式 expr1 ?: expr3 在 expr1 求值为 TRUE 时返回 expr1，否则返回 expr3。</font>
```php
// 当$_POST['action']为null或''，则$action == 'default'
// 当$_POST['action'=不为空则$action == $_POST['action']
$action = $_POST['action'] ?: 'default'; 
```

<b><font color="#891717">Note: 注意三元运算符是个语句，因此其求值不是变量，而是语句的结果。如果想通过引用返回一个变量这点就很重要。在一个通过引用返回的函数中语句 `return $var == 42 ? $a : $b;` 将不起作用，以后的 PHP 版本会为此发出一条警告。</font></b>

---

#### NULL合并运算符 ####

PHP7开始支持NULL合并运算符`??`。当 expr1 为 NULL，表达式 (expr1) ?? (expr2) 等同于 expr2，否则为 expr1。
```php
// Example usage for: Null Coalesce Operator
$action = $_POST['action'] ?? 'default';

// The above is identical to this if/else statement
if (isset($_POST['action'])) {
    $action = $_POST['action'];
} else {
    $action = 'default';
}
```

<b><font color="#891717">Note: 请注意：NULL 合并运算符是一个表达式，产生的也是表达式结果，而不是变量。 返回引用变量时需要强调这一点。 因此，在返回引用的函数里就无法使用这样的语句: `return $foo ?? $bar;`，还会提示警告。</font></b>

---

#### 三元运算符和NULL合并运算符之间的区别 ####

- 三元运算符是`左关联`的；而NULL合并运算符是`右关联`的。
- 三元运算符检查值`是否为true`；而NULL合并运算符检查该值`是否为Null`。
- 如果要执行更多迭代，则发现`NULL合并`运算符比三元运算符`更快`。
- `NULL合并`运算符可以提供`更好的可读性`。

---

#### 参考链接 ####
[三元运算符](https://www.php.net/manual/zh/language.operators.comparison.php#language.operators.comparison.ternary)
[NULL合并运算符](https://www.php.net/manual/zh/language.operators.comparison.php#language.operators.comparison.coalesce)
[PHP中三元运算符和NULL合并运算符的简单比较](https://www.php.cn/php-weizijiaocheng-415006.html)
