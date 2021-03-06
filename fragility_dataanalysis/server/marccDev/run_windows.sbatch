#!/bin/bash

#SBATCH
#SBATCH --mail-type=end
#SBATCH --mail-user=ali39@jhu.edu
#SBATCH --output=_err/%A_%a_windows.out 
#SBATCH --error=_err/%A_%a_windows.err

# Author: Adam Li (ali39@jhu.edu).
# Created on 2017-09-03. 

#---------------------------------------------------------------------
# SLURM job script to run serial MATLAB
# on MARCC using GNU parallel
#---------------------------------------------------------------------

# Load module (comment this to debug in sh mode)
ml parallel
ml matlab

# Debug output to make sure we are in the correct file
echo "Runninng sbatch windows file..."
echo ${SBATCH_JOB_NAME}
echo ${SLURM_SUBMIT_DIR}
echo ${winSize}
echo ${stepSize}
echo ${window}
echo ${radius}
echo ${winsToCompute}

arrWins=( $winsToCompute )
for i in "${arrWins[@]}"; do echo $i; done

# --delay .2 prevents overloading the controlling node
# -j is the number of tasks parallel runs so we set it to 24 (the number of steps we want to run)
# --joblog makes parallel create a log of tasks that it has already run
# --resume makes parallel use the joblog to resume from where it has left off
# the combination of --joblog and --resume allow jobs to be resubmitted if
# necessary and continue from where they left off
parallel="parallel --delay .2 -j 24 --joblog _gnulogs/${log_file} --resume"

# submit jobs via GNU
if [[ "$RUNCONNECTIVITY" -eq 1 ]]; then
	$parallel "matlab -nojvm -nodisplay -nodesktop -nosplash -r \"
		cd('matlab_lib');\
		parallelComputeConnectivity('$patient', $winSize, $stepSize, '$reference', {1}); exit;\"" ::: ${arrWins[@]}
else
	$parallel "matlab -nojvm -nodisplay -nodesktop -nosplash -r \"
		cd('matlab_lib');\
		parallelComputePerturbation('$patient', $winSize, $stepSize, $radius, '$reference', {1}); exit;\"" ::: ${arrWins[@]}
fi

