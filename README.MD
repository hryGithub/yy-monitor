1.文件说明 monitor\_agent.sh为采集脚本 app\_mo.ini
为app\_id和启动命令的配置文件，monitor.agent.sh会去调用 mo\_mo.sh
为monitor\_agent.sh的监控脚本
2.脚本使用root账户运行,monitor\_agent.sh中的logifle,app\_conf需要提前创建好

3.服务器需要安装sysstat,部分数据需要用到 以centos为例:yum install
sysstat -y 4.启动 ./monitor\_agent.sh & 5.监控 使用crontab \* \* \* \*
\* /data/scripts/mo\_mo.sh
