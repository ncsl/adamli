# This script runs the computation/estimation of adjacency matrices

clear # clear terminal window

## 01: Prompt user for input that runs the analysis
echo "Begin estimation of adjacency matrices." # print beginning statement
printf "Enter patient id: " # prompt for patient_id {pt1, pt2, ..., JH105, EZT005}
read patient_id
printf "Enter seizure id: " # prompt for seizure_id {sz1, sz2, ..., seiz001, seiz003}
read seizure_id
printf "Enter type of perturbation (R, C): "
read perturbationType
while true; do
	if [[ $perturbationType = "R" ]] || [[ $perturbationType = "C" ]]; then
		break
	fi;
	printf "Incorrect perturbation type. Renter one (R, C): "
	read -r perturbationType
done

## 02: Set parameters for matlab to run, and check if matlab is on path
matlab_jvm="matlab -nojvm -nodesktop -nosplash -r"
[[ ! -z "`which matlab`" ]] || \
	{ 
		echo "MATLAB not found on the PATH; please add to path."; 
		exit 1;
	}
# set patient_id, seizure_id, run setup script, ...
# 
# $matlab_jvm "patient_id='$patient_id'; \
# 			seizure_id='$seizure_id'; \
# 			serverMainScript; exit"


# for i in `seq 1 2`;
# do
# 	$matlab_jvm "leastSquaresAdjMat($i, eeg, included_channels, patient, \
#          winSize, stepSize, ezone_labels, earlyspread_labels, latespread_labels); exit"
# done

echo "You entered: $patient_id and $seizure_id and perturbationType"

# $matlab_jvm "computeAdjMats; \load('metadata'); \
#     leastSquaresAdjMat(i, eeg, included_channels, patient, \
#       winSize, stepSize, ezone_labels, earlyspread_labels, latespread_labels); \
#     exit"

# computeAdjMats(patient_id, seizure_id, included_channels, ...
#     timeRange, winSize, stepSize, ezone_labels, earlyspread_labels, latespread_labels)