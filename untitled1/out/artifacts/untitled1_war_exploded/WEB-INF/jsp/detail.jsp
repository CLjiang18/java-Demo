<%@page contentType="text/html; charset=UTF-8" language="java" %>
<%@include file="common/tag.jsp" %>
<!DOCTYPE html>
<html>
<head>
    <title>秒杀详情页</title>
    <%@include file="common/head.jsp" %>
</head>
<body>
<div class="container">
    <div class="panel panel-default text-center">
        <div class="pannel-heading">
            <h1>${seckill.name}</h1>
        </div>

        <div class="panel-body">
            <h2 class="text-danger">
                <%--显示time图标--%>
                <span class="glyphicon glyphicon-time"></span>
                <%--展示倒计时--%>
                <span class="glyphicon" id="seckill-box"></span>
            </h2>
        </div>
    </div>
</div>
<%--登录弹出层 输入电话--%>
<div id="killPhoneModal" class="modal fade">

    <div class="modal-dialog">

        <div class="modal-content">
            <div class="modal-header">
                <h3 class="modal-title text-center">
                    <span class="glyphicon glyphicon-phone"> </span>秒杀电话:
                </h3>
            </div>

            <div class="modal-body">
                <div class="row">
                    <div class="col-xs-8 col-xs-offset-2">
                        <input type="text" name="killPhone" id="killPhoneKey"
                               placeholder="填写手机号^o^" class="form-control">
                    </div>
                </div>
            </div>

            <div class="modal-footer">
                <%--验证信息--%>
                <span id="killPhoneMessage" class="glyphicon"> </span>
                <button type="button" id="killPhoneBtn" class="btn btn-success">
                    <span class="glyphicon glyphicon-phone"></span>
                    Submit
                </button>
            </div>

        </div>
    </div>

</div>

</body>
<%--jQery文件,务必在bootstrap.min.js之前引入--%>
<script src="http://apps.bdimg.com/libs/jquery/2.0.0/jquery.min.js"></script>
<script src="http://apps.bdimg.com/libs/bootstrap/3.3.0/js/bootstrap.min.js"></script>
<%--使用CDN 获取公共js http://www.bootcdn.cn/--%>
<%--jQuery Cookie操作插件--%>
<script src="http://cdn.bootcss.com/jquery-cookie/1.4.1/jquery.cookie.min.js"></script>
<%--jQuery countDown倒计时插件--%>
<script src="https://cdn.bootcss.com/jquery.countdown/2.1.0/jquery.countdown.min.js"></script>

<%--<script src="${pageContext.request.contextPath}/resources/script/seckill.js" charset="UTF-8" type="text/javascript">--%>
<%--    --%>
<%--</script>--%>
<script type="text/javascript" charset="UTF-8">
    //存放主要交互逻辑的js代码
    // javascript 模块化(package.类.方法)

    var seckill = {

        //封装秒杀相关ajax的url
        URL: {
            now: function () {
                return '/untitled1_war_exploded/seckill/time/now';
            },
            exposer: function (seckillId) {
                return '/untitled1_war_exploded/seckill/' + seckillId + '/exposer';
            },
            execution: function (seckillId, md5) {
                return '/untitled1_war_exploded/seckill/' + seckillId + '/' + md5 + '/execution';
            }
        },

        //验证手机号
        validatePhone: function (phone) {
            if (phone && phone.length == 11 && !isNaN(phone)) {
                return true;//直接判断对象会看对象是否为空,空就是undefine就是false; isNaN 非数字返回true
            } else {
                return false;
            }
        },

        //详情页秒杀逻辑
        detail: {
            //详情页初始化
            init: function (params) {
                //手机验证和登录,计时交互
                //规划我们的交互流程
                //在cookie中查找手机号
                var userPhone =$.cookie('userPhone');
                //验证手机号
                if (!seckill.validatePhone(userPhone)) {
                    //绑定手机 控制输出
                    var killPhoneModal = $('#killPhoneModal');
                    killPhoneModal.modal({
                        show: true,//显示弹出层
                        backdrop: 'static',//禁止位置关闭
                        keyboard: false//关闭键盘事件
                    });
                    $('#killPhoneBtn').click(function () {
                        var inputPhone = $('#killPhoneKey').val();
//                    console.log("inputPhone: " + inputPhone);
                        if (seckill.validatePhone(inputPhone)) {
                            //电话写入cookie(7天过期)
                            $.cookie('userPhone', inputPhone, {expires: 7, path: '/untitled1_war_exploded'});
                            //验证通过　　刷新页面
                            window.location.reload();
                        } else {
                            //todo 错误文案信息抽取到前端字典里
                            $('#killPhoneMessage').hide().html('<label class="label label-danger">手机号错误!</label>').show(300);
                        }
                    });
                }

                //已经登录
                //计时交互
                var startTime = params['startTime'];
                var endTime = params['endTime'];
                var seckillId = params['seckillId'];
//            console.log("开始秒杀时间=======" + startTime);
//            console.log("结束秒杀时间========" + endTime);
                $.get(seckill.URL.now(), {}, function (result) {
                    if (result && result['success']) {
                        var nowTime = result['data'];
                        //时间判断 计时交互
                        seckill.countDown(seckillId, nowTime, startTime, endTime);
                    } else {
                        console.log('result: ' + result);
                        alert('result: ' + result);
                    }
                });
            }
        },

        handlerSeckill: function (seckillId, node) {
            //获取秒杀地址,控制显示器,执行秒杀
            node.hide().html('<button class="btn btn-primary btn-lg" id="killBtn">开始秒杀</button>');

            $.post(seckill.URL.exposer(seckillId), {}, function (result) {
                //在回调函数种执行交互流程
                if (result && result['success']) {
                    var exposer = result['data'];
                    if (exposer['exposed']) {
                        //开启秒杀
                        //获取秒杀地址
                        var md5 = exposer['md5'];
                        var killUrl = seckill.URL.execution(seckillId, md5);
                        console.log("killUrl: " + killUrl);
                        //绑定一次点击事件
                        $('#killBtn').one('click', function () {
                            //执行秒杀请求
                            //1.先禁用按钮
                            $(this).addClass('disabled');//,<-$(this)===('#killBtn')->
                            //2.发送秒杀请求执行秒杀
                            $.post(killUrl, {}, function (result) {
                                if (result && result['success']) {
                                    var killResult = result['data'];
                                    var state = killResult['state'];
                                    var stateInfo = killResult['stateInfo'];
                                    //显示秒杀结果
                                    node.html('<span class="label label-success">' + stateInfo + '</span>');
                                }
                            });
                        });
                        node.show();
                    } else {
                        //未开启秒杀(浏览器计时偏差)
                        var now = exposer['now'];
                        var start = exposer['start'];
                        var end = exposer['end'];
                        seckill.countDown(seckillId, now, start, end);
                    }
                } else {
                    console.log('result: ' + result);
                }
            });

        },

        countDown: function (seckillId, nowTime, startTime, endTime) {
            console.log(seckillId + '_' + nowTime + '_' + startTime + '_' + endTime);
            var seckillBox = $('#seckill-box');
            if (nowTime > endTime) {
                //秒杀结束
                seckillBox.html("秒杀结束");
                console.log('秒杀结束====>发生乱码错误');
            } else if (nowTime < startTime) {
                //秒杀未开始,计时事件绑定
                var killTime = new Date(startTime + 1000);//todo 防止时间偏移
                seckillBox.countdown(killTime, function (event) {
                    //时间格式
                    var format = event.strftime('秒杀倒计时: %D天 %H时 %M分 %S秒 ');
                    seckillBox.html(format);
                }).on('finish.countdown', function () {
                    //时间完成后回调事件
                    //获取秒杀地址,控制现实逻辑,执行秒杀
                    console.log('______fininsh.countdown');
                    seckill.handlerSeckill(seckillId, seckillBox);
                });
            } else {
                //秒杀开始
                seckill.handlerSeckill(seckillId, seckillBox);
            }
        }
    };
</script>
<script type="text/javascript">
    jQuery(function() {
        //使用EL表达式传入参数
        seckill.detail.init({
            seckillId:${seckill.seckillId},
            startTime:${seckill.starttime.time},//毫秒
            endTime:${seckill.endtime.time}
        });
    });
</script>
</html>