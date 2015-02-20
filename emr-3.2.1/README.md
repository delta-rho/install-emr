# Tessera Environment on Amazon EMR AMI 3.2.1 #
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
*   Upload all `emr-3.2.1/install-*` scripts, Rhipe_*.tag.gz  to your S3 Bucket and optionally `post-install-config.sh` (more info below) 
    *   This can be done through the AWS S3 web site
*   Copy the command below (or run the script launch-cluster.sh - see below) to your favorite text editor then replace `<bucket>` with your own S3 bucket (and path if different) and specify the key-pair you just made in the Amazon EMR install guide  
*   Run the command from the command line (or DOS Prompt) on your local machine where you installed elastic-mapreduce as outlined in the install guide above  
*   Linux/Mac  
**NOTE**  
The last line of this command  
`--script s3://<bucket>/post-install-config.sh`  
Is an optional step used to setup a multiuser environment and stage data. 
````
./elastic-mapreduce --create --alive --name "RhipeCluster" --enable-debugging \
--num-instances 2 --slave-instance-type m1.large --master-instance-type m3.xlarge --ami-version 3.2.1 \
--with-termination-protection \
--key-pair <Your Key Pair> \
--log-uri s3://<bucket>/logs \
--bootstrap-action s3://elasticmapreduce/bootstrap-actions/configure-hadoop \
--args "-m,mapred.reduce.tasks.speculative.execution=false" \
--args "-m,mapred.map.tasks.speculative.execution=false" \
--args "-h,dfs.umaskmode=000" \
--args "-h,dfs.permissions=true" \
--bootstrap-action "s3://<bucket>/install-tessera" \
--bootstrap-action s3://elasticmapreduce/bootstrap-actions/run-if --args "instance.isMaster=true,s3://<bucket>/install-tessera-master" \
--script s3://<bucket>/post-install-config.sh --args "<user count>"  
````
  
*   Alternatively you can run the "launch-cluster.sh" script  
`launch-cluster name keypair-name s3-bucket`  

*   Windows Users:  
    *   Run the following command from the DOS Prompt  
    `ruby elastic-mapreduce <all the above arguments on a single line>`  

You can monitor the progress on the EMR console  
https://console.aws.amazon.com/elasticmapreduce/vnext/home
  
## Post Instantiation Configuration ##
*****
*   Accessing your server  
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
*	"port range" = 80
*	"source" = your IP address OR Anywhere  

Repeat for ports (check that the port are not already available first): 22, 9100, 9103  

## Accessing RStudio ##
*****

From your local machine, using the IP address or public DNS of the master node  (listed in the cluster details on the AWS EMR console page above) from a  web browser navigate to http://[master ip address]  
login as the user you have created and setup  
Or if you ran the post-install-config.sh script login as bootcamp-user-1/bootcamp

## Common Problems ##
*****
*   Unable to ssh into master node:
    *   Verify that ssh port 22 is open in the security group for the master node as done above for rstudio above
    *   If using the elastic-mapreduce cli check that the credentials file has been setup and is named "credentials.json".  If using Windows, it may try to add a ".txt" extension to this file which will not work.
    *   If the elastic-mapreduce cli cannot find the key-pair named in the credentials file, make sure on AWS (EC2 -> key pair) the key-pair is in the same region as specified in the credentials file  
*   Some corporate networks block Amazon AWS IP addresses. In this case you can only run R by ssh'ing in and running R from the command line or by using an alternate network  
 
## Notes ##
*****
*   This is based on Amazon AMI image 3.2.1  
*   This script uses Rhipe 0.75 which depends on proto bufs 2.5.0  

## Known Issues ##
*****
*   "m1.large" or larger instance types must be used.  Smaller instance types have caused issues where hadoop is unable to start  
*   A user must be properly configured to access rstudio and run RHIPE.  The post-install-config.sh does this.  Customize as needed.
