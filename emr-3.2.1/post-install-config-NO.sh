#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    START=1
    USER_COUNT=1
    BASE_USERNAME=tessera
else
    START=$1
    USER_COUNT=$2
    BASE_USERNAME=$3
fi

echo "USER_COUNT=$USER_COUNT"
echo "starting with user number $START"
echo "with a base username of $BASE_USERNAME"
# give hadoop a password
# echo "hadoop:hadoop" | sudo chpasswd

hadoop fs -mkdir /tmp

sudo mkdir -p /mnt/tmp
sudo chmod 777 -R /mnt/tmp

DEMO_FILE=Tessera_demo_CSP2015.zip

#download data & scripts
wget --no-check-certificate https://s3-us-west-2.amazonaws.com/velocity1/vast-data/nf-week2.csv
wget --no-check-certificate -O $DEMO_FILE  https://github.com/tesseradata/docs-csp2015/blob/gh-pages/EMR/Tessera_demo_CSP2015_EMR.zip?raw=true

unzip -q $DEMO_FILE

#create users
PORT=5290$START
echo "$PORT start"
for i in $(eval echo "{$START..$USER_COUNT}")
  do
      USER_NAME=$BASE_USERNAME-$i
	  # create user
	  sudo useradd -m $USER_NAME
	  # give them a password
	  echo "$USER_NAME:$USER_NAME" | sudo chpasswd
      
	  # create data dir in hadoop
  	  hadoop fs -mkdir -p /user/$USER_NAME/vast/raw/nf
	  # put the data in hdfs
	  hadoop fs -put nf-week2.csv /user/$USER_NAME/vast/raw/nf/nf-week2.csv
	    
      # change perms
	  hadoop fs -chown -R $USER_NAME /user/$USER_NAME

	  # copy scripts and sample data to user data dir
      sudo mkdir -p /mnt/users/$USER_NAME
      sudo cp -R demos /mnt/users/$USER_NAME/
      sudo ln -s /mnt/users/$USER_NAME/demos  /home/$USER_NAME/demos
      
	  # create R lib directory
	  sudo mkdir -p /home/$USER_NAME/R/lib
      # create tmp
      sudo mkdir /home/$USER_NAME/tmp
      
	  # set some R environment variables
	  echo "TR_PORT=$PORT" | sudo tee -a /home/$USER_NAME/.Renviron
	  echo "TMPDIR=/mnt/tmp" | sudo tee -a /home/$USER_NAME/.Renviron
	  echo "HDFS_USER_VAST=/user/$USER_NAME/vast" | sudo tee -a /home/$USER_NAME/.Renviron
      
	  # set persmissions
	  sudo chown -R $USER_NAME:$USER_NAME /home/$USER_NAME
      sudo chown -R $USER_NAME:$USER_NAME /mnt/users/$USER_NAME
      
      sudo chmod -R 755 /home/$USER_NAME
      sudo chmod -R 755 /mnt/users/$USER_NAME
      
	  # increment the trelliscope port
	  PORT=$[PORT + 1]
 done

 hadoop fs -chmod -R 777 /
# rwx to the entire world
# hadoop fs -chmod -R 777 /

echo "#!/usr/bin/env bash" >/tmp/fireup.sh
echo "    if [ \"/home/hadoop/bin/hadoop fs -test -d /mnt\" ]; then" >>/tmp/fireup.sh
echo "        sudo -u shiny nohup shiny-server &" >>/tmp/fireup.sh
# Anything you would like to add (configurations or installations) that require Hadoop, HDFS to be running
# use a shell script format and enter after this comment, preferably before the empty crontab entry.
# PLEASE TAKE CARE OF BASHISMS, AMAZON AMI BASH IS NOT STANDARD BASH

echo "        echo \"\" >/tmp/crontab.txt">>/tmp/fireup.sh
echo "        crontab /tmp/crontab.txt" >>/tmp/fireup.sh
echo "    fi" >>/tmp/fireup.sh
chmod +x /tmp/fireup.sh
echo "*/1 * * * * export JAVA_HOME=/usr/lib/jvm/java-7-oracle; /tmp/fireup.sh" >/tmp/crontab.txt
crontab /tmp/crontab.txt


