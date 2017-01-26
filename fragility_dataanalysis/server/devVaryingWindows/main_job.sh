#!/bin/bash -l
# clear # clear terminal window

# 01: Prompt user for input that runs the analysis
echo "Begin analysis." # print beginning statement
# printf "Center (nih, cc, jhu): " # prompt for patient_id {pt1, pt2, ..., JH105, EZT005}
# read center
printf "Enter window size: " # prompt for seizure_id {sz1, sz2, ..., seiz001, seiz003}
read winSize
# printf "Enter step size: "
# read stepSize
# printf "Enter radius: "
# read radius
printf "Run Connectivity (Enter 1, or 0)? "
read RUNCONNECTIVITY
printf "run sleep (Enter 1, or 0)? "
read RUNSLEEP
# printf "run for different radii: "
# read radius

# patients listed 5 per row
patients=(
	# 'pt1aslp1 pt1aslp2 pt1aw1 pt1aw2
	# pt2aslp1 pt2aslp2 pt2aw1 pt2aw2
	# pt3aslp1 pt3aslp2 pt3aw1
	'pt1sz2 pt1sz3 pt1sz4
	pt2sz1 pt2sz3 pt2sz4 
	pt3sz2 pt3sz4
	pt6sz3 pt6sz4 pt6sz5')
	# pt8sz1 pt8sz2 pt8sz3')
	# 'pt10sz1 pt10sz2 pt10sz3
	# pt11sz1 pt11sz2 pt11sz3 pt11sz4
	# pt14sz1 pt14sz2 pt14sz3 pt15sz1 pt15sz2 pt15sz3 pt15sz4
	# pt16sz1 pt16sz2 pt16sz3 
	# pt17sz1 pt17sz2')
	# 'EZT019seiz001 EZT019seiz002 EZT019seiz003
	# EZT005seiz001 EZT005seiz002 EZT005seiz003
	# EZT007seiz001 EZT007seiz002 EZT007seiz003
	# EZT037seiz001 EZT037seiz002
	# EZT070seiz001 EZT070seiz002')
	# 'JH101sz1')
	 # JH101sz2 JH101sz3 JH101sz4
	# JH102sz1 JH102sz2 JH102sz3 JH102sz4 JH102sz5 JH102sz6
	# JH103sz1 JH103sz2 JH103sz3
	# JH104sz1 JH104sz2 JH104sz3
	# JH105sz1 JH105sz2 JH105sz3 JH105sz4 JH105sz5')
	# 'JH106sz1 JH106sz2 JH106sz3 JH106sz4 JH106sz5 JH106sz6')
	# JH107sz1 JH107sz2 JH107sz3 JH107sz4 JH107sz5 JH107sz6 JH107sz7 JH107sz8 JH107sz8 JH107sz9
	# JH108sz1 JH108sz2 JH108sz3 JH108sz4 JH108sz5 JH108sz6 JH108sz7')
	

printf "About to run on patients (press enter to continue): $patients" # prompt for patient_id {pt1, pt2, ..., JH105, EZT005}
read answer

if [[ "$RUNSLEEP" -eq 1 ]]; then
	# runs the sleep function on all faulty nodes 
	qsub -l walltime=24:00:00,nodes=node054 run_b_sleep.sh
	qsub -l walltime=24:00:00,nodes=node215 run_b_sleep.sh
	qsub -l walltime=24:00:00,nodes=node232 run_b_sleep.sh
fi

## 02: Call pbs job, runAnalysis
for patient in $patients; do
	echo $patient
	if [[ "$RUNCONNECTIVITY" -eq 1 ]]; then
		jobname="compute_adjacency_${patient}"
	else
		jobname="compute_perturbation_${patient}"
	fi
	# run a pbs batch job. Make sure there are no spaces in between the parameters passed
	qsub -v RUNCONNECTIVITY=$RUNCONNECTIVITY,patient=$patient,winSize=$winSize -N ${jobname} run_job.pbs
done