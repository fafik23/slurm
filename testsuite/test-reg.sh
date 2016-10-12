#!/bin/bash

sudo mount -t tmpfs cgroup_root /sys/fs/cgroup
sudo mkdir /sys/fs/cgroup/cpuset
sudo mount -t cgroup -ocpuset cpuset /sys/fs/cgroup/cpuset

sudo mkdir /sys/fs/cgroup/freezer
sudo mount -t cgroup -ofreezer cpuset /sys/fs/cgroup/freezer

mkdir /tmp/slurm/etc

export PATH=$PATH:/tmp/slurm/bin/:/tmp/slurm/sbin/

cat >/tmp/slurm/etc/cgroup.conf <<EOL
CgroupMountpoint=/sys/fs/cgroup/
ConstrainCores=yes
EOL

cat >/tmp/slurm/etc/cgroup.conf <<EOL
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
AccountingStorageEnforce=safe

SchedulerType=sched/backfill
SelectType=select/cons_res
SelectTypeParameters=CR_CPU_Memory
SchedulerParameters = default_queue_depth=2000,partition_job_depth=0,sched_interval=20,defer,bf_window=10080,bf_max_job_test=1000,bf_interval=45,bf_resolution=300,no_backup_scheduling,defer

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
PropagateResourceLimitsExcept=MEMLOCK,STACK
EnforcePartLimits=ANY

ReturnToService=1
DefMemPerCPU=100

NodeName=test[01-03] NodeHostName=localhost Sockets=1 CoresPerSocket=2 ThreadsPerCore=1 RealMemory=512 State=UNKNOWN Weight=120 Port=[30001-30003]
NodeName=test[11-13] NodeHostName=localhost Sockets=1 CoresPerSocket=2 ThreadsPerCore=1 RealMemory=512 State=UNKNOWN Weight=120 Port=[30011-30013]

PartitionName=test      Nodes=test0[1-3],test[11-13] Default=YES MaxTime=168:00:00      State=up  Priority=30 Shared=FORCE:1 DefMemPerCPU=100
PartitionName=test2             Nodes=test0[1-3],test[11-13]    MaxTime=168:00:00       MaxNodes=3 State=up  Priority=30 Shared=FORCE:1 DefMemPerCPU=100

EOL


sudo mysql -uroot <<EOL  
create database slurm_acct_db;
creat user slurm@localhost;
grant all on slurm_acct_db.* TO 'slurm'@'localhost';
EOL
sudo sacctmgr add cluster test
sudo slurmctld
sudo slurmdbd
scontrol show hostname test[01-03,11-13]|xargs -n1 -IXXX sudo slurmd -N XXX

sinfo

