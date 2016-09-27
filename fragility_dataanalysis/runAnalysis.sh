#!/Documents/adamli/fragility_dataanalysis/bash
# This script runs the computation/estimation of adjacency matrices

clear # clear terminal window

echo "Begin estimation of adjacency matrices."
cd $PBS_O_WORKDIR				# go to the working directory

# set parameters for matlab to run, and check if matlab is on path
matlab_jvm = "matlab -nojvm -nodesktop -nosplash -r"
[[ ! -z "`which matlab`" ]] || \
	{ 
		echo "MATLAB not found on the PATH; please add to path."; 
		exit 1;
	}

$matlab_jvm "mainScript; exit"


# winSize = 500
# stepSize = 500
# timeRange = [-60, 20]


# computeAdjMats(patient_id, seizure_id, included_channels, ...
#     timeRange, winSize, stepSize, ezone_labels, earlyspread_labels, latespread_labels)