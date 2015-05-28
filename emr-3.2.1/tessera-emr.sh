#!/bin/bash
# Argument = -t test -r server -p password -v

usage()
{
cat << EOF
This script launches an EMR Tessera cluster

OPTIONS:
   -h      Show this message
   -n      Number of worker nodes (default 2)
   -k      EC2 key-pair name
           (see key pairs in http://console.aws.amazon.com/ec2)
           If not specified, will use first listed key pair name
   -s      S3 bucket location to store scripts (required)
   -e      Flag to use EMRFS - if set, will use EMRFS for s3 consitency
   -m      Master instance type (default m1.large)
   -w      Worker instance(s) type (default m1.large)
   -u      Username for RStudio Server login (default tessera-user)
   -p      Password for RStudio Server login (default tessera - setting this is recommended)
   -c      CIDR block to use for security group for exposing RStudio Server (default is your IP only, for security purposes)

EXAMPLE USAGE:
./tessera-emr.sh -s s3://tessera-emr
./tessera-emr.sh -n 5 -s s3://tessera-emr -m m1.xlarge -w m1.xlarge

EOF
}

N_WORKERS=2
S3_BUCKET=
MASTER_TYPE=m1.xlarge
WORKER_TYPE=m1.large
USER=tessera-user
PASSWD=tessera
CIDR=$(curl -s http://checkip.amazonaws.com/)/32
KEY_PAIR_NAME=
AWS_RES_TAG_KEY=app
AWS_RES_TAG_VALUE=tessera
EMRFS=

while getopts ":hn:k:s:m:w:u:p:c:" OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
    n)
      N_WORKERS=$OPTARG
      ;;
    k)
      KEY_PAIR_NAME=$OPTARG
      ;;
    s)
      S3_BUCKET=$OPTARG
      ;;
    e)
      EMRFS="--emrfs Consistent=True"
      ;;
    m)
      MASTER_TYPE=$OPTARG
      ;;
    w)
      WORKER_TYPE=$OPTARG
      ;;
    u)
      USER=$OPTARG
      ;;
    p)
      PASSWD=$OPTARG
      ;;
    c)
      CIDR=$OPTARG
      ;;
    ?)
      usage
      exit
      ;;
  esac
done

if [[ -z $S3_BUCKET ]]
then
  echo "Must specify S3 bucket with -s option... exiting"
  exit 1
fi

echo ""
echo "** Note: Please follow your cluster status closely here:"
echo "**  https://console.aws.amazon.com/elasticmapreduce/"
echo "** and individual instance status here:"
echo "**  https://console.aws.amazon.com/ec2/"
echo "** Leaving instances running when not being used can be costly."
echo "** This script does not terminate clusters - that is your responsibility."
echo ""

if [[ -z $KEY_PAIR_NAME ]]
then
  echo "Key pair name not specified - selecting first listed key-pair from EC2..."
  KEY_PAIR_NAME=$(aws ec2 describe-key-pairs --output text --query 'KeyPairs[0].KeyName')

  if [[ -z $KEY_PAIR_NAME ]]
  then
    echo "Could not find a key pair name... exiting"
    exit 1
  fi
  echo "Using key-pair: $KEY_PAIR_NAME"
  echo ""
fi

echo "Syncing bootstrap scripts..."
aws s3 sync scripts $S3_BUCKET/scripts

SEC_GROUP_TCP_PORT_1=80
SEC_GROUP_TCP_PORT_2=3838

echo ""
echo "Checking for existing Security Groups…"

SEC_GROUP_ID=$(aws ec2 describe-security-groups --filters \
Name=tag-key,Values=$AWS_RES_TAG_KEY Name=tag-value,Values=$AWS_RES_TAG_VALUE \
Name=ip-permission.protocol,Values="tcp" \
Name=ip-permission.from-port,Values=$SEC_GROUP_TCP_PORT_1 Name=ip-permission.to-port,Values=$SEC_GROUP_TCP_PORT_1 \
Name=ip-permission.from-port,Values=$SEC_GROUP_TCP_PORT_2 Name=ip-permission.to-port,Values=$SEC_GROUP_TCP_PORT_2  \
Name=ip-permission.cidr,Values="$CIDR" \
--output text --query 'SecurityGroups[].GroupId')

if test -z "$SEC_GROUP_ID"
then
    # No existing Security Group, create.
    echo "Existing Security Group not found. Setting up new Security Group..."

    rstr=$(head -c 10 /dev/random | base64 | tr -dc 'a-zA-Z')
    GROUP_NAME=TesseraEMR-$rstr

    aws ec2 create-security-group --group-name $GROUP_NAME --description "web access"
    aws ec2 authorize-security-group-ingress --group-name $GROUP_NAME --protocol tcp --port 80 --cidr $CIDR
    aws ec2 authorize-security-group-ingress --group-name $GROUP_NAME --protocol tcp --port 3838 --cidr $CIDR

    # get group id to send to create-cluster
    SEC_GROUP_ID=$(aws ec2 describe-security-groups --group-names $GROUP_NAME --output text --query 'SecurityGroups[].GroupId')

    # Taggin created Security Group
    aws ec2 create-tags --resources $SEC_GROUP_ID --tags Key=$AWS_RES_TAG_KEY,Value=$AWS_RES_TAG_VALUE
else
    # Existing security group found.
    echo "Using existing Security Group with ID $SEC_GROUP_ID"
fi

echo ""
echo "Launching cluster..."

CLUSTER_ID=$(aws emr create-cluster \
--name "Tessera" \
--enable-debugging --log-uri $S3_BUCKET/logs \
--ami-version 3.2.1 $EMRFS \
--no-auto-terminate \
--no-visible-to-all-users \
--use-default-roles \
--instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=$MASTER_TYPE InstanceGroupType=CORE,InstanceCount=$N_WORKERS,InstanceType=$WORKER_TYPE \
--ec2-attributes KeyName=$KEY_PAIR_NAME,AdditionalMasterSecurityGroups=[$SEC_GROUP_ID] \
--bootstrap-actions Path=s3://elasticmapreduce/bootstrap-actions/configure-hadoop,Args=[\
-m,mapred.reduce.tasks.speculative.execution=false,\
-m,mapred.map.tasks.speculative.execution=false,\
-m,mapred.map.child.java.opts=-Xmx1024m,\
-m,mapred.reduce.child.java.opts=-Xmx1024m,\
-m,mapred.job.reuse.jvm.num.tasks=1] \
--bootstrap-actions \
Path=$S3_BUCKET/scripts/install-tessera.sh \
Path=s3://elasticmapreduce/bootstrap-actions/run-if,Args=["instance.isMaster=true",$S3_BUCKET/scripts/install-tessera-master.sh] \
--steps Type=CUSTOM_JAR,Name=CustomJAR,ActionOnFailure=CONTINUE,Jar=s3://elasticmapreduce/libs/script-runner/script-runner.jar,Args=["$S3_BUCKET/scripts/post-install-config.sh",$USER,$PASSWD] \
--output text --query ClusterId)

echo "Tagging cluster…"
aws emr add-tags --resource-id $CLUSTER_ID --tags $AWS_RES_TAG_KEY=$AWS_RES_TAG_VALUE

echo ""
echo "Cluster started $(date)..."
echo "Cluster ID is $CLUSTER_ID"
echo "Waiting for bootstrap actions (could take over 15 minutes)"
echo "Check status here:"
echo " https://console.aws.amazon.com/elasticmapreduce/"
echo "To terminate the cluster at any time, do the following:"
echo " aws emr terminate-clusters --cluster-ids $CLUSTER_ID"

# loop until cluster is ready
while : ; do
  # check status
  STATE=$(aws emr describe-cluster --cluster-id $CLUSTER_ID --output text --query 'Cluster.Status.State')
  echo -n ". "
  if [ $STATE = "WAITING" ]; then
    echo ""
    echo "Cluster is ready!"
    break
  fi
  sleep 5
done

# get IP address of master
EMR_MASTER_IP=$(aws emr describe-cluster --cluster-id $CLUSTER_ID --output text --query 'Cluster.MasterPublicDnsName')

echo ""
echo "You can log in to your cluster with the following:"
echo " ssh hadoop@$EMR_MASTER_IP -i __path_to_pem_file__"
echo "More conveniently, you can log in to RStudio Server w/ credentials $USER:$PASSWD by visiting here in your web browser:"
echo " http://$EMR_MASTER_IP"
echo ""
echo "To install additional packages on all nodes of the cluster:"
echo " ./install-package.sh $CLUSTER_ID $S3_BUCKET __package_name__"
echo "or if it's a github package:"
echo " ./install-package-gh.sh $CLUSTER_ID $S3_BUCKET __user/repo__"
echo "To terminate the cluster, do the following:"
echo " aws emr terminate-clusters --cluster-ids $CLUSTER_ID"

exit 0

