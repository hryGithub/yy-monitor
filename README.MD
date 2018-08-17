1.文件说明
    monitor_agent.sh为采集脚本
    app_mo.ini   为app_id和启动命令的配置文件，monitor.agent.sh会去调用
    mo_mo.sh 为monitor_agent.sh的监控脚本
2.脚本使用root账户运行,monitor_agent.sh中的logifle,app_conf需要提前创建好

3.服务器需要安装sysstat,部分数据需要用到
    以centos为例:yum install sysstat -y
4.启动
    ./monitor_1.sh &
5.监控
    使用crontab
    * * * * * /data/scripts/mo_mo.sh
