#!/bin/bash -l

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
printf "run sleep (Enter 1, or 0)? "
read RUNSLEEP
printf "run merge? (1 or 0) "
read merge
printf "run indiv patients? (enter 0 if n/a): "
read indiv_patients

# patients listed 5 per row
patients=(
	# 'pt1aslp1 pt1aslp2 pt1aw1 pt1aw2
	# pt2aslp1 pt2aslp2 pt2aw1 pt2aw2
	# pt3aslp1 pt3aslp2 pt3aw1
	# pt1sz2 pt1sz3 pt1sz4
	# pt2sz1 pt2sz3 pt2sz4 
	# pt3sz2 pt3sz4
	# pt6sz3 pt6sz4 pt6sz5
	# pt7sz19 pt7sz21 pt7sz22
	# pt8sz1 pt8sz2 pt8sz3
	# pt10sz1 pt10sz2 pt10sz3
	# pt11sz1 pt11sz2 pt11sz3 pt11sz4
	# pt12sz1 pt12sz2
	# pt13sz1 pt13sz2 pt13sz3 pt13sz5
	# pt14sz1 pt14sz2 pt14sz3
	# pt15sz1 pt15sz2 pt15sz3 pt15sz4
	# pt16sz1 pt16sz2 pt16sz3
	# pt17sz1 pt17sz2 pt17sz3')

	'JH101sz1 JH101sz2 JH101sz3 JH101sz4
	JH102sz1 JH102sz2 JH102sz3 JH102sz4 JH102sz5 JH102sz6
	JH103sz1 JH103sz2 JH103sz3
	JH104sz1 JH104sz2 JH104sz3
	JH105sz1 JH105sz2 JH105sz3 JH105sz4 JH105sz5
	JH106sz1 JH106sz2 JH106sz3 JH106sz4 JH106sz5 JH106sz6
	JH107sz1 JH107sz2 JH107sz3 JH107sz4 JH107sz5 JH107sz6 JH107sz7 JH107sz8 JH107sz8 JH107sz9
	JH108sz1 JH108sz2 JH108sz3 JH108sz4 JH108sz5 JH108sz6 JH108sz7
	JH103aslp1 JH103aw1
	JH105aslp1 JH105aw1')

	# 'UMMC001_sz1 UMMC001_sz2 UMMC001_sz3
	# UMMC002_sz1 UMMC002_sz2 UMMC002_sz3
	# UMMC003_sz1 UMMC003_sz2 UMMC003_sz3
	# UMMC004_sz1 UMMC004_sz2 UMMC004_sz3
	# UMMC005_sz1 UMMC005_sz2 UMMC005_sz3
	# UMMC006_sz1 UMMC006_sz2 UMMC006_sz3
	# UMMC007_sz1 UMMC007_sz2 UMMC007_sz3
	# UMMC008_sz1 UMMC008_sz2 UMMC008_sz3
	# UMMC009_sz1 UMMC009_sz2 UMMC009_sz3')

	# 'Pat2sz1p Pat2sz2p Pat2sz3p
	# Pat16sz1p Pat16sz2p Pat16sz3p

	# 'EZT004seiz001 EZT004seiz002
	# EZT006seiz001 EZT006seiz002
	# EZT008seiz001 EZT008seiz002
	# 'EZT009seiz001 EZT009seiz002
	# EZT011seiz001 EZT011seiz002
	# EZT013seiz001 EZT013seiz002
	# EZT020seiz001 EZT020seiz002
	# EZT025seiz001 EZT025seiz002')
	# EZT026seiz001 EZT026seiz002
	# EZT028seiz001 EZT028seiz002')
	# 'EZT007seiz001 EZT007seiz002 EZT007seiz003
	# EZT019seiz001 EZT019seiz002 EZT019seiz003
	# 'EZT005seiz001 EZT005seiz002 EZT005seiz003
	# EZT011seiz001')
	# 'EZT070seiz001 EZT070seiz002')
	# EZT037seiz001 EZT037seiz002')
	# 'EZT070seiz001 EZT070seiz002')

if [[ "$indiv_patients" -eq 0 ]]; then
	echo "just running reg patients"
else
	printf "Enter patients to run: "
	read patient_list

	echo "Running patient list"
	echo $patient_list
	patients=${patient_list}
fi
	
printf "About to run on patients (press enter to continue): $patients" # prompt for patient_id {pt1, pt2, ..., JH105, EZT005}
read answer

if [[ "$RUNSLEEP" -eq 1 ]]; then
	# runs the sleep function on all faulty nodes 
	qsub -l walltime=24:00:00,nodes=node050 run_b_sleep.sh
	qsub -l walltime=24:00:00,nodes=node054 run_b_sleep.sh
	qsub -l walltime=24:00:00,nodes=node165 run_b_sleep.sh
	qsub -l walltime=24:00:00,nodes=node215 run_b_sleep.sh
	qsub -l walltime=24:00:00,nodes=node232 run_b_sleep.sh
fi

# 03: Parameters for each pbs job.
if [[ "${RUNCONNECTIVITY}" -eq 1 ]]; then
	walltime=01:00:00
else
	walltime=05:00:00					# the walltime for each computation
fi

NprocperNode=8    						# number of processors per node
Nnode=1     							# the number of nodes to compute on
Nnodeextra=2

if [[ "${merge}" -eq 1 ]]; then
	echo "Merging..."
	walltime=01:00:00
fi

## 02: Call pbs job, runAnalysis
for patient in $patients; do
	# numWins=$(<./patientMeta/$patient.txt)				# extract the number of windows to compute on
	
	echo $patient
	if [[ "$RUNCONNECTIVITY" -eq 1 ]]; then
		jobname="comp_adj_${patient}"
	else
		jobname="comp_pert_${patient}"
	fi
	# run a pbs batch job. Make sure there are no spaces in between the parameters passed
	qsub -v merge=$merge,RUNCONNECTIVITY=$RUNCONNECTIVITY,patient=$patient,winSize=$winSize,stepSize=$stepSize,radius=$radius,Nnode=$Nnode,NprocperNode=$NprocperNode -N ${jobname} -l nodes=${Nnodeextra}:ppn=${NprocperNode},walltime=${walltime} run_job.pbs
done
