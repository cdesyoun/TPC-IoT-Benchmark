#!/bin/bash
################################################################################
#  Designed to run on SDSC's Comet resource.
################################################################################
#SBATCH -A test1234
#SBATCH --job-name="tpc-iot"
#SBATCH --output="tpc-iot.%j.%N.out"
#SBATCH --partition=compute
#SBATCH --nodes=5
#SBATCH --ntasks-per-node=24
#SBATCH --export=ALL
#SBATCH -t 20:00:00

#SBATCH --res=klin_1743
##########################SBATCH --mem=10g

### Environment setup for Hadoop and Hbase
export HADOOP_HOME=$HOME/hadoop-stack/hadoop-2.6.5
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH
export HBASE_HOME=$HOME/hadoop-stack/hbase-1.2.6
export PATH=$HBASE_HOME/bin:$PATH

export HADOOP_CONF_DIR=$HOME/hadoop-stack/mycluster.conf
export HBASE_CONF_DIR=$HADOOP_CONF_DIR
export WORKDIR=`pwd`

export JAVA_OPTIONS="-Xms256M -Xmx512M -XX:MaxPermSize=512M -Djava.awt.headless=true"
export JVMFLAGS="-Djute.maxbuffer=4294967296"
export SERVER_JVMFLAGS=$JVMFLAGS

ulimit -n 32768
ulimit -u 32768
ulimit -u 

myhadoop-configure.sh

for node in $(cat $HADOOP_CONF_DIR/hdfs-nodes | sort -u )
do
    ssh $node "ulimit -n 32768"
    ssh $node "ulimit -u 32768"
done

### Start HDFS.
start-dfs.sh
# start-all.sh

echo "======================================="
cp mycluster.conf/masters /home/klin/TPCx-IoT-v1.0.3/client_driver_host_list.txt
cp mycluster.conf/tpc-node /home/klin/TPCx-IoT-v1.0.3/client_host_list.txt

for node in $(cat $HADOOP_CONF_DIR/masters | sort -u )
do
    ssh $node "start-hbase.sh"
done

### RUN TPCx-IoT-master.sh
echo "======================================="
echo "Change the working directory"
cd /home/klin/TPCx-IoT-v1.0.3
pwd

echo "Start TPC-IoT-master.sh"
module load python/2.7.10
export PYTHONPATH=$PYTHONPATH:~/.local/lib
export PATH=$PATH:~/.local/bin
/home/klin/TPCx-IoT-v1.0.3/TPC-IoT-master.sh
echo "TPC-IoT-master.sh completed"

