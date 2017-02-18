#!/bin/bash -l
# clear # clear terminal window

# 01: Prompt user for input that runs the analysis
echo "Begin analysis." # print beginning statement
printf "Enter window size: " # prompt for seizure_id {sz1, sz2, ..., seiz001, seiz003}
read winSize
printf "Run Connectivity (Enter 1, or 0)? "
read RUNCONNECTIVITY
printf "run sleep (Enter 1, or 0)? "
read RUNSLEEP

# patients listed 5 per row
patient=('pt1sz2')
numElecsToRemove=25

printf "About to run on patients (press enter to continue): $patient" # prompt for patient_id {pt1, pt2, ..., JH105, EZT005}
read answer

if [[ "$RUNSLEEP" -eq 1 ]]; then
	# runs the sleep function on all faulty nodes 
	qsub -l walltime=24:00:00,nodes=node050 run_b_sleep.sh
	qsub -l walltime=24:00:00,nodes=node054 run_b_sleep.sh
	qsub -l walltime=24:00:00,nodes=node165 run_b_sleep.sh
	qsub -l walltime=24:00:00,nodes=node215 run_b_sleep.sh
	qsub -l walltime=24:00:00,nodes=node232 run_b_sleep.sh
fi

## 02: Call pbs job, runAnalysis
for numToRemove in `seq 1 $numElecsToRemove`; do
	echo $patient
	echo $numToRemove
	if [[ "$RUNCONNECTIVITY" -eq 1 ]]; then
		jobname="compute_adjacency_${patient}_${numToRemove}"
	else
		jobname="compute_perturbation_${patient}_${numToRemove}"
	fi
	# run a pbs batch job. Make sure there are no spaces in between the parameters passed
	qsub -v RUNCONNECTIVITY=$RUNCONNECTIVITY,patient=$patient,winSize=$winSize,numToRemove=$numToRemove -N ${jobname} run_job.pbs
done
