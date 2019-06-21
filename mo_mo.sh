#!/bin/bash

#获取原进程id

#monitor
pid=`ps -ef|grep "/data/monitor/monitor_agent.sh"|grep -v grep|awk '{print $2}'`

#启动命令
cmd="nohup /data/monitor/monitor_agent.sh >> /var/log/monitor_agent.log 2>&1"
#重启
if [ "$pid" = '' ];then
    echo "monitor已停止，开始重启..."
    ($cmd) &  #以子shell启动
fi

