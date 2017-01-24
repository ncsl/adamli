function serverPerturbationScript(patient, radius, winSize, stepSize, frequency_sampling)
    if nargin == 0 % testing purposes
        patient='EZT007seiz001';
        patient ='pt1sz2';
%         patient = 'JH102sz1';
        % window paramters
        radius = 1.5;
        winSize = 500; % 500 milliseconds
        stepSize = 500; 
        frequency_sampling = 1000; % in Hz
    end

    addpath(genpath('../fragility_library/'));
    addpath(genpath('../eeg_toolbox/'));
    addpath('../');

    % analysis parameters
    perturbationTypes = ['C'];
    w_space = linspace(-radius, radius, 51);

    TYPE_CONNECTIVITY = 'leastsquares';
    IS_SERVER = 1;
    
    setupScripts;
    
    % set directory to find adjacency matrix data
    adjMatDir = '../serverdata/fixed_adj_mats_win500_step500_freq1000/'; % at lab

    patDir = fullfile(adjMatDir, patient);
    fileName = strcat(patient, '_adjmats_leastsquares.mat');
    data = load(fullfile(patDir, fileName));
    data = data.adjmat_struct;
    
    % extract meta data
    ezone_labels = data.ezone_labels;
    earlyspread_labels = data.earlyspread_labels;
    latespread_labels = data.latespread_labels;
    resection_labels = data.resection_labels;
    all_labels = data.all_labels;
    seizure_start = data.seizure_start;
    seizure_end = data.seizure_end;
    winSize = data.winSize;
    stepSize = data.stepSize;
    frequency_sampling = data.frequency_sampling;
    included_channels = data.included_channels;
    timePoints = data.timePoints;
    
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
    info.included_channels = included_channels;

    adjMats = data.adjMats;
    [T, N, ~] = size(adjMats);
    
    seizureMarkStart = seizure_start / winSize;
    adjmats = adjMats(1:seizureMarkStart+2,:,:);
    [T, N, ~] = size(adjMats);
    
    for j=1:length(perturbationTypes)
        % initialize matrices to store
        minNormPerturbMat = zeros(N,T);
        fragilityMat = zeros(N,T);
        del_table = cell(N, T);
        
        perturbationType = perturbationTypes(j);
        % save the perturbation results
        filename = strcat(patient, '_', perturbationType, 'perturbation_', ...
                lower(TYPE_CONNECTIVITY), '_radius', num2str(radius), '.mat');
       
        toSavePertDir = fullfile(adjMatDir, strcat(perturbationType, '_perturbations', ...
            '_radius', num2str(radius)), '_diluxan');
        if ~exist(toSavePertDir, 'dir')
            mkdir(toSavePertDir);
        end

        perturb_args = struct();
        perturb_args.perturbationType = perturbationType;
        perturb_args.w_space = w_space;
        perturb_args.radius = radius;
        
        for iTime=1:T
            adjMat = squeeze(adjMats(iTime,:,:));
            
            [minNormPert, del_vecs, ERRORS] = minNormPerturbation(patient, adjMat, perturb_args);
        
            % store results
            minNormPerturbMat(:, iTime) = minNormPert;
            del_table(:, iTime) = del_vecs;
            
            disp(['Finished time: ', num2str(iTime)]);
        end
        
        % Compute fragility rankings per column by normalization
        for i=1:N      % loop through each channel
            for t=1:T % loop through each time point
                fragilityMat(i,t) = (max(minNormPerturbMat(:,t)) - minNormPerturbMat(i,t)) ...
                                            / max(minNormPerturbMat(:,t));
            end
        end
        
%         info.del_table = del_table;
        
        % initialize struct to save
        perturbation_struct = struct();
        perturbation_struct.info = info; % meta data info
        perturbation_struct.minNormPertMat = minNormPerturbMat;
        perturbation_struct.timePoints = timePoints;
        perturbation_struct.fragilityMat = fragilityMat;
        perturbation_struct.del_table = del_table;
        
        % save the perturbation struct result
        save(fullfile(toSavePertDir, filename), 'perturbation_struct');
        disp(['Saved file: ', filename]);
    end
end