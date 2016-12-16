function serverPerturbationScript(patient, radius, winSize, stepSize, frequency_sampling)
    if nargin == 0 % testing purposes
        patient='EZT007seiz001';
        patient ='pt1sz2';

        % window paramters
        radius = 1.5;
        winSize = 500; % 500 milliseconds
        stepSize = 500; 
        frequency_sampling = 1000; % in Hz
    end

    addpath(genpath('../fragility_library/'));
    addpath(genpath('../eeg_toolbox/'));
    addpath('../');
    perturbationTypes = ['R', 'C'];
    w_space = linspace(-radius, radius, 303);
    IS_SERVER = 1;
    
    setupScripts;
    
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

        %% Run Perturbation Algorithm
        patient = strcat(patient_id, seizure_id);

        %% 0: Extract Vars and Initialize Parameters
        perturbationType = perturb_args.perturbationType;
        w_space = perturb_args.w_space;
        radius = perturb_args.radius;
        adjDir = perturb_args.adjDir;
        toSaveFinalDataDir = perturb_args.toSaveFinalDataDir;
        TYPE_CONNECTIVITY = perturb_args.TYPE_CONNECTIVITY;

        sigma = sqrt(radius^2 - w_space.^2); % move to the unit circle 1, for a plethora of different radial frequencies
        b = [0; 1];                          % initialize for perturbation computation later

        % get list of mat files
        matFile = fullfile(adjDir, strcat(patient, '_adjmats_', lower(TYPE_CONNECTIVITY), '.mat'));

        % load the adjacency matrix mat file
        data = load(matFile);
        adjmat_struct = data.adjmat_struct;

        %- extract meta data
        timePoints = adjmat_struct.timePoints;
        ezone_labels = adjmat_struct.ezone_labels;
        earlyspread_labels = adjmat_struct.earlyspread_labels;
        latespread_labels = adjmat_struct.latespread_labels;
        resection_labels = adjmat_struct.resection_labels;
        all_labels = adjmat_struct.all_labels;
        seizure_start = adjmat_struct.seizure_start;
        seizure_end = adjmat_struct.seizure_end;
        winSize = adjmat_struct.winSize;
        stepSize = adjmat_struct.stepSize;
        frequency_sampling = adjmat_struct.frequency_sampling;

        %- set meta data struct
        info.ezone_labels = ezone_labels;
        info.earlyspread_labels = earlyspread_labels;
        info.latespread_labels = latespread_labels;
        info.resection_labels = resection_labels;
        info.all_labels = all_labels;
        info.seizure_start = seizure_start;
        info.seizure_end = seizure_end;
        info.winSize = winSize;
        info.stepSize = stepSize;
        info.frequency_sampling = frequency_sampling;

        % get the number of channels and time points
        num_channels = size(adjmat_struct.adjMats, 3);
        N = num_channels;
        num_times = size(adjmat_struct.adjMats, 1);

        %% 1: Begin Perturbation Analysis
        %- initialize matrices for colsum, rowsum, and minimum perturbation\
        minPerturb_time_chan = zeros(num_channels, num_times);
        del_table = cell(num_channels, num_times);

        % loop through mat files and open them upbcd
        tic; % start counter
        %%- 01: Extract File and Information
        data = load(matFile);
        adjmat_struct = data.adjmat_struct;
        adjMats = adjmat_struct.adjMats;

        
        computePerturbations(patient_id, seizure_id, perturb_args); % the icm server perturbation func
%         computePerturbation(patient_id, seizure_id, perturb_args); % the local parallelized perturbation
    end
end