---
title: 使用Hexo-Next美化博客
date: 2019-11-04 19:55:40
tags: 
- Hexo
- Next
categories: 
- web学习笔记
---

### 指定站点名、作者以及站点描述 ###
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

### 安装Next主题 ###
站点根目录下执行命令<code>git clone https://github.com/theme-next/hexo-theme-next themes/next</code>进行安装

<!-- more -->

### 配置Next主题 ###
编辑<code>themes/next/</code>目录下<code>_config.yml</code>文件，查找<code>scheme</code>,会发现有四种不同的<scheme>
```
# Schemes
scheme: Muse
#scheme: Mist
#scheme: Pisces
#scheme: Gemini
```
这里注释掉<code>Muse</code>,启用Gemini,即博客现在使用的主题。

### 首页、分类、归档、标签设置 ###
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

### 设置站点创建时间 ###
打开next主题目录下<code>_config.yml</code>,查找<code>since</code>
```
footer:
  # Specify the date when the site was setup. If not defined, current year will be used.
  since: 2019
```
去掉<code>since</code>前的注释，如果不设置则显示当前年份。

### 设置头像 ###
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

### 网站图标 ###
1.制作网站图标，参考图标素材网站：[iconfont](https://www.iconfont.cn/),[easyicon](https://www.easyicon.net/)
2.打开next主题目录下<code>_config.yml</code>,查找<code>favicon</code>
```
favicon:
  small: /images/avater_16px_16px.ico
  medium: /images/avater_32px_32px.ico
```
修改small和medium的路径为下载的图标路径

### 背景动画 ###
1.进入<code>theme/next</code>目录，执行命令<code>git clone https://github.com/theme-next/theme-next-three source/lib/three</code>
2.打开<code>theme/next/config.yml</code>文件,找到<code>theme-next-three</code>将<code>three_waves</code>设置为true即表示显示<code>three_waves</code>背景
```
# JavaScript 3D library.
# Dependencies: https://github.com/theme-next/theme-next-three
three:
  enable: true
  three_waves: true
  canvas_lines: false
  canvas_sphere: false
```

### 点击侧栏头像回到首页 ###
编辑<code>themes/next/layout/_partials/sidebar/site-overview.swig</code>文件，将<code>site-author-image</code>图片放入<code>链接</code>中,如：
```
<a href="/">
  <img class="site-author-image" itemprop="image" alt="{{ author }}"
    src="{{ url_for(theme.avatar.url or theme.images + '/avatar.gif') }}">
</a>
```


### 字体设置 ###
编辑<code>themes/next/_config.yml</code>文件，找到<code>font:</code>
```
font:
  enable: true
  host: https://fonts.loli.net
  global:
    external: true
    family: Noto Serif SC
    size: 1
```

### 新建文章时，在相同目录下创建同名文件夹 ###
1.编辑hexo根目录下<code>_config.yml</code>文件，找到<code>post_asset_folder</code>,设置其属性：
```
post_asset_folder: true
```
2.安装hexo-asset-image:<code>npm install hexo-asset-image --save</code>
3.编辑<code>node_modules/hexo-asset-image/index.js</code>文件，将内容替换为下面代码
```
'use strict';
var cheerio = require('cheerio');

// http://stackoverflow.com/questions/14480345/how-to-get-the-nth-occurrence-in-a-string
function getPosition(str, m, i) {
  return str.split(m, i).join(m).length;
}

var version = String(hexo.version).split('.');
hexo.extend.filter.register('after_post_render', function(data){
  var config = hexo.config;
  if(config.post_asset_folder){
    var link = data.permalink;
    if(version.length > 0 && Number(version[0]) == 3)
      var beginPos = getPosition(link, '/', 1) + 1;
    else
      var beginPos = getPosition(link, '/', 3) + 1;
    // In hexo 3.1.1, the permalink of "about" page is like ".../about/index.html".
    var endPos = link.lastIndexOf('/') + 1;
    link = link.substring(beginPos, endPos);

    var toprocess = ['excerpt', 'more', 'content'];
    for(var i = 0; i < toprocess.length; i++){
      var key = toprocess[i];

      var $ = cheerio.load(data[key], {
        ignoreWhitespace: false,
        xmlMode: false,
        lowerCaseTags: false,
        decodeEntities: false
      });

      $('img').each(function(){
        if ($(this).attr('src')){
          // For windows style path, we replace '\' to '/'.
          var src = $(this).attr('src').replace('\\', '/');
          if(!/http[s]*.*|\/\/.*/.test(src) &&
              !/^\s*\//.test(src)) {
            // For "about" page, the first part of "src" can't be removed.
            // In addition, to support multi-level local directory.
            var linkArray = link.split('/').filter(function(elem){
              return elem != '';
            });
            var srcArray = src.split('/').filter(function(elem){
              return elem != '' && elem != '.';
            });
            if(srcArray.length > 1)
              srcArray.shift();
            src = srcArray.join('/');
            $(this).attr('src', config.root + link + src);
            console.info&&console.info("update link as:-->"+config.root + link + src);
          }
        }else{
          console.info&&console.info("no src attr, skipped...");
          console.info&&console.info($(this));
        }
      });
      data[key] = $.html();
    }
  }
});
```
安装完成后，如果新建文章时就会在<code>/source/_posts</code>目录下创建同名文件夹，好处是将需要插入文章的图片放入同名目录下，在文章中只需使用`![](image_name.png)`即可插入成功

### 添加背景图片 ###
1. 编辑themes/next/_config.yml文件，找到<code>custom_file_path</code>，取消<code>style: source/_data/styles.styl</code>注释
2. 站点根目录下新建文件<code>source/_data/style.styl</code>，内容如下:
```text
body {
      background: url(https://source.unsplash.com/random/1600x900?wallpapers);//自己喜欢的图片地址
      background-size: cover;
      background-repeat: no-repeat;
      background-attachment: fixed;
      background-position: 50% 50%;
}

// 修改主体透明度
.main-inner {
      background: #fff;
      opacity: 0.8;
}

// 修改菜单栏透明度
.header-inner {
      opacity: 0.8;
}
```

### 首页文章摘要设置 ###
编辑<code>themes/next/_config.yml</code>文件，找到<code>excerpt</code>
```
excerpt_description: true
auto_excerpt:
  enable: true
  length: 150
```

### 閲讀全文按鈕設置弧度 ###
編輯<code>themes/next/source/css/_variables/Pisces.styl</code>將<code>$btn-default-radius</code>置爲16

### 文章浏览进度显示 ###
编辑<code>themes/next/_config.yml</code>文件，找到<code>back2top</code>
```
back2top:
  enable: true
  sidebar: true
  scrollpercent: true
```

### 文章代码块一键复制功能 ###
编辑<code>themes/next/_config.yml</code>文件，找到<code>codeblock</code>
```
codeblock:
  highlight_theme: normal
  copy_button:
    enable: true
    show_result: true
```

### 文章末尾版权声明设置 ###
编辑<code>themes/next/_config.yml</code>文件，找到<code>creative_commons</code>
```
creative_commons:
  license: by-nc-sa
  sidebar: false
  post: true
  language:
```

### 文章添加评论 ###
1.[注册Leancloud](https://leancloud.cn/dashboard/login.html#/signup)
2.注册完后添加应用app
3.进入应用app，点击设置在基本信息中你会发现<code>应用Keys</code>,点进去拿到<code>AppID</code>和<code>AppKey</code>
4.编辑<code>themes/next/_config.yml</code>文件，找到<code>valine</code>,将<code>enable</code>置为true，将保存的<code>AppID</code>和<code>AppKey</code>分别赋值给<code>appid</code>和<code>appkey</code>
5.进入Leancloud app应用的安全中心，将博客域名填入Web 安全域名，完工

### 本地搜索 ###
编辑<code>themes/next/_config.yml</code>文件，找到<code>local_search</code>
```
# Local Search
# Dependencies: https://github.com/theme-next/hexo-generator-searchdb
local_search:
  enable: true
```
注释说的很明白，此功能依赖hexo-generator-searchdb,执行<code>npm install hexo-generator-search</code>进行安装

### 鼠标点击♥形效果 ###
1.在<code>themes/next/source/js</code>目录下创建<code>src</code>目录，进入<code>src</code>目录，创建<code>click.js</code>文件
2.将下列代码贴入<code>click.js</code>文件
```
!function(e,t,a){
  function n(){
    c(".heart{width: 10px;height: 10px;position: fixed;background: #f00;transform: rotate(45deg);-webkit-transform: rotate(45deg);-moz-transform: rotate(45deg);}" +
      ".heart:after," +
      ".heart:before{content: '';width: inherit;height: inherit;background: inherit;border-radius: 50%;-webkit-border-radius: 50%;-moz-border-radius: 50%;position: fixed;}" +
      ".heart:after{top: -5px;}" +
      ".heart:before{left: -5px;}"
    ),
      o(),
      r()
  }
  function r(){
    for(var e=0;e<d.length;e++)
      d[e].alpha<=0
        ?(t.body.removeChild(d[e].el),d.splice(e,1))
        :(d[e].y--,d[e].scale+=.004,d[e].alpha-=.013,d[e].el.style.cssText="left:"+d[e].x+"px;top:"+d[e].y+"px;opacity:"+d[e].alpha+";transform:scale("+d[e].scale+","+d[e].scale+") rotate(45deg);background:"+d[e].color+";z-index:99999");
    requestAnimationFrame(r)
  }
  function o(){
    var t="function"==typeof e.onclick&&e.onclick;e.onclick=function(e){t&&t(),i(e)}
  }
  function i(e){
    var a=t.createElement("div");
    a.className="heart",d.push({el:a,x:e.clientX-5,y:e.clientY-5,scale:1,alpha:1,color:s()}),t.body.appendChild(a)
  }
  function c(e){
    var a=t.createElement("style");
    a.type="text/css";
    try{
      a.appendChild(t.createTextNode(e))
    }catch(t){
      a.styleSheet.cssText=e
    }
    t.getElementsByTagName("head")[0].appendChild(a)
  }
  function s(){
    return"rgb("+~~(255*Math.random())+","+~~(255*Math.random())+","+~~(255*Math.random())+")"
  }
  var d=[];
  e.requestAnimationFrame=function(){
    return e.requestAnimationFrame
      ||e.webkitRequestAnimationFrame
      ||e.mozRequestAnimationFrame
      ||e.oRequestAnimationFrame
      ||e.msRequestAnimationFrame
      ||function(e){setTimeout(e,1e3/60)}
  }(),n()
}(window,document);

```
3.编辑<code>themes/next/layout/_layout.swig</code>文件，末尾处添加
```
<script type="text/javascript" src="/js/src/click.js"></script>
```

### 社交栏设置 ###
编辑<code>themes/next/_config.yml</code>文件，找到<code>social</code>
```
social:
  #网站名：网址 || 图标名
  GitHub: https://github.com/yourname || github
  E-Mail: mailto:yourname@gmail.com || envelope
```

### 友情链接 ###
编辑<code>themes/next/_config.yml</code>文件，找到<code>Blog rolls</code>
```
links:
  百度: http://baidu.com/
  开源中国: https://www.oschina.net/
```

### 补充功能 ###

#### 部分图片禁用fancybox ####

hexo默认使用fancybox插件，支持点击放大查看。如果不想图片被点击放大，可以使用下面的方法：
1. 找到`theme/next/source/js/utils.js`文件中`var $image = $(element);`
2. 在下一行添加代码`if ($(element).hasClass('nofancybox')) return;`
如下：
```
wrapImageWithFancyBox: function() {
    document.querySelectorAll('.post-body :not(a) > img, .post-body > img').forEach(element => {
      var $image = $(element);
      if ($(element).hasClass('nofancybox')) return; // 此后为添加行
      var imageLink = $image.attr('data-src') || $image.attr('src');
      …………
```

#### 设置背景图片 ####

1. 查看当前使用的是哪个next主题，比如这里用的是`Gemini`
2. 找到`themes/next/source/css/_schemes/Gemini/index.styl`文件，末尾添加如下代码：
```css
body {
    background:url(/images/school.png); /* school.png 为自定义的图片 */
    background-attachment: fixed;
}
```

#### 内容板块透明设置 ####

1. 查看当前使用的是哪个next主题，比如这里用的是`Gemini`
2. 找到`themes/next/source/css/_schemes/Gemini/index.styl`文件，修改如下代码：
```css
.content-wrap {
  background: rgba(255,255,255,0.5); //0.5是透明度
  box-shadow: initial;
  padding: initial;
}

.post-block {
  background: rgba(255,255,255,0.1);
  border-radius: $border-radius-inner;
  box-shadow: $box-shadow-inner;
  padding: $content-desktop-padding;
}

+tablet() {
  // Posts in blocks.
  .content-wrap {
    padding: $content-tablet-padding;
    background: rgba(255,255,255,0.5); //0.5是透明度
  }
  ………
}
```

#### 灵活设置摘要 ####

只需在文章任何地方加入代码`<!-- more -->`，之后的将被屏蔽调，之前的内容作为摘要出现。

#### 设置行内代码块颜色 ####

找到`/themes/next/source/css/_common/scaffolding/highlight/highlight.styl`文件，定位到`code`定义处，修改为：
```css
code {
  background: #5cb85c; // $code-background;
  border-radius: $code-border-radius;
  color: #891717; // $code-foreground;
  padding: 2px 4px;
  word-wrap();
}
```

#### 代码块主题 ####

编辑<code>themes/next/_config.yml</code>文件，找到<code>codeblock</code>
```text
highlight_theme: night
```

### 参考链接 感谢各位 ###
[BlueLzy的博客](https://bluelzy.com/articles/use_valine_for_your_blog.html)
[Eternal_zttz的博客](http://eternalzttz.com/hexo-next.html)
[Hunter1023的博客](https://blog.csdn.net/weixin_39345384/article/details/80785373)
[evansun的博客](https://blog.jyusun.com/contents/20190320112238.html)
