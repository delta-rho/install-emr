#!/bin/bash

# Upgrades R
sudo yum update R.x86_64 -y

sudo su - -c "R -e \"install.packages('shiny')\""
sudo su - -c "R -e \"install.packages('rmarkdown')\""

# rstudio server
sudo yum install -y openssl098e

wget -q https://s3.amazonaws.com/rstudio-server/current.ver -O currentVersion.txt
ver=$(cat currentVersion.txt)
wget http://download2.rstudio.org/rstudio-server-rhel-${ver}-x86_64.rpm
sudo yum install -y --nogpgcheck rstudio-server-rhel-${ver}-x86_64.rpm
rm rstudio-server-rhel-*-x86_64.rpm

echo "www-port=8081" | sudo tee -a /etc/rstudio/rserver.conf
echo "rsession-ld-library-path=/usr/local/lib" | sudo tee -a /etc/rstudio/rserver.conf
sudo rstudio-server restart

# shiny Server
ver=$(wget -qO- https://s3.amazonaws.com/rstudio-shiny-server-os-build/centos-5.9/x86_64/VERSION)
wget https://s3.amazonaws.com/rstudio-shiny-server-os-build/centos-5.9/x86_64/shiny-server-${ver}-rh5-x86_64.rpm
sudo yum install -y --nogpgcheck shiny-server-${ver}-rh5-x86_64.rpm

sudo mkdir -p /srv/shiny-server/examples
sudo cp -R /usr/lib64/R/library/shiny/examples/* /srv/shiny-server/examples
sudo chown -R shiny:shiny /srv/shiny-server/examples
sudo chmod 777 /srv/shiny-server/

