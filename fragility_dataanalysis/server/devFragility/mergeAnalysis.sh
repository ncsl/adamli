#!/bin/bash -l
# This script runs the computation/estimation of adjacency matrices
source /etc/profile.modules
module load matlab/matlab2013a

## 00: Load in input parameters
proc="$1"
patient="$2"
winSize="$3"
stepSize="$4"
radius="$5"
RUNCONNECTIVITY="$6"

## 01: Set parameters for matlab to run, and check if matlab is on path
matlab_jvm="matlab -nojvm -nodesktop -nosplash -r"
[[ ! -z "`which matlab`" ]] || \
{ 
	echo "MATLAB not found on the PATH; please add to path."; 
	exit 1;
}

# run analysis merge
# serverComputeConnectivity(currentpatient, $currentWin);\
if [[ "$RUNCONNECTIVITY" -eq 1 ]]; then
	echo "Running connectivity merging."
	matlab -logfile /home/ali/adamli/fragility_dataanalysis/server/devFragility/_log/job${3}.txt -nojvm -nodisplay -nosplash -r "currentpatient='${patient}'; \
	serverMergeConnectivity(currentpatient, $winSize, $stepSize);\
	exit;"
else
	echo "Running perturbation merging."
	# run perturbation analysis
	matlab -logfile /home/ali/adamli/fragility_dataanalysis/server/devFragility/_log/job${3}.txt -nojvm -nodisplay -nosplash -r "currentpatient='${patient}'; \
	serverMergePerturbation(currentpatient, $winSize, $stepSize, $radius);\
	exit;"
fi