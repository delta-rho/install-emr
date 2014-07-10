These instructions are not bang on precise. Hopefully you will understand their
nature.  That is, the software is either installed in easy to copy directories
(e.g. R packages) which can be copied to a zip file or the software is compiled
but not installed (since it goes all across the system, e.g. protobuf and shiny
server). The latter is compiled and the compiled files are placed in the tar
archive. On the master/work nodes, these tar archives are downloaded and the
'make install' process i.e. the final installation is complete.

To repeat, following these instructions might not get what you exactly want, but
they should provide sufficient base for you  to tweak.



To recreate the binaries (which are downloaded in install-all-software and
install-master-r),  you need to


1. Start up an EMR instance (either from the webconsole or using the using these
   bootup scripts). Though it is better (i.e. easier to reproduce) if you start
   up with bare EMR directly from the webconsole. Be sure to not install
   Pig/Impala/Hive.

2. Run install-preconfigure

3. Run recreate-binaries/install-r (including the commented out parts)

4. Run recreate-binaries/install-additional-packages

5. Create a directories called 'forAll' and 'forMaster'.

6. Switch to 'forAll',

7. Run the recreate-binaries/install-protobuf but do not run the `make
   install`. Place remaining of that script in a complete.protobuf script inside
   'forAll'.

8. Copy the entire R site library to this folder too under heard the directory
   called site-library
   
6. Switch to 'forMaster',

8. Still inside 'forMaster', run  the 'wget' line of
   recreate-binaries/install-rstudio to download the deb file. Place the
   remainder of the file in a script (inside 'forMaster') called
   complete.rstudio.shiny

9. Still inside 'forMaster', run the recreate-binaries/install-shiny-server up
   to the portion that says "### STOP HERE DURING BINARY RECREATION PROCESS"
   Place the remaining in the script 'complete.rstudio.shiny' that switches to
   shiny-server/tmp/ and runs the remaining shiny server installation process.

The code in complete.rstudio.shiny looks like

```
#!/bin/bash                                                                                                                                                          
sudo dpkg -i rstudio-server-0.98.507-amd64.deb
sudo apt-get -f --force-yes --yes install

## Now complete Shiny                                                                                                                                                
cd shinysvr/shiny-server/tmp/

# Install the software at the predefined location                                                                                                                   
                                                                                                                                                                     
sudo make install

# POST INSTALL                                                                                                                                                      
                                                                                                                                                                     
# Place a shortcut to the shiny-server executable in /usr/bin                                                                                                       
                                                                                                                                                                     
sudo ln -s /usr/local/shiny-server/bin/shiny-server /usr/bin/shiny-server 2>/dev/null

#Create shiny user. On some systems, you may need to specify the full path to 'useradd'                                                                             
                                                                                                                                                                     
sudo useradd -r -m shiny 2>/dev/null

# Create log, config, and application directories                                                                                                                   
                                                                                                                                                                     
sudo mkdir -p /var/log/shiny-server
sudo mkdir -p /srv/shiny-server
sudo mkdir -p /var/lib/shiny-server
sudo chown shiny /var/log/shiny-server

#copy shiny examples                                                                                                                                                
                                                                                                                                                                     
sudo mkdir /srv/shiny-server/examples 2>/dev/null
sudo cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/examples 2>/dev/null
sudo chown -R shiny:shiny /srv/shiny-server/examples 2>/dev/null

cd ../../../
```


You should be ready to create your tar zipped files now. 
