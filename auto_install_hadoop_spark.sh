#!/bin/bash
#check os  version
OS_VERSION=`cat /etc/centos-release | awk -F " " '{print$4}' | awk -F "." '{print$1}'`
if [  ${OS_VERSION} -eq 7 ]
then
        echo  "the system is CentOS7 ,The system meets the requirements and continues"
else
        echo -e  "\033[41;37m you should install OS system by CentOS-7.iso(Base Web server). \033[0m"
        exit 1
fi
#install ansible 
if [ `rpm -qa|grep ansible|wc -l` != 0 ]
then
    echo "Ansible already is installed!"
else
    mkdir -p /etc/yum.repo.d/repo_bk &&  mv /etc/yum.repo.d/*.repo /etc/yum.repo.d/repo_bk/
    yum localinstall -y $(pwd)/app_soft/ansible/*.rpm
    cp -r /etc/yum.repo.d/repo_bk/* /etc/yum.repo.d/
fi
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
####check service_hosts file
f_n=`echo $(pwd)/service_hosts`
if [ ! -f $f_n ]
then
    echo -e "\033[31m You must configure service_hosts !!!You can refer to the service_hosts template $(pwd)/service_hosts.template\033[0m"
    exit 1
else
    f_n_master_ip=`cat  $(pwd)/service_hosts|grep -v '^$'|sed 's/ //g'|awk '/service_master/,/service_master:vars/'|sed -n '1n;N;P;D'|wc -l`
    f_n_slave_ip=`cat  $(pwd)/service_hosts|grep -v '^$'|sed 's/ //g'|awk '/service_slave/,/service_slave:vars/'|sed -n '1n;N;P;D'|wc -l`
    if [ $f_n_master_ip == 0 ] && [ $f_n_slave_ip == 0 ]
    then
        echo -e "\033[31m You must configure service_master and service_slave IP in $f_n !!!!\033[0m"
        exit 1
    elif [ $f_n_master_ip == 0 ]
    then
        echo -e "\033[31m You must configure service_master IP in $f_n !!!!\033[0m"
        exit 1
    elif [ $f_n_slave_ip == 0 ]
    then
        echo -e "\033[31m You must configure service_slave IP in $f_n !!!!\033[0m"
        exit 1
    else
        continue
    fi
fi
#get java version
jv_v=`ls $(pwd)/app_soft/java/|awk -F ".tar.gz" {'print $1'}`
o_jv_v=`grep "jv_version:" $(pwd)/group_vars/service_master|awk {'print $2'}`
if [ ! -n "$jv_v" ]; then
   echo -e "\033[31m You must download java package! and put the package in $(pwd)/app_soft/java/!!!!\033[0m"
   exit 1
else
sed -i "s/${o_jv_v}/${jv_v}/g" $(pwd)/group_vars/service_master
fi
#get hadoop version
hdp_v=`ls $(pwd)/app_soft/hadoop/|awk -F ".tar.gz" {'print $1'}`
o_hdp_v=`grep "hdp_version:" $(pwd)/group_vars/service_master|awk {'print $2'}`
if [ ! -n "$hdp_v" ]; then
   echo -e "\033[31m You must download hadoop package! and put the package in $(pwd)/app_soft/hadoop/!!!!\033[0m"
   exit 1
else
   sed -i "s/${o_hdp_v}/${hdp_v}/g" $(pwd)/group_vars/service_master 
fi
#get spark version
spk_v=`ls $(pwd)/app_soft/spark/|awk -F ".tgz" {'print $1'}`
o_spk_v=`grep "spk_version:" $(pwd)/group_vars/service_master|awk {'print $2'}`
if [ ! -n "$spk_v" ]; then
   echo -e "\033[31m You must download spark package! and put the package in $(pwd)/app_soft/spark/!!!!\033[0m"
   exit 1
else
   sed -i "s/${o_spk_v}/${spk_v}/g" $(pwd)/group_vars/service_master
fi
\cp  $(pwd)/group_vars/service_master $(pwd)/group_vars/service_slave
#configuration hadoop file
master_IP=`cat  $(pwd)/service_hosts|grep -v '^$'|sed 's/ //g'|awk '/service_master/,/service_master:vars/'|sed -n '1n;N;P;D'`
slave_IP=`cat  $(pwd)/service_hosts|grep -v '^$'|sed 's/ //g'|awk '/service_slave/,/service_slave:vars/'|sed -n '1n;N;P;D'`
#setup hadoop slaves
hdp_slaves="$(pwd)/roles/service_master/templates/hadoop/slaves"
if [ -f "$hdp_slaves" ];then
    rm -rf $hdp_slaves
    for i in $slave_IP;
    do
        echo $i|grep -v '^$'|sed 's/ //g' >> $hdp_slaves
    done
fi
#setup hadoop 
hdp_core="$(pwd)/roles/service_master/templates/hadoop/core-site.xml"
#core-site,fs.defaultFS:8020
fs_default=`cat ${hdp_core}|grep -v '^$'|sed 's/ //g'|awk '/fs.defaultFS/,/<\/value>/'|awk '/<value>/,/<\/value>/'`
fs_new="<value>$master_IP:8020</value>"
sed -i "/fs.defaultFS/{n;s#${fs_default}#${fs_new}#;}" $hdp_core
#hdfs-site.xml\dfs.namenode.secondary.http-address\dfs.datanode.data.dir
hdp_hdfs="$(pwd)/roles/service_master/templates/hadoop/hdfs-site.xml"
dfs_sec_http=`cat ${hdp_hdfs}|grep -v '^$'|sed 's/ //g'|awk '/dfs.namenode.secondary.http-address/,/<\/value>/'|awk '/<value>/,/<\/value>/'`
dfs_sec_http_new="<value>$master_IP:50090</value>"
dfs_data_dir=`cat ${hdp_hdfs}|grep -v '^$'|sed 's/ //g'|awk '/dfs.datanode.data.dir/,/<\/value>/'|awk '/<value>/,/<\/value>/'`
dfs_data_dir_new=`grep "dfs_datanode_data_dir:" $(pwd)/group_vars/service_master|awk {'print $2'}`
for i in {'dfs.namenode.secondary.http-address','dfs.datanode.data.dir'};
do
    if [ $i == "dfs.namenode.secondary.http-address" ] ;then
    sed -i "/dfs.namenode.secondary.http-address/{n;s#${dfs_sec_http}#${dfs_sec_http_new}#;}" $hdp_hdfs
    else
    sed -i "/dfs.datanode.data.dir/{n;s#${dfs_data_dir}#<value>${dfs_data_dir_new}</value>#;}" $hdp_hdfs
    fi
done
#yarn-site.xml
hdp_yarn="$(pwd)/roles/service_master/templates/hadoop/yarn-site.xml"
#yarn.resourcemanager.hostname
hdp_yarn_host=`cat ${hdp_yarn}|grep -v '^$'|sed 's/ //g'|awk '/yarn.resourcemanager.hostname/,/<\/value>/'|awk '/<value>/,/<\/value>/'`
hdp_yarn_host_new="<value>$master_IP</value>"
#yarn.nodemanager.local-dirs
hdp_yarn_local_dir=`cat ${hdp_yarn}|grep -v '^$'|sed 's/ //g'|awk '/yarn.nodemanager.local-dirs/,/<\/value>/'|awk '/<value>/,/<\/value>/'`
hdp_yarn_local_dir_new=`grep "yarn_nodemanager_local_dirs:" $(pwd)/group_vars/service_master|awk {'print $2'}`

for i in {'yarn.resourcemanager.hostname','yarn.nodemanager.local-dirs'};
do
    if [ $i == "yarn.resourcemanager.hostname" ] ;then
    sed -i "/yarn.resourcemanager.hostname/{n;s#${hdp_yarn_host}#${hdp_yarn_host_new}#;}" $hdp_yarn
    else
    sed -i "/yarn.nodemanager.local-dirs/{n;s#${hdp_yarn_local_dir}#<value>${hdp_yarn_local_dir_new}</value>#;}" $hdp_yarn
    fi
done
#setup spark
spark_slaves="$(pwd)/roles/service_master/templates/spark/slaves"
if [ -f "$spark_slaves" ];then
    rm -rf $spark_slaves
    for i in $slave_IP;
    do
    echo $i|grep -v '^$'|sed 's/ //g' >> $spark_slaves
    done
fi
#configuration service_slave
#check roles/service_slave/templates/ 
conf_slave=`ls $(pwd)/roles/service_slave/templates`
if [ "$conf_slave|wc -l" > "0" ];
then
 rm -rf $(pwd)/roles/service_slave/templates
 cp -r $(pwd)/roles/service_master/templates $(pwd)/roles/service_slave/templates
fi
###########auto deploy app#######################
ansible-playbook -i $(pwd)/service_hosts $(pwd)/service_install.yml
echo `date "+%Y-%m-%d %H:%M:%S"` 
echo -e "\033[33m ################################# \033[0m"
echo -e "\033[33m ###Configure server successful### \033[0m"
echo -e "\033[35m ###Master:    $master_IP    ### \033[0m"
echo -e "\033[36m ***service Username: sparkuser *** \033[0m"
echo -e "\033[33m ################################# \033[0m"
