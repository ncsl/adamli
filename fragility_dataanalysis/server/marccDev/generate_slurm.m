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
    PARTITION, WALLTIME, NUMNODES, NUM_PROCS, JOBTYPE, reference, MERGE) 
    if ~exist('MERGE','var')
        MERGE = 0;
    end
    if ~exist('reference','var')
        reference = '';
    end
    if nargin==0
        patients='LA16_Inter';
        winSize=250;
        stepSize=125;
        radius=1.5;
        PARTITION='scavenger';
        WALLTIME='0:30:0';
        NUMNODES=1;
        NUM_PROCS=1;
        JOBTYPE=1; % RUNCONNECTIVITY
        MERGE = 1;
        if strcmp(PARTITION, 'scavenger')
            QOS='scavenger';
        end
        reference = 'avgref';
        numWins=1000;
    end
    if strcmp(PARTITION, 'scavenger')
        QOS='scavenger';
    end

    close all;
    % data directories to save data into - choose one
    eegRootDirHD = '/Volumes/ADAM LI/';
    eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                 % at ICM server 
    eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';   % at home macbook
    eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';    % at JHU workstation
    eegRootDirMarcc = '/scratch/groups/ssarma2/adamli/fragility_dataanalysis/';

    % Determine which directory we're working with automatically
    if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
    % elseif ~isempty(dir(eegRootDirHD)), rootDir = eegRootDirHD;
    elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
    elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
    elseif ~isempty(dir(eegRootDirMarcc)), rootDir = eegRootDirMarcc;
    else   error('Neither Work nor Home EEG directories exist! Exiting'); end

    % Determine which data directory we're working with automatically
%     if     ~isempty(dir(eegRootDirServer)), dataDir = eegRootDirServer;
%     if ~isempty(dir(eegRootDirHD)), dataDir = eegRootDirHD;
%     else   error('Neither Work nor Home EEG directories exist! Exiting'); end
    
    fprintf('Before adding to path\n');
    fprintf(fullfile(rootDir, 'server/marccDev/'));
    fprintf(fullfile(rootDir, '/fragility_library/'));
    
    addpath((fullfile(rootDir, 'server/marccDev/')));
    addpath((fullfile(rootDir, 'server/marccDev/matlab_lib/')));
    addpath(genpath(fullfile(rootDir, '/fragility_library/')));
    addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
    addpath(rootDir);

    fprintf('\n\nInside generation of slurm...\n');
    
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
    filterType = 'notchfilter';
    
    for iPat=1:numPats
        patient = cell_pats{iPat};
        
        % set patientID and seizureID
        [~, patient_id, seizure_id, seeg] = splitPatient(patient);

        [included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
            resection_labels, fs, center, success_or_failure] ...
                = determineClinicalAnnotations(patient_id, seizure_id);
        
        % initialize command
        basecommand = sprintf(strcat('export radius=%f; export RUNCONNECTIVITY=%d; export patient=%s; export winSize=%d; export stepSize=%d; export reference=%s;\n', ...
                    'sbatch --time=%s --partition=%s --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d'), ...
                     radius, JOBTYPE, patient, winSize, stepSize, reference,...
                    num2str(walltime), partition, numNodes, numTasks, numCPUs);
        
        if exist('QOS', 'var')
            basecommand = sprintf(strcat('export radius=%f; export RUNCONNECTIVITY=%d; export patient=%s; export winSize=%d; export stepSize=%d; export reference=%s;\n', ...
                    'sbatch --time=%s --partition=%s --qos=%s --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d'), ...
                     radius, JOBTYPE, patient, winSize, stepSize, reference, ...
                    num2str(walltime), partition, QOS, numNodes, numTasks, numCPUs); 
        end
        
        % set directories to check for 1) individual window computation and
        % 2) merged results computation
        if JOBTYPE==1
            tempDir = fullfile(rootDir, 'server/marccDev/matlab_lib/tempData/', ...
                'connectivity', filterType, ...
                strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)), ...
                patient, reference);
            
            resultsDir = fullfile(rootDir, 'serverdata/adjmats', strcat(filterType), ...
                strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)),...
                patient, reference);
        elseif JOBTYPE==0
            tempDir = fullfile(rootDir, 'server/marccDev/matlab_lib/tempData/', ...
                'perturbation', filterType, ...
                strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)), ...
                patient, reference);
            
            resultsDir = fullfile(rootDir, 'serverdata/pertmats', strcat(filterType), ...
                strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)),...
                patient, reference);
        end
        
        % merging computations together
        if MERGE
            fprintf('Checking patients...\n');
            % run a computation on checking patients if there is missing data
            [toCompute, patWinsToCompute] = checkPatient(patient, tempDir, resultsDir, winSize, stepSize);
            
            % if merging, there are 3 cases to check:
            % 1. nothing to compute into temporary directories -> merge
            % 2. some windows are missing -> compute those windows with gnu
            % 3. need to compute still -> compute all windows
            % nothing to compute, so merge all computations
            if toCompute == 0
                fprintf('Merging computations.\n');

                % set jobname 
                job_name = strcat(patient, '_merge');
                
                 % initialize command to use debug partition for just a
                 % simple merging
                mergecommand = sprintf(strcat('export radius=%f; export RUNCONNECTIVITY=%d; export patient=%s; export winSize=%d; export stepSize=%d; export reference=%s;\n', ...
                    'sbatch --time=%s --partition=%s --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d'), ...
                     radius, JOBTYPE, patient, winSize, stepSize, reference,...
                    num2str(walltime), 'debug', numNodes, numTasks, numCPUs);
                
                % create command to run either using scavenger partition,
                % or not
                command = sprintf(strcat(mergecommand, ...
                            ' --job-name=%s run_merge.sbatch --export=%s,%d,%d,%d,%d,%s'), ...
                             job_name, patient, winSize, stepSize, JOBTYPE, radius, reference);
                % print command to see and submit to unix shell
                fprintf(command);
                fprintf('\n\n');
                unix(command);
%             elseif ~isempty(patWinsToCompute) && toCompute == 1
%                 fprintf('Recomputing windows for this patient: %s.\n', patient);
%                 
%                 winsToCompute = patWinsToCompute;
%                 winwalltime='1:00:00'; % short walltime for a single window
%                 
%                 % submit a job using GNU system
%                 if JOBTYPE == 1
%                     job_name = strcat(patient, '_ltv_sepwinsgnu');
%                     log_file = strcat('runtask_ltv_', patient, '.log');
%                 else
%                     job_name = strcat(patient, '_pert_sepwinsgnu');
%                     log_file = strcat('runtask_pert_', patient, '.log');
%                 end
%                 
%                 % initialize command
%                 winCommand = sprintf(strcat('export radius=%f; export RUNCONNECTIVITY=%d; ', ...
%                     'export patient=%s; export winSize=%d; export stepSize=%d; export reference=%s;  export winsToCompute="%s"; export log_file=%s; \n', ...
%                     'sbatch --exclusive --time=%s --partition=%s --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d --job-name=%s '), ...
%                     radius, JOBTYPE, patient, winSize, stepSize, reference, num2str(winsToCompute), log_file, ... % exports
%                     num2str(walltime), partition, numNodes, numTasks, numCPUs, job_name);
%                 if exist('QOS', 'var')
%                     winCommand = sprintf(strcat('export radius=%f; export RUNCONNECTIVITY=%d; ', ...
%                         'export patient=%s; export winSize=%d; export stepSize=%d; export reference=%s; export winsToCompute="%s"; export log_file=%s; \n', ...
%                         'sbatch --exclusive --time=%s --partition=%s --qos=%s --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d --job-name=%s '), ...
%                         radius, JOBTYPE, patient, winSize, stepSize, reference, num2str(winsToCompute), log_file, ... % exports
%                         num2str(walltime), partition, QOS, numNodes, numTasks, numCPUs, job_name);
%                 end
%                 
%                 % create command to run
%                 command = sprintf(strcat(winCommand, ...
%                     ' run_windows.sbatch --export=%s,%d,%d,%d,%d,%s,%s'), ...
%                     patient, winSize, stepSize, JOBTYPE, radius,reference, num2str(winsToCompute));
%                 
%                 % print command to see and submit to unix shell
%                 fprintf(command);
%                 fprintf('\n\n');
%                 unix(command);
            elseif toCompute == 1 %&& length(patWinsToCompute)  % still have either patients, or windows to compute
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
                    ' --array=1-%d --job-name=%s run_job.sbatch --export=%s,%d,%d,%d,%d,%s'), ...
                        Nbatch, job_name, patient, winSize, stepSize, JOBTYPE, radius, reference);
                
                % print command to see and submit to unix shell
                fprintf(command);
                fprintf('\n\n');
                unix(command);
            elseif toCompute == -1 % don't compute anything
                fprintf('Not computing anything because data already exists!\n');
            end
        % else not merging -> compute on windows
        else
            fprintf('Computing all windows for %s.\n', patient);
        
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
                        ' --array=1-%d --job-name=%s run_job.sbatch --export=%s,%d,%d,%d,%d,%s'), ...
                            Nbatch, job_name, patient, winSize, stepSize, JOBTYPE, radius,reference);
            % print command to see and submit to unix shell
            fprintf(command);
            fprintf('\n\n');
            unix(command);
        end
    end % end of loop through patients            
end