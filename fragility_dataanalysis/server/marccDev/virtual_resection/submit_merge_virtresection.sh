# patients listed 5 per row
patients=(
	# 'pt1aslp1 pt1aslp2 pt1aw1 pt1aw2
	# pt2aslp1 pt2aslp2 pt2aw1 pt2aw2
	'pt1sz2') 
	# pt1sz3 pt1sz4
	# pt2sz1 pt2sz3 pt2sz4 
	# pt6sz3 pt6sz4 pt6sz5')
	# pt8sz1 pt8sz2 pt8sz3
	# pt10sz1 pt10sz2 pt10sz3
	# pt11sz1 pt11sz2 pt11sz3 pt11sz4
	# pt12sz1 pt12sz2
	# pt13sz1 pt13sz2 pt13sz3 pt13sz5
	# pt14sz1 pt14sz2 pt14sz3
	# pt15sz1 pt15sz2 pt15sz3 pt15sz4
	# pt16sz1 pt16sz2 pt16sz3
	# pt17sz1 pt17sz2 pt17sz3')
	# pt7sz19 pt7sz21 pt7sz22

# numToRemove=(10 10 10 10
# 	4 4 4 4
# 	12 12 12
# 	12 12 12)
numToRemove=$(seq 1 10)
echo $numToRemove

# 01: Prompt user for input that runs the analysis
echo "Begin merging computation." # print beginning statement
printf "Run Connectivity (Enter 1, or 0)? "
read RUNCONNECTIVITY
printf "Enter window size: "
read winSize
printf "Enter step size: "
read stepSize
printf "Enter radius: "
read radius
# printf "Type of reference (e.g. avgref): "
# read reference

# 1. run for 250, 125 ltv model
# 2. run for 1.1, 1.15, 1.25, 1.75, 2.0 radius perturbation

# Pause before running to check
printf "About to run on patients (press enter to continue): $patients" # prompt for patient_id {pt1, pt2, ..., JH105, EZT005}
read answer

## define hardware reqs
NUM_PROCSPERNODE=1 # number of processors per node (1-24)
NUM_NODES=1			# number of nodes to request
MEM_NODE=5 			# GB RAM per node (5-128)
NUM_GPUS=1			# number of GPUS (need 6 procs per gpu)
NUM_TASKS=1 		# number of tasks per CPU

## job reqs
walltime=0:5:0
partition=shared 	# debug, shared, unlimited, parallel, gpu, lrgmem, scavenger
qos=scavenger

## load in the modules for this run -> python, matlab, etc.
module list
module load matlab

# create concatenated strings in unix to ensure proper passing of list of patients
buff=''
for patient in $patients; do
	buff+=$patient
	buff+=' '
done
echo $buff

# Debug statement for reference type
reference=""
if [ -z "$reference" ]
then
      echo "\$var is empty"
      reference=""
else
      echo "\$var is NOT empty and should be 'avgref'"
fi
echo $reference


for numRemove in $numToRemove; do
	echo $numRemove
	## 02: Call patient shell script for each patient
	matlab -logfile /home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/server/marccDev/_log/job$1.txt -nojvm -nodisplay -nosplash -r "\
		generate_slurm_virtresection('$buff', $winSize, $stepSize, $radius,\
		'$partition', '$walltime', $NUM_NODES, $NUM_PROCSPERNODE,\
		 $RUNCONNECTIVITY, '$reference', $numRemove, 1); exit"
done

