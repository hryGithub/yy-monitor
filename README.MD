# wiki

## 1.文件说明

    monitor_agent.sh为采集脚本
    app_mo.ini为app_id和启动命令的配置文件，monitor_agent.sh会去调用 
    mo_mo.sh为monitor_agent.sh的监控脚本

## 2.依赖组件

    服务器需要安装sysstat,部分数据需要用到 以centos为例:yum install sysstat -y 

## 3.注意事项

    脚本使用root账户运行,monitor_agent.sh中的logfile,app_conf需要提前创建好

## 4.启动

    ./monitor_agent.sh &

## 5.监控

    使用crontab 
    * * * * * /data/scripts/mo_mo.sh
