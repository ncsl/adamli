#!/bin/bash -l
cd /home/ali/adamli/fragility_dataanalysis/server/devFragility/

# $patient $winSize $stepSize $radius $numWins $RUNCONNECTIVITY
## 00: Load in input parameters
patient="$1"
winSize="$2"
stepSize="$3"
radius="$4"
numWins="$5"
RUNCONNECTIVITY="$6" 

NprocperNode=8    						# number of processors per node
NNodes=$(($NprocperNode-1))
Nnode=$((${numWins}/${NprocperNode}+1)) # the number of nodes to compute on

# 03: Parameters for each pbs job.
if [[ "${RUNCONNECTIVITY}" -eq 1 ]]; then
	walltime=00:05:00
else
	walltime=00:10:00					# the walltime for each computation
fi

# 04: Loop through each node
for ((inode=1; inode <= Nnode; inode++))
do
	echo $iWin
	currentNode=$((($inode-1)*$NprocperNode))
	# currentNode=$((($iWin+7)/NprocperNode))

	# set pbs job name
	if [[ "$RUNCONNECTIVITY" -eq 1 ]]; then
		jobname="compute_adjacency_${patient}_${currentNode}"
	else
		jobname="compute_perturbation_${patient}+${currentNode}"
	fi
	
	echo "Submit job for ${currentNode}"

	# run a pbs batch job. Make sure there are no spaces in between the parameters passed
	qsub -v RUNCONNECTIVITY=${RUNCONNECTIVITY},patient=${patient},winSize=${winSize},stepSize=${stepSize},radius=${radius},currentNode=${currentNode},NprocperNode=${NNodes} -N ${jobname} -l nodes=1:ppn=${NprocperNode},walltime=${walltime} run_job.pbs
done