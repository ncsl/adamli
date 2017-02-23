#!/bin/bash -l
cd /home/ali/adamli/fragility_dataanalysis/server/devFragility/

## 00: Load in input parameters
patient="$1"
RUNCONNECTIVITY="$2" 
numWins="$3"

NprocperNode=8    					# number of processors per node
NNodes=$(($NprocperNode-1))
Nnode=$((${3}/${NprocperNode}+1)) 	# the number of nodes to compute on
walltime=00:30:00					# the walltime for each computation

echo $Nnode
for ((inode=1; inode <= Nnode; inode++))
do
	echo $inode
	currentNode=$((($inode-1)*$NprocperNode))

	if [[ "$RUNCONNECTIVITY" -eq 1 ]]; then
		jobname="compute_adjacency_${patient}_${inode}"
	else
		jobname="compute_perturbation_${patient}_${inode}"
	fi
	
	echo "Submit job ${inode}"

	# if ((inode == Nnode)); then
	# 	if ((${numWins} < ${inode}*${NprocperNode})); then
	# 		NprocperNode=$((${inode}*${NprocperNode} - ${numWins} + 1))
	# 		echo "New NprocperNode"
	# 		echo $NprocperNode
	# 	elif ((${numWins} == ${inode}*${NprocperNode})); then
	# 	fi
	# fi

	# run a pbs batch job. Make sure there are no spaces in between the parameters passed
	qsub -v RUNCONNECTIVITY=${RUNCONNECTIVITY},patient=${patient},currentNode=${currentNode},NprocperNode=${NNodes} -N ${jobname} -l nodes=1:ppn=${NprocperNode},walltime=${walltime} run_job.pbs
done

