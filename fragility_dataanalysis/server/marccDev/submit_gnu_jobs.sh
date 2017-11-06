#!/bin/bash -l

# patients listed 5 per row
patients=(
	# 'pt1aslp1 pt1aslp2 pt1aw1 pt1aw2
	# pt2aslp1 pt2aslp2 pt2aw1 pt2aw2
	# pt3aslp1 pt3aslp2 pt3aw1
	# pt1sz2 pt1sz3 pt1sz4
	# pt2sz1 pt2sz3 pt2sz4 
	# pt3sz2 pt3sz4
	# pt6sz3 pt6sz4 pt6sz5')
	# 'pt8sz1 pt8sz2 pt8sz3
	# pt10sz1 pt10sz2 pt10sz3
	# pt11sz1 pt11sz2 pt11sz3 pt11sz4')
	# pt12sz1 pt12sz2
	# pt13sz1 pt13sz2 pt13sz3 pt13sz5
	# pt14sz1 pt14sz2 pt14sz3
	# pt15sz1 pt15sz2 pt15sz3 pt15sz4
	# pt16sz1 pt16sz2 pt16sz3
	# pt17sz1 pt17sz2 pt17sz3')
	# pt7sz19 pt7sz21 pt7sz22

	# UMMC001_sz1 UMMC001_sz2 UMMC001_sz3
	# UMMC002_sz1 UMMC002_sz2 UMMC002_sz3
	# UMMC003_sz1 UMMC003_sz2 UMMC003_sz3
	# UMMC004_sz1 UMMC004_sz2 UMMC004_sz3
	# UMMC005_sz1 UMMC005_sz2 UMMC005_sz3
	# UMMC006_sz1 UMMC006_sz2 UMMC006_sz3
	# UMMC007_sz1 UMMC007_sz2 UMMC007_sz3
	# UMMC008_sz1 UMMC008_sz2 UMMC008_sz3
	# UMMC009_sz1 UMMC009_sz2 UMMC009_sz3
	# JH103sz1 JH103sz2 JH103sz3
	# JH103aslp1 JH103aw1
	# 'JH105aslp1 JH105aw1
	# JH105sz1 JH105sz2 JH105sz3 JH105sz4 JH105sz5
	# pt10sz1 pt10sz2 pt10sz3
	# pt17sz1 pt17sz2 pt17sz3')

	'LA05_ICTAL LA05_Inter
	LA07_ICTAL LA07_Inter
	LA13_ICTAL LA13_Inter')
	# 'LA03_ICTAL LA03_Inter
	# LA09_ICTAL LA09_Inter
	# LA10_ICTAL
	# LA11_ICTAL LA11_Inter
	# LA16_ICTAL')

	# 'LA01_ICTAL LA01_Inter
    # LA02_ICTAL LA02_Inter
    # LA03_ICTAL LA03_Inter
    # LA04_ICTAL LA04_Inter
    # LA05_ICTAL LA05_Inter
    # LA06_ICTAL LA06_Inter
    # LA08_ICTAL LA08_Inter
    # LA09_ICTAL LA09_Inter
    # LA10_ICTAL LA10_Inter
    # LA11_ICTAL LA11_Inter
    # LA15_ICTAL LA15_Inter
    # LA16_ICTAL LA16_Inter')

## load in the modules for this run -> python, matlab, etc.
module list
ml matlab
ml parallel

# 01: Prompt user for input that runs the analysis
echo "Begin analysis." # print beginning statement
read -p "Run model (1 for connectivity, 0 for perturbation): " RUNCONNECTIVITY
read -p "Enter window size: " winSize
read -p "Enter step size: " stepSize
read -p "Enter radius: " radius
read -p "Enter type of reference: " reference

# set values and their defauls
RUNCONNECTIVITY=${RUNCONNECTIVITY:-1}
winSize=${winSize:-250}
stepSize=${stepSize:-125}
radius=${radius:-1.5}
reference=${reference:-""}

# show 
echo $RUNCONNECTIVITY
echo $winSize
echo $stepSize
echo $radius
echo $reference

# Pause before running to check
printf "About to run on patients (press enter to continue): $patients" # prompt for patient_id {pt1, pt2, ..., JH105, EZT005}
read answer

## define hardware reqs
NUM_PROCSPERNODE=24 # number of processors per node (1-24)
NUM_NODES=1			# number of nodes to request
MEM_NODE=700 		# GB RAM per node (5-128)
NUM_GPUS=1			# number of GPUS (need 6 procs per gpu)
NUM_CPUPERTASK=1

## job reqs
if [[ "${RUNCONNECTIVITY}" -eq 1 ]]; then
	walltime=10:00:00
else
	walltime=10:00:00					# the walltime for each computation
fi

partition=lrgmem 	# debug, shared, unlimited, parallel, gpu, lrgmem, scavenger
partition=lrgmem
qos=scavenger


# create concatenated strings in unix to ensure proper passing of list of patients
buff=''
for patient in $patients; do
	buff+=$patient
	buff+=' '
done
echo $buff


## 02: Call patient shell script for each patient
matlab -logfile /home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/server/marccDev/_gnulogs/job$1.txt -nojvm -nodisplay -nosplash -r "\
	generate_slurm_gnu('$buff', $winSize, $stepSize, $radius,\
	'$partition', '$walltime', $NUM_NODES,\
	 $NUM_PROCSPERNODE, $MEM_NODE, $NUM_CPUPERTASK, \
	 $RUNCONNECTIVITY, '$reference'); exit"
