#!/bin/bash -l
# This script runs the computation/estimation of adjacency matrices
source /etc/profile.modules
module load matlab/matlab2013a

## 00: Load in input parameters
proc="$1"
patient="$2"
stepSize=$winSize
## 01: Set parameters for matlab to run, and check if matlab is on path
matlab_jvm="matlab -nojvm -nodesktop -nosplash -r"
[[ ! -z "`which matlab`" ]] || \
	{ 
		echo "MATLAB not found on the PATH; please add to path."; 
		exit 1;
	}

# winSize=500
# stepSize=500
radius=1.5

echo $winSize
echo $stepSize
echo $radius
echo $RUNCONNECTIVITY

# run adjacency computation and then run perturbation analysis on the same patient/seizure
# open matlab and call functions
if [[ "$RUNCONNECTIVITY" -eq 1 ]]; then
	echo "Running connectivity computation."
	matlab -logfile /home/ali/adamli/fragility_dataanalysis/server/_log/job$1.txt -nojvm -nodisplay -nosplash -r "currentpatient='$patient'; \
		serverAdjMainScript(currentpatient, $winSize, $stepSize);\
		exit"
else
	echo "Running perturbation computation."
	# run perturbation analysis
	matlab -logfile /home/ali/adamli/fragility_dataanalysis/server/_log/job$1.txt -nojvm -nodisplay -nosplash -r "currentpatient='$patient'; \
	serverPerturbationScript(currentpatient, $radius, $winSize, $stepSize, $center);\
	exit"
fi
fi