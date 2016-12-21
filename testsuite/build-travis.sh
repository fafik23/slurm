#!/bin/bash

MIGRATION=${MIGRATION-0}

if [[ "$SLURMD_VER" != "$TRAVIS_BRANCH" ]] && [ $MIGRATION -eq 1 ] ; then
	git checkout $SLURMD_VER
	echo "Compile $SLURM for Slurmd"
	./configure --enable-multiple-slurmd --prefix=/tmp/slurm_d/ > /dev/null
	make -j > /dev/null
	make -j install > /dev/null
	ln -s /tmp/slurm/etc /tmp/slurm_d/etc
else
	ln -s /tmp/slurm /tmp/slurm_d
fi

if [[ "$SLURMCTL_VER" != "$TRAVIS_BRANCH" ]] && [ $MIGRATION -eq 1 ] ; then
	git checkout $SLURMCTL_VER
	echo "Compile $SLURMCTL_VER for SlurmCTL"
	./configure --enable-multiple-slurmd --prefix=/tmp/slurm_ctl/ > /dev/null
	make -j > /dev/null
	make -j install > /dev/null
	ln -s /tmp/slurm/etc /tmp/slurm_ctl/etc
else
	ln -s /tmp/slurm /tmp/slurm_ctl
fi

if [[ "$SLURMCLI_VER" != "$TRAVIS_BRANCH" ]] && [ $MIGRATION -eq 1 ] ; then
	echo "Compile $SLURMCLI_VER for Slurm CLI"
	git checkout $SLURMCLI_VER
	./configure --enable-multiple-slurmd --prefix=/tmp/slurm_cli/ > /dev/null
	make -j > /dev/null
	make -j install > /dev/null
	ln -s /tmp/slurm/etc /tmp/slurm_cli/etc
else
	ln -s /tmp/slurm /tmp/slurm_cli
fi

if [[ "$SLURMDB_VER" != "$TRAVIS_BRANCH" ]] && [ $MIGRATION -eq 1 ] ; then
	echo "Compile $SLURMDB_VER for SlurmDB"
	git checkout $SLURMDB_VER
	./configure --enable-multiple-slurmd --prefix=/tmp/slurm_db/ > /dev/null
	make -j > /dev/null
	make -j install > /dev/null
	ln -s /tmp/slurm/etc /tmp/slurm_d/etc
else
	ln -s /tmp/slurm /tmp/slurm_db
fi

git checkout $TRAVIS_BRANCH
