#!/bin/bash
# R-Studio
installRstudio(){
    wget http://download2.rstudio.org/rstudio-server-0.98.1062-x86_64.rpm
    sudo yum install -y --nogpgcheck rstudio-server-0.98.1062-x86_64.rpm

    echo "www-port=80" | sudo tee -a /etc/rstudio/rserver.conf
    echo "rsession-ld-library-path=/usr/local/lib" | sudo tee -a /etc/rstudio/rserver.conf
    sudo rstudio-server restart
}

installRstudioPro(){
    
    #openssl
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

installRstudioPro
# installRstudio


# Shiny Server
wget http://download3.rstudio.org/centos-5.9/x86_64/shiny-server-1.2.1.362-x86_64.rpm
sudo yum install -y --nogpgcheck shiny-server-1.2.1.362-x86_64.rpm
sudo mkdir -p /srv/shiny-server/examples
sudo cp -R /usr/lib64/R/library/shiny/examples/* /srv/shiny-server/examples
# sudo chown -R shiny:shiny /srv/shiny-server/examples

