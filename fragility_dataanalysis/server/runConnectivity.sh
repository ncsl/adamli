## 00: Load in input parameters
patient="$1"
winSize="$2" 
stepSize="$3"
radius="$4"

echo $patient
echo $winSize
echo $stepSize
echo $radius
echo "Running connectivity computation inside."

# matlab_jvm="matlab -nojvm -nodesktop -nosplash -r"
# [[ ! -z "`which matlab`" ]] || \
# { 
# 	echo "MATLAB not found on the PATH; please add to path."; 
# 	exit 1;
# }

# run perturbation analysis 
matlab -logfile /home/ali/adamli/fragility_dataanalysis/server/_log/$patient.txt -nojvm -nodisplay -nosplash -r "currentPatient='$patient';\
serverSetupAdjComputation(currentPatient, $radius, $winSize, $stepSize);\
exit;"