#!/bin/bash

#SBATCH
#SBATCH --mail-type=end
#SBATCH --mail-user=ali39@jhu.edu
#SBATCH --output=_err/%A_%a_windows.out 
#SBATCH --error=_err/%A_%a_windows.err

# Author: Adam Li (ali39@jhu.edu).
# Created on 2017-09-03. 

# Load module (comment this to debug in sh mode)
module load matlab

# Debug output to make sure we are in the correct file
echo "Runninng sbatch windows file..."
echo ${SBATCH_JOB_NAME}
echo ${SLURM_SUBMIT_DIR}
echo ${winSize}
echo ${stepSize}
echo ${window}
echo ${radius}

# run merges on either connectivity or perturbation computation
if [[ "$RUNCONNECTIVITY" -eq 1 ]]; then
	matlab -logfile _log/${SBATCH_JOB_NAME}_${window}.txt -nojvm -nodisplay -nodesktop -nosplash -r "\
		cd('matlab_lib');\
		parallelComputeConnectivity('$patient', $winSize, $stepSize, ${window});"
else
	matlab -logfile _log/${SBATCH_JOB_NAME}_${window}.txt -nojvm -nodisplay -nodesktop -nosplash -r "\
		cd('matlab_lib');\
		parallelComputePerturbation('$patient', $winSize, $stepSize, $radius, ${window});"
fi
