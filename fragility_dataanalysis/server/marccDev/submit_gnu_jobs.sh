#!/bin/bash

#SBATCH
#SBATCH --mail-type=end
#SBATCH --mail-user=ali39@jhu.edu

#---------------------------------------------------------------------
# SLURM job script to run serial MATLAB
# on MARCC using GNU parallel
#---------------------------------------------------------------------
 
ml parallel
ml matlab
mkdir -p logs

# 01: Prompt user for input that runs the analysis
echo "Runninng sbatch file..."
echo ${SBATCH_JOB_NAME}
echo ${SLURM_SUBMIT_DIR}
echo $PWD is the present working directory

# 02: Create srun and reservation of CPUS
# --exclusive - distinct CPUs allocated for each job
# -N1 - one node (# of nodes)
# -n1 - one task (# of tasks)
srun="srun -N1 -n1 --exclusive"
 
# --delay .2 prevents overloading the controlling node
# -j is the number of tasks parallel runs so we set it to 24 (the number of steps we want to run)
# --joblog makes parallel create a log of tasks that it has already run
# --resume makes parallel use the joblog to resume from where it has left off
# the combination of --joblog and --resume allow jobs to be resubmitted if
# necessary and continue from where they left off
parallel="parallel --delay .2 -j 24 --joblog _gnulogs/runtask.log --resume"


# submit jobs via GNU
if [[ "$RUNCONNECTIVITY" -eq 1 ]]; then
	$parallel $srun matlab -nojvm -nodisplay -nodesktop -nosplash -r "\
		cd('matlab_lib');\
		parallelComputeConnectivity('$patient', $winSize, $stepSize, ${iSeq});"
else
	$parallel $srun matlab -nojvm -nodisplay -nodesktop -nosplash -r "\
		cd('matlab_lib');\
		parallelComputePerturbation('$patient', $winSize, $stepSize, $radius, ${iSeq});"
fi


# strings in Bash
patient=1004
winSize=10
stepSize=2
radius=4
 
# submit jobs via GNU
if [[ "$RUNCONNECTIVITY" -eq 1 ]]; then
      $parallel $srun echo matlab -nojvm -nodisplay -nodesktop -nosplash -r "\
            cd('matlab_lib');\
            parallelComputeConnectivity({1}, {2}, {3}, {4});" ::: $(echo $patient) ::: $(echo $winSize) ::: $(echo $stepSize) :::  $(seq 1 100)
else
      $parallel $srun echo matlab -nojvm -nodisplay -nodesktop -nosplash -r "\
            cd('matlab_lib');\
            parallelComputePerturbation({1}, {2}, {3}, {4}, {5});" ::: $(echo $patient) ::: $(echo $winSize) ::: $(echo $stepSize) :::  $(echo $radius) ::: $(seq 1 100)
fi
 
