#!/bin/bash

#SBATCH
#SBATCH --mail-type=end
#SBATCH --mail-user=ali39@jhu.edu
#SBATCH --output=_err/%A_%a.out 
#SBATCH --error=_err/%A_%a.err

# Author: Adam Li (ali39@jhu.edu).
# Created on 2017-09-28.
# For submitting jobs on studying virtual resection of EZ electrodes

# Load module (comment this to debug in sh mode)
ml matlab

# Debug output to make sure we are in the correct file
echo "Runninng sbatch file..."
echo ${SBATCH_JOB_NAME}
echo ${SLURM_SUBMIT_DIR}
echo ${SLURM_ARRAY_TASK_ID}

if [[ "$RUNCONNECTIVITY" -eq 1 ]]; then
	matlab -logfile _log/${SBATCH_JOB_NAME}_${SLURM_ARRAY_TASK_ID}.txt -nojvm -nodisplay -nodesktop -nosplash -r "\
		parallelComputeConn('$patient', $winSize, $stepSize, $numToRemove, '$reference', ${SLURM_ARRAY_TASK_ID});"
else
	matlab -logfile _log/${SBATCH_JOB_NAME}_${SLURM_ARRAY_TASK_ID}.txt -nojvm -nodisplay -nodesktop -nosplash -r "\
		parallelComputePert('$patient', $winSize, $stepSize, $radius, $numToRemove, '$reference', ${SLURM_ARRAY_TASK_ID});"
fi
