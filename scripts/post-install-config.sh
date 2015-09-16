#!/bin/bash

USER=$1
PASSWD=$2

if [[ -z $USER ]]
then
  USER=tessera-user
fi

if [[ -z $PASSWD ]]
then
  PASSWD=tessera
fi

# fix permissions
chmod a+r /home/hadoop/conf/emrfs-site.xml
# this will allow anyone who has a login to see keys

# create user
sudo useradd -m $USER
# give them a password
echo "$USER:$PASSWD" | sudo chpasswd
# create data dir in hadoop
hadoop fs -mkdir -p /user/$USER/
# change perms
hadoop fs -chown -R $USER /user/$USER

# create R lib directory
sudo mkdir -p /home/$USER/R/lib
# create tmp
sudo mkdir /home/$USER/tmp
# give everyone persmissions
sudo chown -R $USER /home/$USER

# rwx to the entire world
# hadoop fs -chmod -R 777 /

echo "#!/usr/bin/env bash" >/tmp/fireup.sh
echo "  if [ \"/home/hadoop/bin/hadoop fs -test -d /mnt\" ]; then" >>/tmp/fireup.sh
echo "    /home/hadoop/bin/hadoop fs -mkdir /user/user3" >>/tmp/fireup.sh
echo "    /home/hadoop/bin/hadoop fs -mkdir /tmp" >>/tmp/fireup.sh
echo "    /home/hadoop/bin/hadoop fs -chmod -R 777 /" >>/tmp/fireup.sh
echo "    sudo -u shiny nohup shiny-server &" >>/tmp/fireup.sh
# Anything you would like to add (configurations or installations) that require Hadoop, HDFS to be running
# use a shell script format and enter after this comment, preferably before the empty crontab entry.
# PLEASE TAKE CARE OF BASHISMS, AMAZON AMI BASH IS NOT STANDARD BASH

echo "    echo \"\" >/tmp/crontab.txt">>/tmp/fireup.sh
echo "    crontab /tmp/crontab.txt" >>/tmp/fireup.sh
echo "  fi" >>/tmp/fireup.sh
chmod +x /tmp/fireup.sh

echo "*/1 * * * * export JAVA_HOME=/usr/lib/jvm/java-7-oracle; /tmp/fireup.sh" >/tmp/crontab.txt
crontab /tmp/crontab.txt
hadoop fs -chmod -R 777 /

