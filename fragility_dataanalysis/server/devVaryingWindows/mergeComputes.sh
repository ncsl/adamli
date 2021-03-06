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

# run adjacency/perturbation merge
if [[ "$RUNCONNECTIVITY" -eq 1 ]]; then
	echo "Running connectivity computation."
	matlab -logfile /home/ali/adamli/fragility_dataanalysis/server/devVaryingWindows/_log/$2_merge_job$1.txt -nojvm -nodisplay -nosplash -r "currentpatient='$patient'; \
		mergeComputeConnectivity(currentpatient, $winSize, $stepSize);"
else
	echo "Running perturbation computation."
	# run perturbation analysis
	matlab -logfile /home/ali/adamli/fragility_dataanalysis/server/devVaryingWindows/_log/job$1.txt -nojvm -nodisplay -nosplash -r "currentpatient='$patient'; \
		mergeComputePerturbation(currentpatient, $radius, $winSize, $stepSize);"
fi