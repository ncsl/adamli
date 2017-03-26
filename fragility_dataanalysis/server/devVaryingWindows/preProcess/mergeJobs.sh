#!/bin/bash -l
# This script runs the computation/estimation of adjacency matrices
source /etc/profile.modules
module load matlab/matlab2013a

## 00: Load in input parameters
proc="$1"
patient="$2"
winSize="$3"
stepSize="$4"
typeTransform="$5"


## 01: Set parameters for matlab to run, and check if matlab is on path
matlab_jvm="matlab -nojvm -nodesktop -nosplash -r"
[[ ! -z "`which matlab`" ]] || \
{ 
	echo "MATLAB not found on the PATH; please add to path."; 
	exit 1;
}

# run spectral merge
echo "Running spectral merge..."
matlab -logfile /home/ali/adamli/fragility_dataanalysis/server/devVaryingWindows/_log/job$1.txt -nojvm -nodisplay -nosplash -r "currentpatient='$patient'; \
		mergeChannelSpectrum(currentpatient, $winSize, $stepSize, '$typeTransform');"