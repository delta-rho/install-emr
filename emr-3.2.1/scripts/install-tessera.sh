#!/bin/bash

# AMI 3.2.1
# sudo yum update
# this produces errors
# R 3.0.2 already installed

## CONFIG
function eVal {
    echo $1 | tee -a /home/hadoop/.Renviron
    echo $1 | sudo tee -a /usr/lib64/R/etc/Renviron
    echo export $1 | tee -a /home/hadoop/.bashrc
}

eVal 'HADOOP=/home/hadoop'
eVal 'HADOOP_HOME=/home/hadoop'
eVal 'HADOOP_CONF_DIR=/home/hadoop/conf'
eVal 'HADOOP_BIN=/home/hadoop/bin'
eVal 'HADOOP_OPTS=-Djava.awt.headless=true'
eVal 'HADOOP_LIBS=/home/hadoop/conf:/home/hadoop/share/hadoop/common/lib/:/home/hadoop/share/hadoop/common/:/home/hadoop/share/hadoop/hdfs:/home/hadoop/share/hadoop/hdfs/lib/:/home/hadoop/share/hadoop/hdfs/:/home/hadoop/share/hadoop/yarn/lib/:/home/hadoop/share/hadoop/yarn/:/home/hadoop/share/hadoop/mapreduce/lib/:/home/hadoop/share/hadoop/mapreduce/::/usr/share/aws/emr/emrfs/lib/:/usr/share/aws/emr/lib/'
eVal 'LD_LIBRARY_PATH=/usr/local/lib:/home/hadoop/lib/native:/usr/lib64:/usr/local/cuda/lib64:/usr/local/cuda/lib:$LD_LIBRARY_PATH'

echo '/usr/java/jdk1.7.0_65/jre/lib/amd64/server/' | sudo tee -a  /etc/ld.so.conf.d/jre.conf
echo '/usr/java/jdk1.7.0_65/jre/lib/amd64/' | sudo tee -a  /etc/ld.so.conf.d/jre.conf
echo '/home/hadoop/.versions/2.4.0/lib/native/' | sudo tee -a  /etc/ld.so.conf.d/hadoop.conf
sudo ldconfig


# packages need updating/installing
sudo R CMD javareconf
sudo su - -c "R -e \"install.packages('rJava', repos='http://www.rforge.net/')\""
sudo su - -c "R -e \"install.packages('codetools', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('lattice', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('MASS', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('boot', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('shiny', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"options(repos = 'http://cran.rstudio.com/'); library(devtools); install_github('hafen/housingData')\""
sudo su - -c "R -e \"install.packages('maps',repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('mixtools', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('lubridate', repos='http://cran.rstudio.com/')\""

#protobuf 2.5.0 comes with hadoop but need the .so files
export PROTO_BUF_VERSION=2.5.0
wget https://protobuf.googlecode.com/files/protobuf-$PROTO_BUF_VERSION.tar.bz2
tar jxvf protobuf-$PROTO_BUF_VERSION.tar.bz2
cd protobuf-$PROTO_BUF_VERSION
./configure && make -j4
sudo make install
cd ..

# rhipe
export RHIPE_VERSION=0.75.1.4_hadoop-2

wget http://ml.stat.purdue.edu/rhipebin/Rhipe_$RHIPE_VERSION.tar.gz

export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
sudo chmod 777 /usr/lib64/R/library
sudo chmod -R 777 /usr/share/
R CMD INSTALL Rhipe_$RHIPE_VERSION.tar.gz

sudo yum -y install libcurl-devel

sudo -E R -e "install.packages('devtools', repos='http://cran.rstudio.com/')"
sudo -E R -e "options(unzip = 'unzip', repos = 'http://cran.rstudio.com/'); library(devtools); install_github('datadr', 'tesseradata')"
sudo -E R -e "options(unzip = 'unzip', repos = 'http://cran.rstudio.com/'); library(devtools); install_github('trelliscope', 'tesseradata')"

# setup R environment
sudo mkdir /etc/R/
echo 'HADOOP=/home/hadoop'| sudo tee -a /etc/R/Renviron
echo 'HADOOP_HOME=/home/hadoop/' | sudo tee -a /etc/R/Renviron
echo 'HADOOP_CONF_DIR=/home/hadoop/conf' | sudo tee -a /etc/R/Renviron
echo 'HADOOP_LIBS=/home/hadoop/conf:/home/hadoop/share/hadoop/common/lib/:/home/hadoop/share/hadoop/common/:/home/hadoop/share/hadoop/hdfs:/home/hadoop/share/hadoop/hdfs/lib/:/home/hadoop/share/hadoop/hdfs/:/home/hadoop/share/hadoop/yarn/lib/:/home/hadoop/share/hadoop/yarn/:/home/hadoop/share/hadoop/mapreduce/lib/:/home/hadoop/share/hadoop/mapreduce/::/usr/share/aws/emr/emrfs/lib/:/usr/share/aws/emr/lib/' | sudo tee -a /etc/R/Renviron

echo 'LD_LIBRARY_PATH=/usr/local/lib:/home/hadoop/lib/native:/usr/lib64:/usr/local/cuda/lib64:/usr/local/cuda/lib:$LD_LIBRARY_PATH' | sudo tee -a /etc/R/Renviron

echo "exec /usr/bin/R CMD /usr/lib64/R/library/Rhipe/bin/RhipeMapReduce --slave --silent --vanilla" | sudo tee -a /home/hadoop/rhRunner.sh

sudo chmod 755 -R /home/hadoop


