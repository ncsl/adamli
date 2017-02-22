#!/bin/bash -l
source /etc/profile.modules
module load matlab/matlab2013a

## 00: Load in input parameters
proc="$1"
patient="$2"
currentWin="$3"
RUNCONNECTIVITY="$4"

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
	serverComputeConnectivity(currentpatient,${currentWin});\
		fprintf('it is working.');"
else
	echo "Running perturbation computation."
	# run perturbation analysis
	matlab -logfile /home/ali/adamli/fragility_dataanalysis/server/devFragility/_log/job${3}.txt -nojvm -nodisplay -nosplash -r "currentpatient='${patient}'; \
	serverComputePerturbations(currentpatient, ${currentWin});"
fi