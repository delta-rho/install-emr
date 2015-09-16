#!/bin/bash
# R-Studio
installRstudio(){
    sudo yum install -y openssl098e

    wget -q https://s3.amazonaws.com/rstudio-server/current.ver -O currentVersion.txt
    ver=$(cat currentVersion.txt)
    wget http://download2.rstudio.org/rstudio-server-${ver}-x86_64.rpm
    sudo yum install -y --nogpgcheck rstudio-server-${ver}-x86_64.rpm
    rm rstudio-server-*-x86_64.rpm

    echo "www-port=80" | sudo tee -a /etc/rstudio/rserver.conf
    echo "rsession-ld-library-path=/usr/local/lib" | sudo tee -a /etc/rstudio/rserver.conf
    sudo rstudio-server restart
}

installRstudioPro(){

    # openssl
    sudo yum install -y openssl098e

    ## rstudio ##
    wget http://download2.rstudio.org/rstudio-server-pro-0.98.1091-x86_64.rpm
    sudo yum install -y --nogpgcheck rstudio-server-pro-0.98.1091-x86_64.rpm

    sudo mkdir /etc/rstudio

    # create self-signed cert
    sudo openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=WA/L=Richland/O=PNNL/CN=bootcamp.pnnl.gov" -keyout /etc/rstudio/server.key  -out /etc/rstudio/server.crt

    sudo chmod 600 /etc/rstudio/server.*

    echo "www-port=443" | sudo tee -a /etc/rstudio/rserver.conf
    echo "ssl-enabled=1" | sudo tee -a /etc/rstudio/rserver.conf
    echo "ssl-certificate=/etc/rstudio/server.crt" | sudo tee -a /etc/rstudio/rserver.conf
    echo "ssl-certificate-key=/etc/rstudio/server.key" | sudo tee -a /etc/rstudio/rserver.conf
    echo "rsession-ld-library-path=/usr/local/lib" | sudo tee -a /etc/rstudio/rserver.conf

    sudo rstudio-server restart
}

# Upgrades R
sudo yum update R.x86_64 -y

# installRstudioPro
installRstudio


# shiny Server
ver=$(wget -qO- https://s3.amazonaws.com/rstudio-shiny-server-os-build/centos-5.9/x86_64/VERSION)
wget https://s3.amazonaws.com/rstudio-shiny-server-os-build/centos-5.9/x86_64/shiny-server-${ver}-rh5-x86_64.rpm
sudo yum install -y --nogpgcheck shiny-server-${ver}-rh5-x86_64.rpm

sudo mkdir -p /srv/shiny-server/examples
sudo cp -R /usr/lib64/R/library/shiny/examples/* /srv/shiny-server/examples
sudo chown -R shiny:shiny /srv/shiny-server/examples
sudo chmod 777 /srv/shiny-server/

