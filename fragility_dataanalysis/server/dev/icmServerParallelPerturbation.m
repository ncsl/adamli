function icmServerParallelPerturbation(patient, currentWin, winSize, stepSize, radius)
    addpath(genpath('../fragility_library/'));
    addpath(genpath('../eeg_toolbox/'));
    addpath(genpath('../../'));
    cd ..
    IS_SERVER = 1;
    if nargin == 0 % testing purposes
        patient='EZT005seiz001';
        patient='JH102sz6';
        patient='pt1sz4';
        % window paramters
        winSize = 500; % 500 milliseconds
        stepSize = 500; 
        radius = 1.5;
        frequency_sampling = 1000; % in Hz
        currentWin = 2;
    end

    perturbationTypes = ['R', 'C'];
    w_space = linspace(-radius, radius, 303);
    IS_SERVER = 1;
    setupScripts;

    %%- temporary directory to save the perturbation computations
    tempDir = fullfile('../tempdata/', patient);
    if ~exist(tempDir, 'dir')
        mkdir(tempDir);
    end
    
    %%- get the adjacency mat
    matFile = fullfile(adjDir, strcat(patient, '_adjmats_', lower(TYPE_CONNECTIVITY), '.mat'));

    % load the adjacency matrix mat file
    data = load(matFile);
    adjmat_struct = data.adjmat_struct;
    adjMat = adjmat_struct.adjMats(currentWin,:,:);
    
    [T,N,~] = size(adjmat_struct.adjMats);
    
    if currentWin == 1
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
        info.timePoints = timePoints;
        info.radius = radius;
        
        %- save here the info meta data temporarily
        save(fullfile(tempDir, 'infoPert'), 'info');
    end
    
    for j=1:length(perturbationTypes)
        perturbationType = perturbationTypes(j);

        perturb_args = struct();
        perturb_args.perturbationType = perturbationType;
        perturb_args.w_space = w_space;
        perturb_args.radius = radius;
        perturb_args.toSaveFinalDataDir = tempDir;
        
        serverComputePerturbations(patient_id, seizure_id, currentWin, adjMat, perturb_args); % the icm server perturbation func
    end    
end