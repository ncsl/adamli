#!/bin/bash

#SBATCH
#SBATCH --mail-type=end
#SBATCH --mail-user=ali39@jhu.edu
#SBATCH --output=_err/%A_%a_merge.out 
#SBATCH --error=_err/%A_%a_merge.err

# Author: Adam Li (ali39@jhu.edu).
# Created on 2017-06-12. Last update on 6/12/17

# Load module (comment this to debug in sh mode)
module load matlab

# Debug output to make sure we are in the correct file
echo "Runninng sbatch merge file..."
echo ${SBATCH_JOB_NAME}
echo ${SLURM_SUBMIT_DIR}
echo ${winSize}
echo ${stepSize}
echo ${windows}
echo ${radius}

# run merges on either connectivity or perturbation computation
if [[ "$RUNCONNECTIVITY" -eq 1 ]]; then
	echo "Running connectivity merge."
	matlab -logfile _log/${SBATCH_JOB_NAME}.txt -nojvm -nodisplay -nodesktop -nosplash -r "\
	cd('matlab_lib');\
	mergeConnectivity('$patient', $winSize, $stepSize, $reference);"
else
	echo "Running perturbation merge."
	matlab -logfile _log/${SBATCH_JOB_NAME}.txt -nojvm -nodisplay -nodesktop -nosplash -r "\
	cd('matlab_lib');\
	mergePerturbation('$patient', $winSize, $stepSize, $radius, $reference);"
fi
