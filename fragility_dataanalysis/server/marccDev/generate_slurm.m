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
function generate_slurm(patients, winSize, stepSize, radius, ...
    PARTITION, WALLTIME, NUMNODES, NUM_PROCS, JOBTYPE, MERGE)
    if nargin==0
        patients='pt1sz2 pt1 pt3sz1';
        winSize=250;
        stepSize=125;
        radius=1.5;
        PARTITION='scavenger';
        WALLTIME='0:0:30';
        NUMNODES=1;
        NUM_PROCS=1;
        JOBTYPE=1;
        MERGE = 0;
        if strcmp(PARTITION, 'scavenger')
            QOS='scavenger';
        end
        
        numWins=1000;
    end
    if nargin < 10
        MERGE = 0;
    end
    if strcmp(PARTITION, 'scavenger')
        QOS='scavenger';
    end
    
    % data directories to save data into - choose one
    eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                 % at ICM server 
    eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';   % at home macbook
    eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';    % at JHU workstation
    eegRootDirMarcc = '/scratch/groups/ssarma2/adamli/fragility_dataanalysis/';
    
    % Determine which directory we're working with automatically
    if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
    elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
    elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
    elseif ~isempty(dir(eegRootDirMarcc)), rootDir = eegRootDirMarcc;
    else   error('Neither Work nor Home EEG directories exist! Exiting'); end
    
    addpath(genpath(fullfile(rootDir, 'server/marccDev/')));
    addpath(genpath(fullfile(rootDir, '/fragility_library/')));
    addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
    addpath(rootDir);

    fprintf('Inside generation of slurm...\n');
    
    % determine number of patients to generate slurm script
    cell_pats = strsplit(patients, ' ');
    if strcmp(cell_pats{end}, '')
        cell_pats(end) = [];
    end
    numPats = size(cell_pats, 2);
    
    %- generate merge check
    if MERGE
        filterType = 'adaptivefilter';
        
        [patientsToCompute, patWinsToCompute] = checkPatients(cell_pats, rootDir, winSize, stepSize, filterType);
        
        %- if patientsToCompute is not empty
        if ~isempty(patientsToCompute)
            for i=1:length(patientsToCompute)
                patient = patientsToCompute{i};
                
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
                    jobname = strcat('ltvmodel_batch_', num2str(winSize), '_', num2str(stepSize));
                else
                    jobname = strcat('pertmodel_batch_', num2str(radius));
                end

                %- create command to run
                command = sprintf(strcat('export patient=%s; export winSize=%d; export stepSize=%d;\n', ...
                                    'sbatch --array=1-%d --time=%s --partition=%s', ...
                                    ' --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d', ...
                                    ' --job-name=%s run_job.sbatch --export=%s,%d,%d'), ...
                                patient, winSize, stepSize,...
                                Nbatch, num2str(walltime), partition, numNodes, numTasks, numCPUs, jobname, ...
                                patient, winSize, stepSize);

                if exist('QOS', 'var')
                    command = sprintf(strcat('export patient=%s; export winSize=%d; export stepSize=%d;\n', ...
                                    'sbatch --array=1-%d --time=%s --partition=%s', ...
                                    ' --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d', ...
                                    ' --job-name=%s --qos=%s run_job.sbatch --export=%s,%d,%d'), ...
                                patient, winSize, stepSize,...
                                Nbatch, num2str(walltime), partition, numNodes, numTasks, numCPUs, jobname, QOS, ...
                                patient, winSize, stepSize);
                end
                fprintf(command);
                unix(command);
            end
            
            clear patientsToCompute
        end
        %- run on windows to compute for each patient
        if ~isempty(patWinsToCompute)
            for i=1:length(patWinsToCompute)
                patient = patWinsToCompute{i};
                winsToCompute = patWinsToCompute(patient);
                
                %- create the header of slurm file
                job_name = strcat(patient, '_sepwins');
                partition = PARTITION;
                walltime = WALLTIME;
                numNodes = NUMNODES;
                numCPUs = NUM_PROCS;
                numTasks = 1;
                jobname = strcat('ltvmodel_merge');
                
                %- create a job array that goes through the windows to
                %- compute instead of index by index
                Nbatch = length(winsToCompute);
                
                winsToCompute_cell = mat2str(winsToCompute);
                winsToCompute_cell = winsToCompute_cell(2:end-1);
                
                %- create command to run
                command = sprintf(strcat('export patient=%s; export winSize=%d; export stepSize=%d; export windows=%s;\n', ...
                                    'sbatch --array=1-%d --time=%s --partition=%s', ...
                                    ' --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d', ...
                                    ' --job-name=%s run_merge.sbatch --export=%s,%d,%d'), ...
                                patient, winSize, stepSize, winsToCompute_cell,...
                                Nbatch, num2str(walltime), partition, numNodes, numTasks, numCPUs, jobname, ...
                                patient, winSize, stepSize);

                if exist('QOS', 'var')
                    command = sprintf(strcat('export patient=%s; export winSize=%d; export stepSize=%d; export windows=%s;\n', ...
                                    'sbatch --array=1-%d --time=%s --partition=%s', ...
                                    ' --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d', ...
                                    ' --job-name=%s --qos=%s run_merge.sbatch --export=%s,%d,%d'), ...
                                patient, winSize, stepSize, winsToCompute_cell,...
                                Nbatch, num2str(walltime), partition, numNodes, numTasks, numCPUs, jobname, QOS, ...
                                patient, winSize, stepSize);
                end
                fprintf(command);
                unix(command);
            end
        end
    else
        %- generate job slurms
        for i=1:numPats
            patient = cell_pats{i};

            % trim white spaces in patient name
            patients = strtrim(patients);

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
                jobname = strcat('ltvmodel_batch_', num2str(winSize), '_', num2str(stepSize));
            else
                jobname = strcat('pertmodel_batch_', num2str(radius));
            end

            %- create command to run
            command = sprintf(strcat('export patient=%s; export winSize=%d; export stepSize=%d;\n', ...
                                'sbatch --array=1-%d --time=%s --partition=%s', ...
                                ' --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d', ...
                                ' --job-name=%s run_job.sbatch --export=%s,%d,%d'), ...
                            patient, winSize, stepSize,...
                            Nbatch, num2str(walltime), partition, numNodes, numTasks, numCPUs, jobname, ...
                            patient, winSize, stepSize);

            if exist('QOS', 'var')
                command = sprintf(strcat('export patient=%s; export winSize=%d; export stepSize=%d;\n', ...
                                'sbatch --array=1-%d --time=%s --partition=%s', ...
                                ' --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d', ...
                                ' --job-name=%s --qos=%s run_job.sbatch --export=%s,%d,%d'), ...
                            patient, winSize, stepSize,...
                            Nbatch, num2str(walltime), partition, numNodes, numTasks, numCPUs, jobname, QOS, ...
                            patient, winSize, stepSize);
            end
            fprintf(command);
            unix(command);
        end
    end
end