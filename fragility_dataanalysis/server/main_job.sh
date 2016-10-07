#!/bin/bash -l
# clear # clear terminal window

## 01: Prompt user for input that runs the analysis
echo "Begin estimation of adjacency matrices." # print beginning statement
# printf "Enter patient id: " # prompt for patient_id {pt1, pt2, ..., JH105, EZT005}
# read patient_id
# printf "Enter seizure id: " # prompt for seizure_id {sz1, sz2, ..., seiz001, seiz003}
# read seizure_id
# printf "Enter type of perturbation (R, C): "
# read perturbationType
# while true; do
# 	if [[ $perturbationType = "R" ]] || [[ $perturbationType = "C" ]]; then
# 		break
# 	fi;
# 	printf "Incorrect perturbation type. Renter one (R, C): "
# 	read -r perturbationType
# done

# echo "You entered: $patient_id and $seizure_id and $perturbationType"

patients='pt1sz2 pt1sz3 pt2sz1 pt2sz3 pt7sz19 pt7sz21 pt7sz22 JH105sz1 EZT005seiz001 EZT005seiz002 EZT007seiz001 EZT007seiz002 EZT019seiz001 EZT019seiz002 EZT045seiz001 EZT045seiz002 EZT090seiz002 EZT090seiz003'

# runs the sleep function on all faulty nodes 
qsub -l walltime=24:00:00,nodes=node054 run_b_sleep.sh
qsub -l walltime=24:00:00,nodes=node215 run_b_sleep.sh
qsub -l walltime=24:00:00,nodes=node232 run_b_sleep.sh

## 02: Call pbs job, which in turn calls run_all_pbs (put nodes to sleep) and runAnalysis
# qsub -v patient_id=$patient_id,seizure_id=$seizure_id,perturbationType=$perturbationType run_job.pbs
qsub run_job.pbs
