# Fragility Algorithm Development
This directory is developing the fragility alg. to run in parallel on ICM server at JHU using PBS. 

Currently, the run structure is as follows:
	1. masterscript.sh
		- Initialize patient list, run sleep on bad nodes, read temp data file, and call run_job.pbs
		- temp data file stores the number of windows for this patient (e.g. pt1sz4)
	2. run_job.pbs
		- For a certain patient (e.g. pt1sz4), call computeConnectivity.sh many times in parallel with 8 nodes for this core
	3. computeConnectivity.sh
		- This shell script will call matlab to either compute connectivity, or compute fragility.
		- It calls the functions: serverComputeConnectivity.m and serverComputePerturbations.m

Note: must call serverSetupComputation.m before all this for the patient list
Note: call serverMergeConnectivity.m or serverMergePerturbations.m afterwards.
Note: must submit jobs for fragility after connectivity is complete