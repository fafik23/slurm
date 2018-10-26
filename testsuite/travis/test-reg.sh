#!/bin/bash
export PATH=/usr/lib/ccache:$PATH

if [ -z "$TRAVIS_TAG" ]; then
    echo "Build is not for a git tag"
#    echo "Skiping test"
#    exit 0
fi

ulimit -c unlimited -S >/dev/null
ulimit -c
ulimit -a -S
ulimit -a -H
echo "/tmp/core.%e.%p.%h.%t" > /proc/sys/kernel/core_pattern

mount -t tmpfs cgroup_root /sys/fs/cgroup
mkdir /sys/fs/cgroup/cpuset
mount -t cgroup -ocpuset cpuset /sys/fs/cgroup/cpuset

mkdir /sys/fs/cgroup/freezer
mount -t cgroup -ofreezer cpuset /sys/fs/cgroup/freezer

mkdir /tmp/slurm/etc
mkdir /tmp/slurm_save

export PATH=$PATH:/tmp/slurm/bin/:/tmp/slurm/sbin/

cat >/tmp/slurm/etc/cgroup.conf <<EOL
CgroupMountpoint=/sys/fs/cgroup/
ConstrainCores=yes
EOL

cat >/tmp/slurm/etc/slurmdbd.conf <<EOL
AuthType=auth/munge
DbdAddr=localhost
DbdHost=localhost
SlurmUser=root
DebugLevel=0
PidFile=/var/run/slurmdbd.pid
StorageType=accounting_storage/mysql
StorageHost=localhost
StoragePort=3306
StorageUser=slurm
StorageLoc=slurm_acct_db
EOL

cat >/tmp/slurm/etc/slurm.conf <<EOL
ClusterName=test
ControlMachine=localhost
ControlAddr=localhost
SlurmUser=root

SlurmctldPort=6815
SlurmctldDebug=info
SlurmSchedLogLevel=0

SlurmdPort=6820
SlurmdDebug=info

AuthType=auth/munge
StateSaveLocation=/tmp/slurm_save
SlurmdSpoolDir=/tmp/slurmd_%n

SlurmctldPidFile=/var/run/slurmctld.pid
SlurmdPidFile=/var/run/slurmd%n.pid

ProctrackType=proctrack/cgroup
TaskPlugin=task/cgroup
JobAcctGatherType=jobacct_gather/linux

FirstJobId=1
MaxJobCount=30000

AccountingStorageType=accounting_storage/slurmdbd
AccountingStorageHost=localhost

SchedulerType=sched/backfill
SelectType=select/cons_res
SelectTypeParameters=CR_CPU_Memory

PriorityType=priority/multifactor

PriorityDecayHalfLife=14-0
PriorityCalcPeriod=10
PriorityUsageResetPeriod=NOW
PriorityWeightFairshare=1500
PriorityWeightAge=500
PriorityWeightPartition=1000
PriorityWeightJobSize=500
PriorityMaxAge=3-0
PriorityFavorSmall=NO

TmpFs=/tmp/
UsePAM=0

SwitchType=switch/none
MpiDefault=none
MpiParams=ports=12000-12999

ReturnToService=1
DefMemPerCPU=100

NodeName=test[01-09] NodeHostName=localhost CPUs=2 Sockets=1 CoresPerSocket=2 ThreadsPerCore=1 RealMemory=512 State=UNKNOWN Weight=120 Port=[30001-30009]
NodeName=test[11-19] NodeHostName=localhost CPUs=2 Sockets=1 CoresPerSocket=2 ThreadsPerCore=1 RealMemory=512 State=UNKNOWN Weight=120 Port=[30011-30019]

PartitionName=test      Nodes=test0[1-9],test[11-19] Default=YES MaxTime=168:00:00 State=up  DefMemPerCPU=100
PartitionName=test2             Nodes=test0[1-9],test[11-19]    MaxTime=168:00:00 State=up DefMemPerCPU=100

EOL

sudo mysql -uroot <<EOL
create database slurm_acct_db;
create user 'slurm'@'localhost';
grant all on slurm_acct_db.* TO 'slurm'@'localhost';
EOL

/usr/sbin/create-munge-key
service munge start

sleep 1
/tmp/slurm_db/sbin/slurmdbd
sleep 1
/tmp/slurm_db/bin/sacctmgr -i add cluster test

/tmp/slurm_ctl/sbin/slurmctld
sleep 1
/tmp/slurm_cli/bin/scontrol show hostname test[01-09,11-19]|xargs -n1 -IXXX  /tmp/slurm_d/sbin/slurmd -N XXX

cat > ./testsuite/expect/globals.local <<EOL
set slurm_dir     "/tmp/slurm_cli/"
set max_job_delay 100
EOL

cd ./testsuite/expect/
./regression.py -t -i $TEST_SET -k
rc=$?
for f in $(ls /tmp/core.* 2>/dev/null) ; do
    ff=$(basename $f |awk -F"." '{print $2}')
    gdb $ff $f -ex "thread apply all bt" -ex "set pagination 0" -batch

done

exit $rc
