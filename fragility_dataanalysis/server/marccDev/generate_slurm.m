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
    if nargin < 10
        MERGE = 0;
    end    
    if nargin==0
        patients='UMMC001_sz1';
        winSize=250;
        stepSize=125;
        radius=1.5;
        PARTITION='scavenger';
        WALLTIME='0:0:30';
        NUMNODES=1;
        NUM_PROCS=1;
        JOBTYPE=1;
        MERGE = 1;
        if strcmp(PARTITION, 'scavenger')
            QOS='scavenger';
        end
        
        numWins=1000;
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
    
    % initialize filter
    filterType = 'adaptivefilter';
    
    for iPat=1:numPats
        patient = cell_pats{iPat};
        
        % initialize command
        basecommand = sprintf(strcat('export RUNCONNECTIVITY=%d; export patient=%s; export winSize=%d; export stepSize=%d;\n', ...
                    'sbatch --time=%s --partition=%s --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d'), ...
                     JOBTYPE, patient, winSize, stepSize,...
                    num2str(walltime), partition, numNodes, numTasks, numCPUs);
        if exist('QOS', 'var')
            basecommand = sprintf(strcat('export RUNCONNECTIVITY=%d; export patient=%s; export winSize=%d; export stepSize=%d;\n', ...
                    'sbatch --time=%s --partition=%s --qos=%s --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d'), ...
                     JOBTYPE, patient, winSize, stepSize,...
                    num2str(walltime), partition, QOS, numNodes, numTasks, numCPUs); 
        end
        
        % merging computations together
        if MERGE
            % run a computation on checking patients if there is missing data
            [toCompute, patWinsToCompute] = checkPatient(patient, rootDir, winSize, stepSize, filterType);
            
            % nothing to compute, so merge all computations
            if isempty(patWinsToCompute) && toCompute == 0
                fprintf('Merging computations.\n');
                
                % set jobname 
                job_name = strcat(patient, '_merge');
                
                % create command to run either using scavenger partition,
                % or not
                command = sprintf(strcat(basecommand, ...
                            ' --job-name=%s run_merge.sbatch --export=%s,%d,%d,%d'), ...
                             job_name, patient, winSize, stepSize, JOBTYPE);
            elseif toCompute == 1 || ~isempty(patWinsToCompute) % still have either patients, or windows to compute
                fprintf('Recomputing for this patient: %s.\n', patient);
                
                %- call function to compute number of windows for a patient based on
                %- the data available, window size, and step size
                numWins = getNumWins(patient, winSize, stepSize);
                %             numWins = 10; % for testing

                % jobname and array parameters for the batch command
                Nbatch = numWins; % the number of jobs in job batch
                if JOBTYPE == 1
                    job_name = strcat(patient, '_ltv_batched');
                else
                    job_name = strcat(patient, '_pert_batched');
                end

                % create command to run
                command = sprintf(strcat(basecommand, ...
                    ' --array=1-%d --job-name=%s run_jobs.sbatch --export=%s,%d,%d'), ...
                        Nbatch, job_name, patient, winSize, stepSize);
%             elseif ~isempty(patWinsToCompute)
%                 fprintf('Recomputing windows for this patient: %s.\n', patient);
%                 
%                 winsToCompute = patWinsToCompute;
% 
%                 %- create a job array that goes through the windows to
%                 %- compute instead of index by index
%                 Nbatch = length(winsToCompute);
%                 if JOBTYPE == 1
%                     job_name = strcat(patient, '_ltv_sepwins');
%                 else
%                     job_name = strcat(patient, '_pert_sepwins');
%                 end
%                 
%                 winsToCompute_cell = mat2str(winsToCompute');
%                 winsToCompute_cell = winsToCompute_cell(2:end-1);
% 
%                 %- create command to run
%                 command = sprintf(strcat('export windows=%s;\n', basecommand, ...
%                                     ' --array=1-%d --job-name=%s run_job.sbatch --export=%s,%d,%d'), ...
%                                 winsToCompute_cell,...
%                                 Nbatch, job_name, patient, winSize, stepSize);
            end
        % else not merging
        else
            fprintf('Computing on windows.\n');
        
            %- call function to compute number of windows for a patient based on
            %- the data available, window size, and step size
            numWins = getNumWins(patient, winSize, stepSize);
%             numWins = 10; % for testing
            
            % jobname and array parameters for the batch command
            Nbatch = numWins; % the number of jobs in job batch
            if JOBTYPE == 1
                job_name = strcat(patient, '_ltv_batched');
            else
                job_name = strcat(patient, '_pert_batched');
            end

            % create command to run
            command = sprintf(strcat(basecommand, ...
                        ' --array=1-%d --job-name=%s run_jobs.sbatch --export=%s,%d,%d'), ...
                            Nbatch, job_name, patient, winSize, stepSize);
        end
        
        % print command to see and submit to unix shell
        fprintf(command);
        fprintf('\n');
        unix(command);
    end % end of loop through patients            
end