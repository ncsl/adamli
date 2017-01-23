#!/bin/bash

## 00: Load in input parameters
patient="$1"
RUNCONNECTIVITY="$2" 
numWins="$3"

NprocperNode=8    					# number of processors per node
Nnode=$((${3}/${NprocperNode}+1)) 	# the node to compute on
walltime=01:00:00					# the walltime for each computation

echo $Nnode
for inode in `seq 1 $Nnode`; do
	echo $inode
	currentNode=$((($inode-1)*$NprocperNode))

	if [[ "$RUNCONNECTIVITY" -eq 1 ]]; then
		jobname="compute_adjacency_${patient}_${inode}"
	else
		jobname="compute_perturbation_${patient}_${inode}"
	fi
	
	# run a pbs batch job. Make sure there are no spaces in between the parameters passed
	qsub -v RUNCONNECTIVITY=$RUNCONNECTIVITY,patient=$patient,currentNode=$currentNode -N ${jobname} -l nodes=1:ppn=${NprocperNode},walltime=${walltime} run_job.pbs
done

