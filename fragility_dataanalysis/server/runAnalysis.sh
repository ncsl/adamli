#!/bin/bash -l
# This script runs the computation/estimation of adjacency matrices
source /etc/profile.modules
module load matlab/matlab2013a

## 00: Load in input parameters
proc="$1"
patient_id="$2"
seizure_id="$3"
perturbationType="$4" 

# echo $proc
# echo $patient_id
# echo $seizure_id
# echo $perturbationType

## 01: Set parameters for matlab to run, and check if matlab is on path
matlab_jvm="matlab -nojvm -nodesktop -nosplash -r"
[[ ! -z "`which matlab`" ]] || \
	{ 
		echo "MATLAB not found on the PATH; please add to path."; 
		exit 1;
	}
## 02: Run matlab job for each window
for ind in `seq 0 0`
do
	winIndex=$(($proc+1))
	job=$((24*ind))
	winIndex=$((index+job))
	echo $winIndex

	# open matlab and call functions
	matlab -logfile /home/ali/adamli/fragility_dataanalysis/server/_log/job$1.txt -nojvm -nodisplay -nosplash -r "patient_id='$patient_id'; \
 			seizure_id='$seizure_id'; \
 			serverEZTMainScript; \
 			serverLeastSquaresAdjMat($winIndex, eeg, metadata); exit"
done