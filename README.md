## hadoop_spark_autoinstall
 Hadoop spark one-click deployment

### 应用场景

可以通过简单几步设定快速部署hadoop
### 



```
++++++++++++++++service_hosts contents+++++++++++++++
[service_master]
sr209
[service_master:vars]
ansible_ssh_user="root"
ansible_ssh_pass="abc123"
[service_slave]
sr210
sr211
sr212
[service_slave:vars]
ansible_ssh_user="root"
ansible_ssh_pass="abc123"
++++++++++++++++++++++++++++++++++++++++++++++++++++
```












## first you need download java,hadoop,spark package!
## put this package into app_soft/hadoop ,app_soft/java,app_soft/spark
### need configure service_hosts file
# ++++++++++++++++service_hosts contents+++++++++++++++
[service_master]
sr209
[service_master:vars]
ansible_ssh_user="root"
ansible_ssh_pass="abc123"
[service_slave]
sr210
sr211
sr212
[service_slave:vars]
ansible_ssh_user="root"
ansible_ssh_pass="abc123"
# ++++++++++++++++++++++++++++++++++++++++++++++++++++
4.
