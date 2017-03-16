#!/bin/bash -l

############################# SLURM CONFIGURATION ############################
#SBATCH
#SBATCH --partition=shared
# NUMBER OF TASKS (PROCS) PER NODE
#SBATCH --mail-type=end
#SBATCH --mail-user=ali39@jhu.edu
#SBATCH -o localhost:${SLURM_SUBMIT_DIR}/_log/${SLURM_JOBNAME}.o${SLURM_JOBID}
#SBATCH -e localhost:${SLURM_SUBMIT_DIR}/_log/${SLURM_JOBNAME}.e${SLURM_JOBID}

############################# 	 LOAD MODULES      ############################
module list
module load matlab

############################# 	 RUN CODE		   ############################
RUNCONNECTIVITY=${RUNCONNECTIVITY}
patient=${patient}
currentNode=${currentNode}
NprocperNode=${NNodes}

for ((proc=0; proc <= ((${NprocperNode})); proc++))
do
	currentWin=$(( ${currentNode} + ${proc} + 1))
	echo $currentWin
	pbsdsh -n $proc /home/ali/adamli/fragility_dataanalysis/server/devFragility/computeAnalysis.sh ${proc} ${patient} ${currentWin} ${RUNCONNECTIVITY} &
done
wait