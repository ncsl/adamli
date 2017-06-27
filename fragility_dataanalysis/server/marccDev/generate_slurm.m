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
        patients='pt1sz2 pt3sz1 ';
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
    
    fprintf('Before adding to path\n');
    fprintf(fullfile(rootDir, 'server/marccDev/'));
    fprintf(fullfile(rootDir, '/fragility_library/'));
    
    addpath((fullfile(rootDir, 'server/marccDev/')));
    addpath((fullfile(rootDir, 'server/marccDev/matlab_lib/')));
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
    
    % parameters for sbatch
    partition = PARTITION;
    walltime = WALLTIME;
    numNodes = NUMNODES;
    numCPUs = NUM_PROCS;
    numTasks = 1;
    
    % initialize command
    basecommand = sprintf(strcat('export winSize=%d; export stepSize=%d;\n', ...
                    'sbatch --time=%s --partition=%s',' --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d'), ...
                     winSize, stepSize,...
                    num2str(walltime), partition, numNodes, numTasks, numCPUs);
    
    %- generate merge check
    if MERGE
        filterType = 'adaptivefilter';
        
        % run a computation on checking patients if there is missing data
        [patientsToCompute, patWinsToCompute] = checkPatients(cell_pats, rootDir, winSize, stepSize, filterType);
        
        % nothing to compute, so merge all computations
        if isempty(patientsToCompute) && isempty(patWinsToCompute)
            fprintf('Merging computations.\n');
            
            for iPat=1:numPats
                patient = cell_pats{iPat};
                
                % set jobname 
                job_name = strcat(patient, '_merge');
                
                % create command to run either using scavenger partition,
                % or not
                command = sprintf(strcat('export patient=%s; \n', basecommand, ...
                            ' --job-name=%s run_merge.sbatch --export=%s,%d,%d'), ...
                             patient, ...
                             job_name, patient, winSize, stepSize);
                
                if exist('QOS', 'var')
                        command = sprintf(strcat('export patient=%s; \n', basecommand, ...
                            ' --job-name=%s --qos=%s run_merge.sbatch --export=%s,%d,%d'), ...
                             patient, ...
                             job_name, QOS, patient, winSize, stepSize);
                end
                fprintf(command);
                unix(command);
            end
        else % still have either patients, or windows to compute
            fprintf('There are still patients, or windows to compute.\n');
            % still have patients to compute -> so compute them
            if ~isempty(patientsToCompute)
                for i=1:length(patientsToCompute)
                    patient = patientsToCompute{i};

                    %- call function to compute number of windows for a patient based on
                    %- the data available, window size, and step size
                    numWins = getNumWins(patient, winSize, stepSize);

                    %- create the header of slurm file
                    job_name = strcat(patient, '_batched');
                    Nbatch = numWins; % the number of jobs in job batch
                    if JOBTYPE == 1
                        jobname = strcat('ltvmodel_batch_', num2str(winSize), '_', num2str(stepSize));
                    else
                        jobname = strcat('pertmodel_batch_', num2str(radius));
                    end

                    %- create command to run
                    command = sprintf(strcat('export patient=%s; \n', basecommand, ...
                                ' --array=1-%d --job-name=%s run_jobs.sbatch --export=%s,%d,%d'), ...
                                patient, ...
                                Nbatch, job_name, patient, winSize, stepSize);

                    if exist('QOS', 'var')
                            command = sprintf(strcat('export patient=%s; \n', basecommand, ...
                                ' --array=1-%d --qos=%s --job-name=%s run_job.sbatch --export=%s,%d,%d'), ...
                                patient, ...
                                Nbatch, QOS, job_name, patient, winSize, stepSize);
                    end
                    fprintf(command);
                    unix(command);
                end

                clear patientsToCompute
            end

            % there are windows to compute so compute them
            if ~isempty(patWinsToCompute)
                for i=1:length(patWinsToCompute)
                    patient = patWinsToCompute{i};
                    winsToCompute = patWinsToCompute(patient);

                    %- create the header of slurm file
                    job_name = strcat(patient, '_sepwins');

                    %- create a job array that goes through the windows to
                    %- compute instead of index by index
                    Nbatch = length(winsToCompute);

                    winsToCompute_cell = mat2str(winsToCompute);
                    winsToCompute_cell = winsToCompute_cell(2:end-1);

                    %- create command to run
                    command = sprintf(strcat('export patient=%s; export winSize=%d;', ...
                                             ' export stepSize=%d; export windows=%s;\n', ...
                                        'sbatch --array=1-%d --time=%s --partition=%s', ...
                                        ' --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d', ...
                                        ' --job-name=%s run_job.sbatch --export=%s,%d,%d'), ...
                                    patient, winSize, stepSize, winsToCompute_cell,...
                                    Nbatch, num2str(walltime), partition, numNodes, numTasks, numCPUs, jobname, ...
                                    patient, winSize, stepSize);

                    if exist('QOS', 'var')
                        command = sprintf(strcat('export patient=%s; export winSize=%d; export stepSize=%d; export windows=%s;\n', ...
                                        'sbatch --array=1-%d --time=%s --partition=%s', ...
                                        ' --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d', ...
                                        ' --job-name=%s --qos=%s run_job.sbatch --export=%s,%d,%d'), ...
                                    patient, winSize, stepSize, winsToCompute_cell,...
                                    Nbatch, num2str(walltime), partition, numNodes, numTasks, numCPUs, jobname, QOS, ...
                                    patient, winSize, stepSize);
                    end
                    fprintf(command);
                    unix(command);
                end
            end
        end
    else % not merging and computing on windows
        fprintf('Computing on windows.\n');
        
        %- generate job slurms
        for i=1:numPats
            patient = cell_pats{i};

            %- call function to compute number of windows for a patient based on
            %- the data available, window size, and step size
            numWins = getNumWins(patient, winSize, stepSize);
%             numWins = 10; % for testing
            
            %- create the header of slurm file
            job_name = strcat(patient, '_batched');
            
            Nbatch = numWins; % the number of jobs in job batch
            if JOBTYPE == 1
                jobname = strcat('ltvmodel_batch_', num2str(winSize), '_', num2str(stepSize));
            else
                jobname = strcat('pertmodel_batch_', num2str(radius));
            end

            %- create command to run
            command = sprintf(strcat('export patient=%s; \n', command, ...
                        ' --array=1-%d --job-name=%s run_jobs.sbatch --export=%s,%d,%d'), ...
                        patient, ...
                        Nbatch, job_name, patient, winSize, stepSize);

            if exist('QOS', 'var')
                    command = sprintf('export patient=%s; \n', strcat(command, ...
                        ' --array=1-%d --qos=%s --job-name=%s run_job.sbatch --export=%s,%d,%d'), ...
                        patient, ...
                        Nbatch, QOS, job_name, patient, winSize, stepSize);
            end
            
            fprintf(command);
            unix(command);
        end
    end
end