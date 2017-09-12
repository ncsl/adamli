#!/bin/bash

#---------------------------------------------------------------------
# SLURM job script to run serial MATLAB
# on MARCC using GNU parallel
#---------------------------------------------------------------------
 
ml parallel
ml matlab
mkdir -p logs

# 01: Prompt user for input that runs the analysis
echo "Begin analysis." # print beginning statement
printf "Run Connectivity (Enter 1, or 0)? "
read RUNCONNECTIVITY
printf "Enter window size: "
read winSize
printf "Enter step size: "
read stepSize
printf "Enter radius: "
read radius

# Pause before running to check
printf "About to run on patients (press enter to continue): $patients" # prompt for patient_id {pt1, pt2, ..., JH105, EZT005}
read answer

# --exclusive - distinct CPUs allocated for each job
# -N1 - one node
# -n1 - one task
srun="srun -N1 -n1 --exclusive"
 
# --delay .2 prevents overloading the controlling node
# -j is the number of tasks parallel runs so we set it to 24 (the number of steps we want to run)
# --joblog makes parallel create a log of tasks that it has already run
# --resume makes parallel use the joblog to resume from where it has left off
# the combination of --joblog and --resume allow jobs to be resubmitted if
# necessary and continue from where they left off
parallel="parallel --delay .2 -j 24 --joblog logs/runtask.log --resume"
 
echo $PWD is the present working directory
$parallel $srun "matlab -nodisplay -nojvm -nosplash -nodesktop \
    -r \"csv_string='{1},{2}', try, run('$PWD/my_sum.m'), catch, exit(1), end, exit(0);\"" ::: {100..199} ::: {200..201}
echo "matlab exit code: $?"