#!/bin/bash -l
# This script runs the computation/estimation of adjacency matrices
source /etc/profile.modules
module load matlab/matlab2013a

cd /home/ali/adamli/fragility_dataanalysis/server/devVaryingWindows/


## 00: Load in input parameters
proc="$1"
patient="$2"
winSize="$3"
stepSize="$4"
radius="$5"
RUNCONNECTIVITY="$6"
numProcs="$7"

# ${proc} ${patient} ${currentWin} ${winSize} ${stepSize} ${radius} ${RUNCONNECTIVITY}
## 01: Set parameters for matlab to run, and check if matlab is on path
matlab_jvm="matlab -nojvm -nodesktop -nosplash -r"
[[ ! -z "`which matlab`" ]] || \
	{ 
		echo "MATLAB not found on the PATH; please add to path."; 
		exit 1;
	}

echo $winSize
echo $stepSize
echo $proc
echo $numProcs

# run adjacency computation and then run perturbation analysis on the same patient/seizure
# open matlab and call functions
if [[ "$RUNCONNECTIVITY" -eq 1 ]]; then
	echo "Running connectivity computation."
	matlab -logfile /home/ali/adamli/fragility_dataanalysis/server/devVaryingWindows/_log/$2_job$1.txt -nojvm -nodisplay -nosplash -r "currentpatient='$patient'; \
		parallelComputeConnectivity(currentpatient, $winSize, $stepSize, $proc, $numProcs);"
else
	echo "Running perturbation computation."
	# run perturbation analysis
	matlab -logfile /home/ali/adamli/fragility_dataanalysis/server/devVaryingWindows/_log/job$1.txt -nojvm -nodisplay -nosplash -r "currentpatient='$patient'; \
		parallelComputePerturbation(currentpatient, $winSize, $stepSize, $radius, $proc, $numProcs);"
		# serverPerturbationScript(currentpatient, $radius, $winSize, $stepSize);"
fi

