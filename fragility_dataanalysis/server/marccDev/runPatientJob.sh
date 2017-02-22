#!/bin/bash -l

############################# SLURM CONFIGURATION ############################
#SBATCH
#SBATCH --job-name=${SLURM_JOBNAME}
#SBATCH --time=6:0:0
#SBATCH --partition=shared
#SBATCH --nodes=1
# NUMBER OF TASKS (PROCS) PER NODE
#SBATCH --ntasks-per-node=24
#SBATCH --mail-type=end
#SBATCH --mail-user=ali39@jhu.edu

############################# 	 LOAD MODULES   ############################
module list
module load matlab

## Check if there are arguments, if not, then ask for patient
if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    
    # 01: Prompt user for input that runs the analysis
	echo "Begin analysis." # print beginning statement
	printf "Enter patient id: "
	read patient
	printf "Run Connectivity (Enter 1, or 0)? "
	read RUNCONNECTIVITY

	# Pause before running to check
	printf "About to run on patients (press enter to continue): ${patient}"
	read answer

	numWins=$(<./patientMeta/$patient.txt)
else
	## 00: Load in input parameters
	patient="$1"
	RUNCONNECTIVITY="$2" 
	numWins="$3"
fi

## Run slurm batch job for this patient
NprocperNode=8    					# number of processors per node
NNodes=$(($NprocperNode-1))
Nprocs=$((${numWins}/${NprocperNode}+1)) 	# the number of nodes to compute on
walltime=02:00:00					# the walltime for each computation

for ((iproc=1; iproc <= Nprocs; iproc++))
do
	# current Node to compute on
	currentNode=$(((${iproc}-1)*${NprocperNode}))

	# create dynamic job name based on process we are on
	if [[ "${RUNCONNECTIVITY}" -eq 1 ]]; then
		jobname="compute_adjacency_${patient}_${iproc}"
	else
		jobname="compute_perturbation_${patient}_${iproc}"
	fi

	echo "Submit job ${iproc}"
	sbatch -v RUNCONNECTIVITY=${RUNCONNECTIVITY},patient=${patient},currentNode=${currentNode},NprocperNode=${NNodes} -J ${jobname} -t ${walltime} runJob.sh
done

