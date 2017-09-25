#!/bin/bash

#SBATCH
#SBATCH --mail-type=end
#SBATCH --mail-user=ali39@jhu.edu
#SBATCH --output=_err/%A_%a.out 
#SBATCH --error=_err/%A_%a.err

# Author: Adam Li (ali39@jhu.edu).
# Created on 2017-05-22. Last update on 6/1/17

# cd ./matlab\ lib/

# Load module (comment this to debug in sh mode)
module load matlab

# Debug output to make sure we are in the correct file
echo "Runninng sbatch file..."
echo ${SBATCH_JOB_NAME}
echo ${SLURM_SUBMIT_DIR}
echo ${SLURM_ARRAY_TASK_ID}

if [[ "$RUNCONNECTIVITY" -eq 1 ]]; then
	matlab -logfile _log/${SBATCH_JOB_NAME}_${SLURM_ARRAY_TASK_ID}.txt -nojvm -nodisplay -nodesktop -nosplash -r "\
		cd('matlab_lib');\
		parallelComputeConnectivity('$patient', $winSize, $stepSize, '$reference', ${SLURM_ARRAY_TASK_ID});"
else
	matlab -logfile _log/${SBATCH_JOB_NAME}_${SLURM_ARRAY_TASK_ID}.txt -nojvm -nodisplay -nodesktop -nosplash -r "\
		cd('matlab_lib');\
		parallelComputePerturbation('$patient', $winSize, $stepSize, $radius, '$reference', ${SLURM_ARRAY_TASK_ID});"
fi
