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
    numTasks = 1;
    
    % initialize filter
    filterType = 'notchfilter';
    
    for iPat=1:numPats
        patient = cell_pats{iPat};
        
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
        
        % initialize command
        basecommand = sprintf(strcat('export radius=%f; export RUNCONNECTIVITY=%d; export patient=%s; export winSize=%d; export stepSize=%d; export reference=%s;  export numWins=%d;\n', ...
                        'srun --exclusive --time=%s --partition=%s --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d --job-name=%s ', ... 
                        ' parallel --delay .2 -j 24 --joblog _gnulogs/runtask.log --resume'), ...
                         radius, JOBTYPE, patient, winSize, stepSize, reference, numWins, ... % exports
                         num2str(walltime), partition, numNodes, numTasks, numCPUs, job_name); 
        if exist('QOS', 'var')
            basecommand = sprintf(strcat('export radius=%f; export RUNCONNECTIVITY=%d; export patient=%s; export winSize=%d; export stepSize=%d; export reference=%s; export numWins=%d;\n', ...
                        'srun --exclusive --time=%s --partition=%s --qos=%s --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d --job-name=%s ', ...
                        ' parallel --delay .2 -j 24 --joblog _gnulogs/runtask.log --resume'), ...
                         radius, JOBTYPE, patient, winSize, stepSize, reference, numWins, ... % exports
                         num2str(walltime), partition, QOS, numNodes, numTasks, numCPUs, job_name); 
        end
        
        % merging computations together
        if MERGE
            fprintf('Checking patients...\n');
            % run a computation on checking patients if there is missing data
            [toCompute, patWinsToCompute] = checkPatient(patient, rootDir, winSize, stepSize, filterType, radius, reference, JOBTYPE);
            
            % if merging, there are 3 cases to check:
            % 1. nothing to compute into temporary directories -> merge
            % 2. some windows are missing -> compute those windows with gnu
            % 3. need to compute still -> compute all windows
            % nothing to compute, so merge all computations
            if toCompute == 0
                fprintf('Merging computations.\n');
                
                % initialize command with debug partition if just doing a
                % merge...
%                 mergepartition='debug';
%                 mergecommand = sprintf(strcat('export radius=%f; export RUNCONNECTIVITY=%d; export patient=%s; export winSize=%d; export stepSize=%d;\n', ...
%                             'sbatch --time=%s --partition=%s --nodes=%d --ntasks-per-node=%d --cpus-per-task=%d'), ...
%                              radius, JOBTYPE, patient, winSize, stepSize,...
%                             num2str(walltime), mergepartition, numNodes, numTasks, numCPUs);

                % create command to run either using scavenger partition,
                % or not
                command = sprintf(strcat(basecommand, ...
                            ' --job-name=%s run_merge.sbatch --export=%s,%d,%d,%d,%d,%s'), ...
                             job_name, patient, winSize, stepSize, JOBTYPE, radius, reference);
                % print command to see and submit to unix shell
%                 fprintf(command);
                fprintf('\n\n');
                unix(command);
            elseif toCompute == -1 % don't compute anything
                fprintf('Not computing anything because data already exists!\n');
            end
        % else not merging -> compute on windows
        else
            fprintf('Computing all windows for %s.\n', patient);

            % create command to run
            command = sprintf(strcat(basecommand, ...
                        ' run_job.sbatch --export=%s,%d,%d,%d,%d,%s,%d'), ...
                            job_name, patient, winSize, stepSize, JOBTYPE, radius,reference, numWins);
                               
            % print command to see and submit to unix shell
%             fprintf('Command is %s', command);
            fprintf('\n\n');
            unix(command);
        end
    end % end of loop through patients            
end