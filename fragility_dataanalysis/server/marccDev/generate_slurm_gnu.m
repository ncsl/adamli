%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% m-file: generate_slurm_gnu.m
%
% Description: It uses a template of *.sbatch (slurm system) file and
%              customizes it to make a *.sh file for every patient of
%              iEEG data that must be processed by the cluster.
%
% Author: Adam Li
% Ver.: 1.0 - Date: 09/24/2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function generate_slurm_gnu(patients, winSize, stepSize, radius, ...
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
        PARTITION='shared';
        WALLTIME='5:00:0';
        NUMNODES=1;
        NUM_PROCS=1;
        JOBTYPE=1; % RUNCONNECTIVITY
        MERGE = 0;
        if strcmp(PARTITION, 'scavenger')
            QOS='scavenger';
        end
        reference = '';
%         numWins=1000;
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

    fprintf('\n\nInside gnu generation of slurm...\n');
    
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
    numTasks = 24;
    memNode = 5*numTasks; % memory GB per CPU
    
    % initialize filter
    filterType = 'notchfilter';
    
    for iPat=1:numPats
        patient = cell_pats{iPat};
        
         % set patientID and seizureID
        [~, patient_id, seizure_id, seeg] = splitPatient(patient);

        [included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
            resection_labels, fs, center, success_or_failure] ...
                = determineClinicalAnnotations(patient_id, seizure_id);
        
        %- call function to compute number of windows for a patient based on
        %- the data available, window size, and step size
        numWins = getNumWins(patient, winSize, stepSize);
        
        % jobname parameters for the batch command
        if JOBTYPE == 1
            job_name = strcat(patient, '_ltv_gnu');
        else
            job_name = strcat(patient, '_pert_gnu');
        end
        if MERGE
            % set jobname 
            job_name = strcat(patient, '_merge');
        end    
        if JOBTYPE == 1
            log_file = strcat('runtask_', patient, '.log');
        else
            log_file = strcat('runtask_', patient, '_pert.log');
        end
        % initialize command
        basecommand = sprintf(strcat('export radius=%f; export RUNCONNECTIVITY=%d; ', ...
                'export patient=%s; export winSize=%d; export stepSize=%d; export reference=%s;  export numWins=%d; export log_file=%s; \n', ...
                    'sbatch --exclusive --time=%s --partition=%s --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d --job-name=%s '), ...
                         radius, JOBTYPE, patient, winSize, stepSize, reference, numWins, log_file, ... % exports
                         num2str(walltime), partition, numNodes, numTasks, numCPUs, job_name); 
        if exist('QOS', 'var')
            basecommand = sprintf(strcat('export radius=%f; export RUNCONNECTIVITY=%d; ', ...
                'export patient=%s; export winSize=%d; export stepSize=%d; export reference=%s; export numWins=%d; export log_file=%s; \n', ...
                    'sbatch --exclusive --time=%s --partition=%s --qos=%s --mem=%d --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d --job-name=%s '), ...
                         radius, JOBTYPE, patient, winSize, stepSize, reference, numWins, log_file, ... % exports
                         num2str(walltime), partition, QOS, memNode, numNodes, numTasks, numCPUs, job_name); 
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
                strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)), ...
                patient, reference);
            
            resultsDir = fullfile(rootDir, 'serverdata/pertmats', strcat(filterType), ...
                strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)),...
                patient, reference);
        end
        
        % merging computations together
        if MERGE
            fprintf('Checking patients...\n');
            % run a computation on checking patients if there is missing data
            [toCompute, patWinsToCompute] = checkPatient(patient, tempDir, resultsDir, winSize, stepSize);
            
            % if merging,
            % nothing to compute, so merge all computations
            if toCompute == 0
                fprintf('Merging computations.\n');
                
                % initialize command with debug partition if just doing a
                % merge...
                mergepartition='shared';
                QOS = 'scavenger';
                walltime='0:20:0';
                mergecommand = sprintf(strcat('export radius=%f; export RUNCONNECTIVITY=%d; export patient=%s; export winSize=%d; export stepSize=%d; export reference=%s;\n', ...
                            'sbatch --time=%s --partition=%s --qos=%s --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d'), ...
                             radius, JOBTYPE, patient, winSize, stepSize, reference,...
                            num2str(walltime), mergepartition, QOS, numNodes, numTasks, numCPUs);

                % create command to run either using scavenger partition,
                % or not
                command = sprintf(strcat(mergecommand, ...
                            ' --job-name=%s run_merge.sbatch --export=%s,%d,%d,%d,%d,%s'), ...
                             job_name, patient, winSize, stepSize, JOBTYPE, radius, reference);
                % print command to see and submit to unix shell
                fprintf(command);
                fprintf('\n\n');
                unix(command);
            elseif toCompute == -1 % don't compute anything
                fprintf('Not computing anything because data already exists!\n');
            elseif toCompute == 1 % still needs some computing, so call job again
                fprintf('These windows still need computing! %s \n', num2str(patWinsToCompute));
                fprintf('Lenght of windows needed to compute! %s \n', num2str(length(patWinsToCompute)));
                
                % create command to run
                command = sprintf(strcat(basecommand, ...
                            ' gnu_run_jobs.sbatch --export=%s,%d,%d,%d,%d,%s,%d'), ...
                                patient, winSize, stepSize, JOBTYPE, radius,reference, numWins);

                % print command to see and submit to unix shell
                fprintf('Command is %s', command);
                fprintf('\n\n');
                unix(command);
            end
        % else not merging -> compute on windows
        else
            fprintf('Computing all windows for %s.\n', patient);

            % create command to run
            command = sprintf(strcat(basecommand, ...
                        ' gnu_run_jobs.sbatch --export=%s,%d,%d,%d,%d,%s,%d'), ...
                            patient, winSize, stepSize, JOBTYPE, radius,reference, numWins);
                               
            % print command to see and submit to unix shell
            fprintf('Command is %s', command);
            fprintf('\n\n');
            unix(command);
        end
    end % end of loop through patients            
end