#!/bin/bash

aws emr add-steps --cluster-id $1 \
--steps Type=CUSTOM_JAR,Name=InstallPackage,ActionOnFailure=CONTINUE,Jar=s3://elasticmapreduce/libs/script-runner/script-runner.jar,Args=["$2/scripts/install-package.sh","$3"]

