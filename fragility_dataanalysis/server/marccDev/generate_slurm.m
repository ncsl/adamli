%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% m-file: generate_slurm.m
%
% Description: It uses a template of *.sbatch (slurm system) file and
%              customizes it to make a *.sh file for every patient of
%              iEEG data that must be processed by the cluster.
%
% Author: Adam Li
%
% QUESTIONS FOR PIERRE:
% 1. DO I SET A SEPARATE JOB NAME IN HERE FOR EACH ENTRY IN THE JOB ARRAY?
% 2. EXPLAIN NUMTASKS AGAIN?
% 3. WHAT IS THE OFFSET IN SUBMITTING ARRAY IN SBATCH
% Ver.: 1.0 - Date: 05/22/2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function generate_slurm(patient, winSize, stepSize, radius, ...
    PARTITION, WALLTIME, NUMNODES, NUM_PROCS, JOBTYPE)
    if nargin==0
        patient='pt1sz2';
        winSize=250;
        stepSize=125;
        radius=1.5;
        PARTITION='debug';
        WALLTIME='01:00:00';
        NUMNODES=1;
        NUM_PROCS=1;
        JOBTYPE=1;
        
        numWins=1000;
    end
    addpath('./matlab lib/');

    %- call function to compute number of windows for a patient based on
    %- the data available, window size, and step size
    numWins = getNumWins(patient, winSize, stepSize);
    
    %- create the header of slurm file
    job_name = strcat(patient, '_batched');
    partition = PARTITION;
    walltime = WALLTIME;
    numNodes = NUMNODES;
    numCPUs = NUM_PROCS;
    numTasks = 1;
    Nbatch = numWins; % the number of jobs in job batch
    if JOBTYPE == 1
        jobname = 'ltvmodel_batch';
    else
        jobname = 'pertmodel_batch';
    end
    
    %- create command to run
    command = sprintf(strcat('export patient=%s; export winSize=%d; export stepSize=%d;\n', ...
                        'sbatch --array=1-%d --time=%s --partition=%s', ...
                        ' --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d', ...
                        ' --jobname=%s run_job.sbatch --export=%s,%d,%d'), ...
                    patient, winSize, stepSize,...
                    Nbatch, num2str(walltime), partition, numNodes, numTasks, numCPUs, jobname, ...
                    patient, winSize, stepSize);
    
    unix(command);
end