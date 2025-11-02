<?php /*a:1:{s:48:"/www/wwwroot/cs.dkewl.cn/view/console/index.html";i:1692157005;}*/ ?>
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title><?php echo config('web.webname'); ?> - 后台管理</title>
  <meta name="renderer" content="webkit">
  <meta http-equiv="Content-Security-Policy" content="upgrade-insecure-requests" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
  <link href="https://pic8.58cdn.com.cn/nowater/webim/big/n_v2f90cb079558b409f8858777787d71f5a.png" rel='icon' type='image/x-icon'/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=0">
  <link rel="stylesheet" href="/static/layui/css/layui.css?t=20181101-1" media="all">
  <script>
  /^http(s*):\/\//.test(location.href) || alert('请先部署到 localhost 下再访问');
  </script>
</head>
<body>
  <div id="LAY_app"></div>
  <script src="/static/layui/layui.js?t=20181101-1"></script>
  <script>
  layui.config({
    base: '/static/' //指定 layuiAdmin 项目路径
    ,version: '1.2.1'
  }).use('index', function(){
    var layer = layui.layer, admin = layui.admin;
    layer.ready(function(){
    });
  });
  </script>
</body>
</html>
