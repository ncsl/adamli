function icmServerParallelPerturbation(patient, currentWin, winSize, stepSize)
    addpath(genpath('../fragility_library/'));
    addpath(genpath('../eeg_toolbox/'));
    addpath(genpath('../'));
    IS_SERVER = 1;
    if nargin == 0 % testing purposes
        patient='EZT005seiz001';
        patient='JH102sz6';
        patient='pt1sz4';
        % window paramters
        winSize = 500; % 500 milliseconds
        stepSize = 500; 
        frequency_sampling = 1000; % in Hz
        currentWin = 2;
    end

    perturbationTypes = ['R', 'C'];
    w_space = linspace(-radius, radius, 303);
    IS_SERVER = 1;
    setupScripts;

    tempDir = fullfile('../tempdata/', patient);
    if ~exist(tempDir, 'dir')
        mkdir(tempDir);
    end
    
    
     for j=1:length(perturbationTypes)
        perturbationType = perturbationTypes(j);

        toSaveFinalDataDir = fullfile(strcat(adjMat, num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), strcat(perturbationType, '_perturbations', ...
            '_radius', num2str(radius)));
        if ~exist(toSaveFinalDataDir, 'dir')
            mkdir(toSaveFinalDataDir);
        end

        perturb_args = struct();
        perturb_args.perturbationType = perturbationType;
        perturb_args.w_space = w_space;
        perturb_args.radius = radius;
        perturb_args.adjDir = toSaveAdjDir;
        perturb_args.toSaveFinalDataDir = toSaveFinalDataDir;
        perturb_args.TYPE_CONNECTIVITY = TYPE_CONNECTIVITY;

        computePerturbations(patient_id, seizure_id, perturb_args); % the icm server perturbation func
%         computePerturbation(patient_id, seizure_id, perturb_args); % the local parallelized perturbation
    end
    
    if currentWin == 1
        info = struct();
        info.type_connectivity = TYPE_CONNECTIVITY;
        info.ezone_labels = ezone_labels;
        info.earlyspread_labels = earlyspread_labels;
        info.latespread_labels = latespread_labels;
        info.resection_labels = resection_labels;
        info.all_labels = labels;
        info.seizure_start = seizureStart;
        info.seizure_end = seizureEnd;
        info.winSize = winSize;
        info.stepSize = stepSize;
        info.timePoints = timePoints;
        info.included_channels = included_channels;
        info.frequency_sampling = frequency_sampling;
        
        save(fullfile(tempDir, 'tempinfo'), 'info');
    end
    % define args for computing the functional connectivity
    adj_args = struct();
    adj_args.frequency_sampling = frequency_sampling; % frequency that this eeg data was sampled at
    adj_args.winSize = winSize;
    adj_args.stepSize = stepSize;
    adj_args.toSaveAdjDir = tempDir;
    adj_args.included_channels = included_channels;
    adj_args.seizureStart = seizureStart;
    adj_args.seizureEnd = seizureEnd;
    adj_args.labels = labels;
    adj_args.l2regularization = l2regularization;
    adj_args.TYPE_CONNECTIVITY = TYPE_CONNECTIVITY;
    adj_args.num_channels = size(eeg,1);    

    serverComputePerturbation(patient_id, seizure_id, currentWin, tempeeg, clinicalLabels, adj_args);
end