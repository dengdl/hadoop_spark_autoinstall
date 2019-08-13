## hadoop_spark_autoinstall
 Hadoop spark one-click deployment
### 应用场景
可以通过简单几步设定快速部署hadoop

1. first you need download java,hadoop,spark package!
2. put this package into app_soft/hadoop ,app_soft/java,app_soft/spark
3. need configure service_hosts file
```
[service_master]
sr209
[service_master:vars]
ansible_ssh_user="`root`"
ansible_ssh_pass="abc123"
[service_slave]
sr210
sr211
sr212
[service_slave:vars]
ansible_ssh_user="root"
ansible_ssh_pass="abc123"

```
4. run hadoop_spark_autoinstall
sh auto_install_hadoop_spark.sh

###也可以直接运行auto_install_hadoop_spark.sh 根据提示完成设定
