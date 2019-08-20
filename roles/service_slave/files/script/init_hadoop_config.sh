#!/bin/bash

#disabile selinux
function fn_set_selinx () {
cp -a /etc/selinux/config /etc/selinux/config_bak
sed -i  "s/^SELINUX=enforcing/SELINUX=disabled/g"  /etc/selinux/config
}
STATUS_SELINUX=`cat /etc/selinux/config | grep ^SELINUX= | awk -F "=" '{print$2}'`
if [  ${STATUS_SELINUX} == enforcing ]
then
        fn_set_selinx
#else
#        continue
fi
#disable  firewalld.service
systemctl stop firewalld.service
systemctl disable firewalld.service

f_f=`cat /home/sparkuser/hadoop/etc/hadoop/hdfs-site.xml|grep -v '^$'|sed 's/ //g'|awk '/dfs.datanode.data.dir/,/<\/value>/'|awk '/<value>/,/<\/value>/'`
d_f="${f_f#*>}"
e_f="${d_f%<*}"
OLD_IFS="$IFS"
IFS=","
arr=($e_f)
IFS="$OLD_IFS"
for s in ${arr[@]}
do
rm -rf $s/
chown -R sparkuser:sparkuser ${s%/*}
done

py_mem=`free -g|sed -n "2,2p"|awk '{print $2}'`
yarn_nodemanager_mem=`echo $((py_mem*1024))`
py_vcores=`lscpu|sed -n "4p"|awk '{print $2}'`
source_f="/home/sparkuser/hadoop/etc/hadoop/yarn-site.xml"
a1=`cat ${source_f}|grep -v '^$'|sed 's/ //g'|awk '/yarn.nodemanager.resource.memory-mb/,/<\/value>/'|tail -1`
a2=`cat ${source_f}|grep -v '^$'|sed 's/ //g'|awk '/yarn.scheduler.maximum-allocation-mb/,/<\/value>/'|tail -1`
b1="<value>${yarn_nodemanager_mem}</value>"
a3=`cat ${source_f}|grep -v '^$'|sed 's/ //g'|awk '/yarn.nodemanager.resource.cpu-vcores/,/<\/value>/'|tail -1`
a4=`cat ${source_f}|grep -v '^$'|sed 's/ //g'|awk '/yarn.scheduler.maximum-allocation-vcores/,/<\/value>/'|tail -1`
b2="<value>${py_vcores}</value>"
for i in {'yarn.nodemanager.resource.memory-mb','yarn.scheduler.maximum-allocation-mb','yarn.nodemanager.resource.cpu-vcores','yarn.scheduler.maximum-allocation-vcores'};
do
    if [ $i == "yarn.nodemanager.resource.memory-mb" ] ;then
    sed -i "/yarn.nodemanager.resource.memory-mb/{n;s#${a1}#${b1}#;}" $source_f
    elif [ $i == "yarn.scheduler.maximum-allocation-mb" ];then
    sed -i "/yarn.scheduler.maximum-allocation-mb/{n;s#${a2}#${b1}#;}" $source_f
    elif [ $i == "yarn.nodemanager.resource.cpu-vcores" ];then
    sed -i "/yarn.nodemanager.resource.cpu-vcores/{n;s#${a3}#${b2}#;}" $source_f
    else
    sed -i "/yarn.scheduler.maximum-allocation-vcores/{n;s#${a4}#${b2}#;}" $source_f
    fi
done
