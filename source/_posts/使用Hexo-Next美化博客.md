---
title: 使用Hexo-Next美化博客
date: 2019-11-04 19:55:40
tags: 
- Hexo
- Next
categories: 
- 前端
---

# 博客信息说明

** 指定站点名、作者以及站点描述 **
编辑根目录下_config.yml文件
```
# Site
title: Pureven Home
subtitle: ''
description: 不积跬步•无以至千里
keywords:
author: W E N C H A O
language: zh-CN
timezone: Asia/Shanghai
```
其中<code>title</code>表示站点标题，
<code>description</code>表示站点描述，
<code>author</code>表示站点主人，
<code>language</code>表示站点语言，这里通过themes/landscape/languages目录下的文件名来确认，这里使用中文即由<code>zh-CN</code>表示，<code>landscape</code>表示默认主题
<code>timezone</code>表示站点时区，默认为当前电脑所在时区，可参考[时区列表](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)自行设定

** 安装Next主题 **
站点根目录下执行命令<code>git clone https://github.com/theme-next/hexo-theme-next themes/next</code>进行安装

** 配置Next主题 **
编辑<code>themes/next/</code>目录下<code>_config.yml</code>文件，查找<code>scheme</code>,会发现有四种不同的<scheme>
```
# Schemes
scheme: Muse
#scheme: Mist
#scheme: Pisces
#scheme: Gemini
```
这里注释掉<code>Muse</code>,启用Gemini,即博客现在使用的主题。

** 首页、分类、归档、标签设置 **
1.编辑<code>themes/next/</code>目录下<code>_config.yml</code>文件，查找<code>menu</code>,
```
menu:
  home: / || home
  #about: /about/ || user
  tags: /tags/ || tags
  categories: /categories/ || th
  archives: /archives/ || archive
  #schedule: /schedule/ || calendar
  #sitemap: /sitemap.xml || sitemap
  #commonweal: /404/ || heartbeat
```
<code>home</code>表示首页，<code>tags</code>表示标签，<code>categories</code>表示分类，<code>archives</code>表示归档
去掉前面的<code>#</code>即使用对应的功能，其中<code>||</code>之前的值是目标链接，之后的是分类页面的图标，图标名称来自于FontAwesome icon。若没有配置图标，默认会使用问号图标。

2.hexo根目录下执行命令<code>hexo new page "categories"</code>,之后会在source文件夹中生成一个categories文件夹，里面有一个<code>index.md</code>文件，编辑此文件：
``` 
title: categories
date: 2019-11-03 07:43:34
type: "categories"
```
设置<code>type</code>为<code>"categories"</code>,<code>tags</code>,<code>archives</code>配置类似。

** 设置站点创建时间 **
打开next主题目录下<code>_config.yml</code>,查找<code>since</code>
```
footer:
  # Specify the date when the site was setup. If not defined, current year will be used.
  since: 2019
```
去掉<code>since</code>前的注释，如果不设置则显示当前年份。

** 设置头像 **
打开next主题目录下<code>_config.yml</code>,查找<code>avatar</code>
```
# Sidebar Avatar
avatar:
  # Replace the default image and set the url here.
  url: /images/avatar.png
  # If true, the avatar would be dispalyed in circle.
  rounded: true
  # If true, the avatar would be rotated with the cursor.
  rotated: true
```
<code>url</code>表示图片位置，
若将图片放置<code>themes/next/source/images/</code>下，则url为/images/avater.png
若将图片放置hexo跟目录下的<code>source/uploads</code>目录下则url为<code>/uploads/avater.png</code>
<code>rounded</code>为true表示头像显示为圆形
<code>rotated</code>为true表示鼠标移动到头像时否可旋转

** 网站图标 **
1.制作网站图标，参考图标素材网站：[iconfont](https://www.iconfont.cn/),[easyicon](https://www.easyicon.net/)
2.打开next主题目录下<code>_config.yml</code>,查找<code>favicon</code>
```
favicon:
  small: /images/avater_16px_16px.ico
  medium: /images/avater_32px_32px.ico
  apple_touch_icon: /images/apple-touch-icon-next.png
```
修改small和medium的路径为下载的图标路径
