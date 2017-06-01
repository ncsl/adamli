#!/bin/bash

#SBATCH
#SBATCH --mail-type=end
#SBATCH --mail-user=ali39@jhu.edu
#SBATCH --output=_err/%A_%a_${SLURM_JOBNAME}.out 
#SBATCH --error=_err/%A_%a_${SLURM_JOBNAME}.err

# Author: Adam Li (ali39@jhu.edu).
# Created on 2017-05-22. Last update on 6/1/17

# cd ./matlab\ lib/

# Load module (comment this to debug in sh mode)
module load matlab

echo ${SLURM_JOBNAME}
echo ${SLURM_SUBMIT_DIR}
echo ${SLURM_ARRAY_TASK_ID}

matlab -logfile _log/${SLURM_JOBNAME}_${SLURM_ARRAY_TASK_ID}.txt -nojvm -nodisplay -nodesktop -nosplash -r "\
	cd('matlab_lib');\
	parallelComputeConnectivity('$patient', $winSize, $stepSize, ${SLURM_ARRAY_TASK_ID});"