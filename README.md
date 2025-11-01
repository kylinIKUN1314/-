# XPlayerConsole

#### 介绍
基于thinkphp6开发的XPlayerHTML5网页播放器前台控制面板,支持多音乐平台音乐解析。

#### 技术栈
后端：thinkphp 6
前端：layui
数据库：mysql

#### 依赖
composer
php 7.1+
mysql 5.5+

#### 伪静态配置
nginx

```
location / {
      index  index.htm index.html index.php;
      #访问路径的文件不存在则重写URL转交给ThinkPHP处理
      if (!-e $request_filename) {
         rewrite  ^/(.*)$  /index.php?s=$1  last;
         break;
      }
  }
```
apache
项目自带apache静态化无需配置
#### 安装
1. 导入根目录install.sql到数据库
2. 配置config/database.php数据库信息
3. 默认账户 admin 123456
4. 开放函数popen和proc_open

