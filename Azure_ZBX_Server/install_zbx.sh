#!/bin/bash

#install zbx2.2
rpm --import http://ftp.miraclelinux.com/zbx/RPM-GPG-KEY-MIRACLE
rpm -ihv http://ftp.miraclelinux.com/zbx/2.2/miracle-zbx-release-2.2-1.noarch.rpm
yum install -y zabbix zabbix-server zabbix-server-mysql zabbix-web zabbix-web-mysql zabbix-web-japanese zabbix-agent zabbix-java-gateway mariadb-server


#configure firewall
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=10051/tcp --permanent
firewall-cmd --zone=public --add-port=162/udp --permanent
firewall-cmd --zone=public --add-port=10050/tcp --permanent

#cnfigure mariadb
sed -i -e "4i innodb_file_per_table" /etc/my.cnf
sed -i -e "4i innodb_log_buffer_size=16M" /etc/my.cnf
sed -i -e "4i innodb_buffer_pool_size=$(expr $(free|grep '^Mem'|awk '{print $2}') / 2)" /etc/my.cnf
sed -i -e "4i innodb_log_file_size=$(expr $(free|grep '^Mem'|awk '{print $2}') / 10)" /etc/my.cnf
sed -i -e "4i innodb_log_files_in_group=2" /etc/my.cnf
sed -i -e "4i key_buffer_size=$(expr $(free|grep '^Mem'|awk '{print $2}') / 10)" /etc/my.cnf
sed -i -e "4i max_allowed_packet=16MB" /etc/my.cnf
sed -i -e "4i skip-character-set-client-handshake" /etc/my.cnf
sed -i -e "4i character-set-server=utf8" /etc/my.cnf

systemctl enable mariadb
systemctl start mariadb

mysql -uroot -e "create database zabbix; grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';"

mysql zabbix -uzabbix -pzabbix < /usr/share/doc/zabbix-server-mysql-2.2.11/mysql/schema.sql
mysql zabbix -uzabbix -pzabbix < /usr/share/doc/zabbix-server-mysql-2.2.11/mysql/images.sql
mysql zabbix -uzabbix -pzabbix < /usr/share/doc/zabbix-server-mysql-2.2.11/mysql/data.sql

#configure zabbix
sed -i -e "/^DBName=/s/DBName=.*/DBName=zabbix/" /etc/zabbix/zabbix_server.conf
sed -i -e "/^DBUser=/s/DBUser=.*/DBUser=zabbix/" /etc/zabbix/zabbix_server.conf
sed -i -e "/^# DBPassword/a DBPassword=zabbix" /etc/zabbix/zabbix_server.conf

chown zabbix:zabbix /etc/zabbix/zabbix_server.conf
chmod 400 /etc/zabbix/zabbix_server.conf

systemctl enable zabbix-server
systemctl enable zabbix-agent
systemctl start zabbix-server
systemctl start zabbix-agent

#configure httpd
sed -i -e 's/^#//' /etc/httpd/conf.d/zabbix.conf

systemctl enable httpd
systemctl start httpd


