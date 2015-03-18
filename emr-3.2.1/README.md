Tessera Environment on Amazon EMR
=================================

**Note:** These scripts are experimental.  We would appreciate users testing them out and using them and providing feedback / fixes.

### Prerequisites ###

- An Amazon AWS account with properly set up security groups and policies
- An s3 bucket
- AWS Command Line Interface

If you don't have these prerequisites, they will be covered in more detail below.

### Installation ###

You can install the scripts simply by cloning the github respository.

```bash
git clone https://github.com/tesseradata/install-emr
cd install-emr/emr-3.2.1
```

### Usage ###

If you have the prerequisites and you have a bash shell, you can simply simply call tessera-emr.sh as follows:

```bash
./tessera-emr.sh -s <s3 bucket>
```

To see more options (number of workers, instance types, etc.):

```bash
./tessera-emr.sh -h
```

This script does the following:

- Syncs the custom Tessera bootstrap scripts to a "scripts" folder in your s3 bucket
- Creates a security group to allow RStudio Server to be served over port 80 (by default open to just your IP address)
- Launches the EMR cluster and installs and configures all Tessera components

Once your cluster is up and running, if you need to install additional R packages on the nodes, there are some helper scripts for this:

```bash
# CRAN package
./install-package.sh <cluster id> <s3 bucket> rvest
# github package
./install-package-gh.sh <cluster id> <s3 bucket> bokeh/rbokeh
```

If you want finer control over things, take a look at tessera-emr.sh and modify the `aws create-cluster` command for your needs.

**Please note that you are responsible for making sure that instances you have started are terminated when you are done.  Please familiarize yourself with the following resources for monitoring usage, and check them frequently.  It is your responsibility to monitor and handle your resource usage.**

- **[AWS Console](http://console.aws.amazon.com/) -> EMR** ([direct link](https://console.aws.amazon.com/elasticmapreduce/)) - you can view running EMR clusters and terminate them here
- **[AWS Console](http://console.aws.amazon.com/) -> EC2 -> Instances** ([direct link](https://console.aws.amazon.com/ec2/)) - you can view running instances and terminate them here
- **[AWS Console](http://console.aws.amazon.com/) -> Menu Bar -> (username dropdown) -> Billing and Cost Management**: you can view your account balance here

#### Set up an AWS account ####

If you don't already have an AWS account, go to [http://aws.amazon.com](http://aws.amazon.com) and click the button that says "Create a Free Account" or if you have logged in to the system before, the button will say something like "Sign in to the Console".

You can sign in if you have an existing amazon.com account or create a new account.

#### Set up account credentials ####

- Sign in to the [AWS management console](http://console.aws.amazon.com/)
- Click on "Identity and Access Management"
- Click on "Users" and then click the "Create New Users" button and create your user
- After you have created the user, click the "Download Credentials" button - this will give you a file, `credentials.csv`, with your user's key and secret key that will be used when we configure the AWS Command Line Interface
- Click on "Groups" and click the "Create New Group" button
- Call the group what you'd like, e.g. "tessera"
- Attach the following two policies to the group: `AmazonDynamoDBFullAccess`, `AmazonElasticMapReduceFullAccess`
- Now click "Groups" and click on the entry of the group you just created
- Click the "Add Users to Group" button and select your user

#### Get an EC2 key pair ####

- Sign in to the [AWS management console](http://console.aws.amazon.com/)
- Click on "EC2"
- Click on "Key Pairs" under "Network & Security"
- Click the "Create Key Pair" button
- Name it what you'd like, e.g. "tessera-emr"
- A file with that name and a .pem extension will be downloaded
- You can put this file where you'd like but treat it with care (don't share with anyone or put it anywhere where others can get it)
- You can put it in the emr-3.2.1 directory of this repo if you'd like (but don't check it in to git)

#### Set up an s3 bucket ####

We will use this to store the EMR startup scripts and you can also use it to store your HDFS data.

- Sign in to the [AWS management console](http://console.aws.amazon.com/)
- Click "S3"
- Click the "Create Bucket" button and go through the steps
- Enable logging for the bucket with the default prefix "logs/"
- Make sure you make note of the Region you choose

#### Get the AWS command line interface ####

The AWS CLI uses Python so make sure you have that installed.

Instructions for how to install the AWS CLI can be found [here](http://docs.aws.amazon.com/cli/latest/userguide/installing).

#### Configure AWS CLI ####

Follow the instrutions [here](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) to configure the AWS CLI.

Some notes:

- Use your user `credentials.csv` file you downloaded when you created the user to get your key and secret key
- If you don't have this file, follow this [guide](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSGettingStartedGuide/AWSCredentials.html).
- To see the possibilities for "region", look at the codes [here](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html) - it is a good idea to choose the same one as your s3 bucket
- You can choose the default value for "output" - it doesn't matter which you choose

You should now be ready to run tessera-emr.sh as outlined at the beginning of this README.

#### Notes ####

- `m1.large` or larger instance types must be used.  Smaller instance types have caused issues where hadoop is unable to start.
- These scripts set up EMR with EMRFS enabled, meaning that you can use s3 buckets as your hadoop storage.  This is convenient for keeping storage persistent from cluster to cluster.
- Each time a cluster is started a new security group is created with a name `TesseraEMR-xxxxxx`.  Periodically you may want to check your security groups and clean out old groups with this prefix.

