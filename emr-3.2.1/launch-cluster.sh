if [ $# -ne 3 ]
  then
    echo "Usage:"
    echo "launch-cluster name keypair-name s3-bucket"
    echo "copy script to elastic-mapreduce-cli directory and run from there"
    exit -1;
fi

./elastic-mapreduce --create --alive --name $1 --enable-debugging \
--num-instances 2 --slave-instance-type m1.large --master-instance-type m3.xlarge --ami-version 3.2.1 \
--with-termination-protection \
--key-pair $2 \
--log-uri s3://$3/logs \
--bootstrap-action s3://elasticmapreduce/bootstrap-actions/configure-hadoop \
--args "-m,mapred.reduce.tasks.speculative.execution=false" \
--args "-m,mapred.map.tasks.speculative.execution=false" \
--args "-m,mapred.map.child.java.opts=-Xmx1024m" \
--args "-m,mapred.reduce.child.java.opts=-Xmx1024m" \
--args "-m,mapred.job.reuse.jvm.num.tasks=1" \
--bootstrap-action "s3://$3/install-tessera.sh" \
--bootstrap-action s3://elasticmapreduce/bootstrap-actions/run-if --args "instance.isMaster=true,s3://$3/install-tessera-master.sh" \
--script s3://$3/post-install-config.sh --args "1"

#--num-instances 2 --slave-instance-type m1.large --master-instance-type m3.xlarge --ami-version 3.2.1 \
