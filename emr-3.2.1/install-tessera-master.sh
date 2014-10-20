#!/bin/bash

# R-Studio
wget http://download2.rstudio.org/rstudio-server-0.98.1062-x86_64.rpm
sudo yum install -y --nogpgcheck rstudio-server-0.98.1062-x86_64.rpm

echo "www-port=80" | sudo tee -a /etc/rstudio/rserver.conf
echo "rsession-ld-library-path=/usr/local/lib" | sudo tee -a /etc/rstudio/rserver.conf
sudo rstudio-server restart

wget http://download3.rstudio.org/centos-5.9/x86_64/shiny-server-1.2.1.362-x86_64.rpm
sudo yum install -y --nogpgcheck shiny-server-1.2.1.362-x86_64.rpm

# Shiny Server
sudo mkdir -p /srv/shiny-server/examples
sudo cp -R /usr/lib64/R/library/shiny/examples/* /srv/shiny-server/examples
# sudo chown -R shiny:shiny /srv/shiny-server/examples
