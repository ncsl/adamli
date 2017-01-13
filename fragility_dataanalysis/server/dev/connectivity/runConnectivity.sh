# Example Call of runConnectivity.sh:
# sh ./connectivity/srunConnectivity.sh $patient $winSize $stepSize $radius

source /etc/profile.modules
module load matlab/matlab2013a

## 00: Load in input parameters
patient="$1"
winSize="$2" 
stepSize="$3"

echo $patient
echo $winSize
echo $stepSize
echo "Running connectivity computation inside."

matlab_jvm="matlab -nojvm -nodesktop -nosplash -r"
[[ ! -z "`which matlab`" ]] || \
{ 
	echo "MATLAB not found on the PATH; please add to path."; 
	exit 1;
}

# run connectivity estimation
matlab -logfile /home/ali/adamli/fragility_dataanalysis/server/_log/$patient.txt -nojvm -nodisplay -nosplash -r "currentPatient='$patient';\
serverSetupAdjComputation(currentPatient, $winSize, $stepSize);\
exit;"