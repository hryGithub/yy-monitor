#!/bin/bash

#系统需要安装sysstat
#本机host_id
host_id=

#日志文件
logfile="/var/log/monitor_agent.log"

#数据库配置
host="127.0.0.1"
port=3306
username="root"
password=""
dbname="dba"

#采集频率(秒)
delay=30

#磁盘目录空间监控，空格分隔
disk_path=("/" "/data")

#app监控的配置文件绝对路径
app_conf='/data/monitor/app_mo.ini'


cpu_record()
{
    temp=(`sar 1 1 |tail -1 |awk '{print $3,$4,$5,$6,$8}'`)
    #12:00:01 AM     CPU     %user     %nice   %system   %iowait    %steal     %idle
    #Average:        all      0.02      0.00      0.02      0.00      0.00     99.97
    us=${temp[0]}
    ni=${temp[1]}
    sy=${temp[2]}
    wa=${temp[3]}
    id=${temp[4]}
    #记录日志
    echo $us $sy $ni $id $wa >> $logfile
    #插入数据库
    mysql -h$host -u$username -p$password -P$port -e "insert into $dbname.cpu_record(host_id,cpu_idle,cpu_nice,cpu_system,cpu_user,cpu_wait) values($host_id,$id,$ni,$sy,$us,$wa);"
}

memory_record()
{
    #总内存，使用内存，空闲内存(单位MB)，空格分隔
    temp=(`free -m|awk '/Mem/ {print $2,$3,$4,$5,$6,$7}'`)
    total=${temp[0]}
    used=${temp[1]}
    free=${temp[2]}
    shared=${temp[3]}
    buffers=${temp[4]}
    cached=${temp[5]}
    #记录日志
    echo $total $used $free $shared $buffer $cached >> $logfile
    #插入数据库
    mysql -h$host -u$username -p$password -P$port -e "insert into $dbname.memory_record(host_id,used,free,shared,buffers,cached) values($host_id,$used,$free,$shared,$buffers,$cached);"
}
disk_record()
{
    create_time=`date "+%Y-%m-%d %H:%M:%S"`
    for path in ${disk_path[@]};do
        #df -P 加-P参数解决换行问题
        #-BG 以G为单位显示
        temp=(`df -P -BG $path |tail -1|awk '{print $2,$3}'|sed 's@G@@g'`)
        total=${temp[0]}
        used=${temp[1]}
        #记录日志
        echo $path $total $used >> $logfile
        #出入数据库
        mysql -h$host -u$username -p$password -P$port -e "insert into $dbname.disk_record(host_id,path,total,used,create_time) values($host_id,'$path',$total,$used,'$create_time');"
    done
}
disk_io_record()
{
    create_time=`date "+%Y-%m-%d %H:%M:%S"`
    #获取物理磁盘(sd,hd,xvd)
    diskarray=(`cat /proc/diskstats |grep -E "\bx?[shv]d[abcdefg]\b"|grep -i "\b$1\b"|awk '{print $3}'|sort|uniq   2>/dev/null`)
    for disk in ${diskarray[@]};do
        io_temp=(`iostat -d -k "$disk" |grep "$disk" |awk '{print $2,$3,$4}'`)
        io_tps=0
        io_rs=0
        io_ws=0
        if [ ${#io_temp[@]} != 0 ];then
            io_tps=${io_temp[0]}
            io_rs=${io_temp[1]}
            io_ws=${io_temp[2]}
        fi
        #记录日志
        echo $host_id   $disk  $io_tps $io_rs  $io_ws >> $logfile
        #插入数据库
        #字符串形式的需要加单引号
        mysql -h$host -u$username -p$password -P$port -e "insert into $dbname.disk_io_record(host_id,disk,io_read,io_write,io_tps,create_time) values($host_id,'$disk',$io_rs,$io_ws,$io_tps,'$create_time');"
    done
    
}

net_record()
{
    create_time=`date "+%Y-%m-%d %H:%M:%S"`
    #获取服务所有网卡
    nets=(`ls /sys/class/net|grep -v lo`)
    #获取网卡流量
    temp_r=`sar -n DEV 1 1|grep  ^Average|grep -vE "lo|IFACE"`
    for net in ${nets[@]};do
        temp=(`echo -e "$temp_r"|grep "$net"|awk '{print $5,$6}'`)
        in=${temp[0]}
        out=${temp[1]}
        #记录日志
        echo $net $in $out >> $logfile
        #插入数据库
        mysql -h$host -u$username -p$password -P$port -e "insert into $dbname.net_record(host_id,net,net_in_rate,net_out_rate,create_time) values($host_id,'$net',$in,$out,'$create_time');"
    done
}

app_record()
{
    apps=(`cat $app_conf|grep -v '^#'|cut -d ';' -f1`)
    for app_id in ${apps[@]};do
        cmd=`cat $app_conf|grep -v '^#'|grep $app_id|cut -d ';' -f2`
        pids=(`ps -ef|grep "$cmd" |grep -v grep |awk '{print $2}'`)
        is_start=0
        start_time=`date "+%Y-%m-%d %H:%M:%S"`
        cpu_used=0
        memory_used=0
        pid=${pids[0]}
        if [[ $pid ]];then
            temp=(`ps aux |grep "$cmd" |grep -v grep |awk '{print $3,$4}'|awk '{for(i=1;i<=NF;i++)a[i]+=$i}END{for(j=1;j<=NF;j++)printf a[j]"\t"}'`)
            is_start=1
            start_time=$(date -d "`ps -p $pid -o lstart|tail -1`" "+%Y-%m-%d %H:%M:%S")          
            cpu_used=${temp[0]}
            memory_used=${temp[1]}
        fi
        #日志记录
        echo $app_id,$is_start,$start_time,$cpu_used,$memory_used >> $logfile
        #插入数据库
        mysql -h$host -u$username -p$password -P$port -e \
        "insert into $dbname.app_record(app_id,is_start,start_time,cpu_used,memory_used) \
        values($app_id,$is_start,'$start_time',$cpu_used,$memory_used);"
    done

}

db_record()
{
    #被监控数据库配置
    db_id=1
    host_m="127.0.0.1"
    port_m=3306
    username_m="root"
    password_m=""

    connections=`mysql -h$host_m -u$username_m -p$password_m -P$port_m -e "status" |grep '^Threads'|awk '{print $2}'`
    slow_queries=0
    buffer_utilization=0
    #记录日志
    echo $db_id,$slow_queries,$connections,$buffer_utilization >> $logfile
    #插入数据库
     mysql -h$host -u$username -p$password -P$port -e \
     "insert into $dbname.db_record(db_id,slow_queries,connections,buffer_utilization) \
     values($db_id,$slow_queries,$connections,$buffer_utilization);"
}

http_record()
{
    #配置信息
    http_id=
    port=

    connections=`netstat -an|grep $port|grep ESTAB|wc -l`
    #记录日志
    echo $http_id $port $connections >> $logfile
    #插入数据库
    mysql -h$host -u$username -p$password -P$port -e "insert into $dbname.http_record(http_id,connections) values($http_id,$connections)"
}			 


while true;
do
    echo `date "+%Y-%m-%d %H:%M:%S"` >> $logfile
    echo "cpu_record:" >> $logfile
    cpu_record
    echo "memory_record:" >> $logfile
    memory_record
    echo "disk_record:" >> $logfile
    disk_record
    echo "disk_io_record:" >> $logfile
    disk_io_record
    echo "net_record:" >> $logfile 
    net_record
    echo "app_record:" >> $logfile
    app_record
    #echo "db_record:" >> $logfile
    #db_record
	#echo "http_record:" >> $logfile
	#http_record
    echo "----------------------------------------------------------------" >> $logfile
    sleep $delay
done