# Tessera Environment on Amazon EMR #
## Prereqs ##
*****
*   Comfortable installing software and using command line tools  
*   An Amazon AWS Account (EMR is not available with the free usage tier)  
    *   http://aws.amazon.com/  
*   Install the Amazon EMR CLI  
    *   http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-cli-install.html  
    *   When setting up your account always use the same region (e.g. "us-east-1")
    *   **Windows Users:**
        *   If the link on Amazon to install Ruby is broken use this one: http://rubyinstaller.org/ 
        *   The use of the Windows command prompt is required: http://windows.microsoft.com/en-us/windows-vista/open-a-command-prompt-window
    *   **Follow all the instructions!**
		*	This step will have you setup an S3 bucket and generate a key-pair that will be used below


## Instantiating a Cluster ##
*****
*   Do a `git clone` of this repo or download the files as a zip (click the "Download ZIP" button on the right) from this github site and unzip them
*   Upload all `emr-2.4.2/install-*` scripts to your S3 Bucket (ignore the Rhipe-*tar.gz)  
    *   This can be done through the AWS S3 web site
*   Copy the command below to your favorite text editor then replace `<bucket>` with your own S3 bucket (and path if different) and specify the key-pair you just made in the Amazon EMR install guide  
*   Run the command from the command line (or DOS Prompt) on your local machine where you installed elastic-mapreduce as outlined in the install guide above  
*   Linux/Mac  
````
./elastic-mapreduce --create --alive --name "RhipeCluster" --enable-debugging \
--num-instances 2 --slave-instance-type m1.large --master-instance-type m3.xlarge --ami-version "2.4.2" \
--with-termination-protection \
--key-pair <Your Key Pair> \
--log-uri s3://<bucket>/logs \
--bootstrap-action s3://elasticmapreduce/bootstrap-actions/configure-hadoop \
--args "-m,mapred.reduce.tasks.speculative.execution=false" \
--args "-m,mapred.map.tasks.speculative.execution=false" \
--args "-m,mapred.map.child.java.opts=-Xmx1024m" \
--args "-m,mapred.reduce.child.java.opts=-Xmx1024m" \
--args "-m,mapred.job.reuse.jvm.num.tasks=1" \
--bootstrap-action "s3://<bucket>/install-preconfigure" \
--bootstrap-action "s3://<bucket>/install-r" \
--bootstrap-action s3://elasticmapreduce/bootstrap-actions/run-if --args "instance.isMaster=true,s3://<bucket>/install-rstudio" \
--bootstrap-action s3://elasticmapreduce/bootstrap-actions/run-if --args "instance.isMaster=true,s3://<bucket>/install-shiny-server" \
--bootstrap-action s3://elasticmapreduce/bootstrap-actions/run-if --args "instance.isMaster=true,s3://<bucket>/install-post-hadoop" \
--bootstrap-action "s3://<bucket>/install-protobuf" \
--bootstrap-action "s3://<bucket>/install-rhipe" \
--bootstrap-action "s3://<bucket>/install-additional-pkgs" \
--bootstrap-action "s3://<bucket>/install-post-configure"  
````
  
*   Windows Users:  
    *   Run the following command from the DOS Prompt  
    `ruby elastic-mapreduce <all the above arguments on a single line>`  

You can monitor the progress on the EMR console  
https://console.aws.amazon.com/elasticmapreduce/vnext/home
  
## Post Instantiation Configuration ##
*****
Currently there a few steps that have not been automated that need to be done manually when the cluster has finished provisioning  
Once the cluster has been spun up (around 10 - 15 min) you can access the master node via ssh through the elastic-mapreduce CLI  

*   Linux/Mac  
`./elastic-mapreduce --ssh -j <job id from previous command>`  
(if you are familiar with EC2 you can access the master node via the ip address and pem as well)     
*   Windows Users:
    *   `ruby elastic-mapreduce -ssh -j <job id from previous command>`
    

### Open Ports ###
From the AWS EC2 web site, find the master node in the EC2 instance list and select the security group  

*   Select the "Inbound" tab
*	Click "Edit"  
*	Add "Custom TCP rule"  
*	"port range" = 8787  
*	"source" = your IP address OR Anywhere  

Repeat for ports (check that the port are not already available first): 22, 9100, 9103  

## Accessing RStudio ##
*****

From your local machine, using the IP address or public DNS of the master node  (listed in the cluster details on the AWS EMR console page above) from a  web browser navigate to http://[master ip address]:8787  
login as user3/user3  

## Common Problems ##
*****
*   Unable to ssh into master node:
    *   Verify that ssh port 22 is open in the security group for the master node as done above for rstudio above
    *   If using the elastic-mapreduce cli check that the credentials file has been setup and is named "credentials.json".  If using Windows, it may try to add a ".txt" extension to this file which will not work.
    *   If the elastic-mapreduce cli cannot find the key-pair named in the credentials file, make sure on AWS (EC2 -> key pair) the key-pair is in the same region as specified in the credentials file  
*   Some corporate networks block Amazon AWS IP addresses. In this case you can only run R by ssh'ing in and running R from the command line or by using an alternate network  
 
## Notes ##
*****
*   This is based on Amazon AMI image 2.4.2.  More current AMIs come with R 3.x preinstalled and will be looked at in the future
*   Amazon Hadoop 1.0.3 comes with Google proto bufs 2.4.1  
*   This script uses Rhipe 0.74 which depends on proto bufs 2.4.1  
*   Rhipe 0.75 is based on proto bufs 2.5.0 and initial testing was unsuccessful even with prot bufs 2.5 manually installed

## Known Issues ##
*****
*   "m1.large" or larger instance types must be used.  Smaller instance types have caused issues where hadoop is unable to start
*   Shiny server does not start during the bootstrapping and attempts to make it do so have not been successful.  After the cluster has started you must ssh into the master and start it manually:  
    `sudo -u shiny nohup shiny-server &`
