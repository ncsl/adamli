# source /etc/profile.modules
# module load matlab/matlab2013a

winSize=500
stepSize=500
frequency_sampling=1000
radius=1.5
numTimes=0

## 00: Load in input parameters
patient="$1"
echo $patient
echo "Running perturbation computation."

# matlab_jvm="matlab -nojvm -nodesktop -nosplash -r"
# [[ ! -z "`which matlab`" ]] || \
# { 
# 	echo "MATLAB not found on the PATH; please add to path."; 
# 	exit 1;
# }

# run perturbation analysis -logfile /home/ali/adamli/fragility_dataanalysis/server/_log/job$1.txt
matlab -nojvm -nodisplay -nosplash -r "currentpatient='$patient'; \
	serverSetupComputePert(currentpatient, $radius, $winSize, $stepSize, $frequency_sampling);\
	exit"