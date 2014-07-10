## Why prefix-emr.R ?

Though i made every effort to keep useful R packages in the binary tar archives,
I still forgot some. Once the cluster is up and running, how then to install an
R package on all the nodes? I do not know of a way on Elastic MapReduce.

One approach is to install R packages on the master node (the node you ssh into)
and then create an R bundle. That is the entire R distribution, the packages,
the binaries and all shared libraries that the connected graph of libraries
consist of. This is what the function `buildingR`in prefix-emr.R does.

When you source this file, it checks for the presence of Remr.tar.gz on the
HDFS. If it exists, it passes some options to RHIPE to use this archive to
execute R on the nodes. If not, it creates the bundle and saves it to the HDFS.

With this approach, if you need to install and R package which will be required
on the nodes, then, install the package on the master, rerun the `buildingR`
function (in a fresh R session)

```
library(Rhipe)
rhinit()
 buildingR(nameof="Remr", dest="/",verbose=100)
 ```

And then source prefix-emr.R and carry on as usual.

