#!/bin/bash

source /etc/profile.modules
module load matlab/matlab2013a

cd /home/ali/adamli/fragility_dataanalysis/server/devFragility

## 00: Load in input parameters
proc="$1"
patient="$2"
currentWin="$3"
winSize="$4"
stepSize="$5"
radius="$6"
RUNCONNECTIVITY="$7"

## 01: Set parameters for matlab to run, and check if matlab is on path
matlab_jvm="matlab -nojvm -nodesktop -nosplash -r"
[[ ! -z "`which matlab`" ]] || \
	{ 
		echo "MATLAB not found on the PATH; please add to path."; 
		exit 1;
	}

# run adjacency computation and then run perturbation analysis on the same patient/seizure
# open matlab and call functions
# serverComputeConnectivity(currentpatient, $currentWin);\
if [[ "$RUNCONNECTIVITY" -eq 1 ]]; then
	echo "Running connectivity computation."
	matlab -logfile /home/ali/adamli/fragility_dataanalysis/server/devFragility/_log/job${3}.txt -nojvm -nodisplay -nosplash -r "currentpatient='${patient}'; \
	serverComputeConnectivity(currentpatient, ${winSize}, ${stepSize}, ${currentWin});
	exit;"
else
	echo "Running perturbation computation."
	# run perturbation analysis
	matlab -logfile /home/ali/adamli/fragility_dataanalysis/server/devFragility/_log/job${3}.txt -nojvm -nodisplay -nosplash -r "currentpatient='${patient}'; \
	serverComputePerturbations(currentpatient, ${winSize}, ${stepSize}, ${radius}, ${currentWin});\
	exit;"
fi