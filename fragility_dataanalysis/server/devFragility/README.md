# Fragility Algorithm Development
By: Adam Li
Last Edited: 2/23/17

This directory is developing the fragility alg. to run in parallel on ICM server at JHU using PBS. 

Currently, the run structure is as follows:
	1. masterscript.sh
		- Initialize patient list, run sleep on bad nodes, read temp data file
		- temp data file stores the number of windows for this patient (e.g. pt1sz4)
        - Calls the patient file
    2. runPatient.sh
        - For a certain patient, initialize the parameters that will be used 
          for pbs job. (e.g. #procs per node, #nodes, walltime, jobname) 
        - Run's run_job.pbs with all these parameters to compute 1 model per 
          window.
	2. run_job.pbs
		- For a certain patient (e.g. pt1sz4), call 
            computeAnalyss.sh many times in parallel with 8 nodes for this core
        - For each processor, passes in a different window to compute on
	3. computeConnectivity.sh
		- This shell script will call matlab to either compute connectivity, or compute fragility.
		- It calls the functions: serverComputeConnectivity.m and serverComputePerturbations.m

Note: must call runSetup.m before all this for the patient list
Note: call serverMergeConnectivity.m or serverMergePerturbations.m afterwards.