#!/bin/bash -l
# This script runs the computation/estimation of adjacency matrices
source /etc/profile.modules
module load matlab/matlab2013a

## 00: Load in input parameters
$proc=$1
$patient_id=$2
$seizure_id=$3
$perturbationType=$4 

## 01: Set parameters for matlab to run, and check if matlab is on path
matlab_jvm="matlab -nojvm -nodesktop -nosplash -r"
[[ ! -z "`which matlab`" ]] || \
	{ 
		echo "MATLAB not found on the PATH; please add to path."; 
		exit 1;
	}
## 02: Run matlab job for each window
for index in `seq 0 5`
do
	index=$((proc+1))
	jobnum=$((24\*job)) # set index for the window
	index=$((index+jobnum))

	# open matlab and call functions
	matlab -logfile /home/ali/adamli/fragility_dataanalysis/_log/job$1.txt -nojvm \ 
	-nodisplay -nosplash -r "patient_id='$patient_id'; \
 			seizure_id='$seizure_id'; \
 			serverMainScript; \
 			leastSquaresAdjMat($index, eeg, included_channels, patient, \
	          winSize, stepSize, ezone_labels, earlyspread_labels, latespread_labels); exit"
done