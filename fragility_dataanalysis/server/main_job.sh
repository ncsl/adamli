#!/bin/bash -l
# clear # clear terminal window

## 01: Prompt user for input that runs the analysis
echo "Begin estimation of adjacency matrices." # print beginning statement
printf "Enter patient id: " # prompt for patient_id {pt1, pt2, ..., JH105, EZT005}
read patient_id
printf "Enter seizure id: " # prompt for seizure_id {sz1, sz2, ..., seiz001, seiz003}
read seizure_id
printf "Enter type of perturbation (R, C): "
read perturbationType
while true; do
	if [[ $perturbationType = "R" ]] || [[ $perturbationType = "C" ]]; then
		break
	fi;
	printf "Incorrect perturbation type. Renter one (R, C): "
	read -r perturbationType
done

echo "You entered: $patient_id and $seizure_id and $perturbationType"

# runs the sleep function on all faulty nodes 
qsub -l walltime=24:00:00,nodes=node054 run_b_sleep.sh
qsub -l walltime=24:00:00,nodes=node215 run_b_sleep.sh
qsub -l walltime=24:00:00,nodes=node232 run_b_sleep.sh

## 02: Call pbs job, which in turn calls run_all_pbs (put nodes to sleep) and runAnalysis
qsub -v patient_id=$patient_id,seizure_id=$seizure_id,perturbationType=$perturbationType run_job.pbs
