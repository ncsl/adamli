function serverPerturbationScript(patient, radius, winSize, stepSize)
    if nargin == 0 % testing purposes
        patient='EZT011seiz001';
        patient ='pt13sz1';
%         patient='UMMC006_sz2';
%         patient = 'Pat16sz1p';
%         patient = 'JH102sz1';
        % window paramters
        radius = 1.5;
        winSize = 250; % 500 milliseconds
        stepSize = 125; 
%         frequency_sampling = 1000; % in Hz
    end

    % set working directory
    % data directories to save data into - choose one
    eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';     % work
    % eegRootDirHome = '/Users/adam2392/Documents/MATLAB/Johns Hopkins/NINDS_Rotation';  % home
    eegRootDirHome = '/Volumes/NIL_PASS/';
    eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';
    % Determine which directory we're working with automatically
    if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
    elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
    elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
    else   error('Neither Work nor Home EEG directories exist! Exiting'); end

    addpath(genpath(fullfile(rootDir, '/fragility_library/')));
    addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
    addpath(rootDir);

    %- 0 == no filtering
    %- 1 == notch filtering
    %- 2 == adaptive filtering
    FILTER_RAW = 2;
    TYPE_CONNECTIVITY = 'leastsquares';
    
    % set patientID and seizureID
    patient_id = [];
    patient_id = patient(1:strfind(patient, 'seiz')-1);
    seizure_id = strcat('_', patient(strfind(patient, 'seiz'):end));
    seeg = 1;
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'sz')-1);
        seizure_id = patient(strfind(patient, 'sz'):end);
        seeg = 0;
    end
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'aslp')-1);
        seizure_id = patient(strfind(patient, 'aslp'):end);
        seeg = 0;
    end
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'aw')-1);
        seizure_id = patient(strfind(patient, 'aw'):end);
        seeg = 0;
    end
    buffpatid = patient_id;
    if strcmp(patient_id(end), '_')
        patient_id = patient_id(1:end-1);
    end
    %- Edit this file if new patients are added.
    [included_channels, ezone_labels, earlyspread_labels,...
    latespread_labels, resection_labels, fs, ...
    center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);

    perturbationTypes = ['C', 'R'];
    w_space = linspace(-radius, radius, 51);
    sigma = sqrt(radius^2 - w_space.^2); % move to the unit circle 1, for a plethora of different radial frequencies
    b = [0; 1];                          % initialize for perturbation computation later
    
    % add to sigma and w to create a whole circle search
    w_space = [w_space, w_space];
    sigma = [-sigma, sigma];
        
    % set directory to find adjacency matrix data
    if FILTER_RAW == 1
        adjMatDir = fullfile(rootDir, 'serverdata/adjmats/notchfilter/', strcat('win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
        
        toSaveDir = fullfile(rootDir, strcat('/serverdata/perturbationmats/notchfilter', '/win', num2str(winSize), ...
                '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)), patient); % at lab

    elseif FILTER_RAW == 2
        adjMatDir = fullfile(rootDir, 'serverdata/adjmats/adaptivefilter/', strcat('win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
        
        toSaveDir = fullfile(rootDir, strcat('/serverdata/perturbationmats/adaptivefilter', '/win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)), patient); % at lab
    else 
        adjMatDir = fullfile(rootDir, 'serverdata/adjmats/nofilter/', strcat('win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
        
        toSaveDir = fullfile(rootDir, strcat('/serverdata/perturbationmats/nofilter', 'win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)), patient); % at lab
    end
    if ~exist(toSaveDir, 'dir')
        mkdir(toSaveDir);
    end
    
    fileName = strcat(patient, '_adjmats_leastsquares.mat');
    adjmat_struct = load(fullfile(adjMatDir, fileName));
    adjmat_struct = adjmat_struct.adjmat_struct;
    
    % extract meta data
    timePoints = adjmat_struct.timePoints;
    
    %- set meta data struct
    info.ezone_labels = adjmat_struct.ezone_labels;
    info.earlyspread_labels = adjmat_struct.earlyspread_labels;
    info.latespread_labels = adjmat_struct.latespread_labels;
    info.resection_labels = adjmat_struct.resection_labels;
    info.all_labels = adjmat_struct.all_labels;
    info.seizure_estart_ms = adjmat_struct.seizure_estart_ms;       % store in ms
    info.seizure_eend_ms = adjmat_struct.seizure_eend_ms;
    info.seizure_cstart_ms = adjmat_struct.seizure_cstart_ms;
    info.seizure_coffset_ms = adjmat_struct.seizure_cend_ms;
    info.seizure_estart_mark = adjmat_struct.seizure_estart_mark;
    info.seizure_eend_mark = adjmat_struct.seizure_eend_mark;
    info.winSize = adjmat_struct.winSize;
    info.stepSize = adjmat_struct.stepSize;
    info.frequency_sampling = adjmat_struct.fs;
    info.included_channels = adjmat_struct.included_channels;
    info.FILTER = adjmat_struct.FILTER;
    info.timePoints = adjmat_struct.timePoints;
    info.TYPE_CONNECTIVITY = adjmat_struct.type_connectivity;
    
    adjMats = adjmat_struct.adjMats;
    [T, N, ~] = size(adjMats);

     % save the perturbation results
    filename = strcat(patient, '_', 'pertmats_', ...
            lower(TYPE_CONNECTIVITY), '_radius', num2str(radius), '.mat');
    
    perturbation_struct = struct();
    perturbation_struct.info = info; % meta data info
    
    for j=1:length(perturbationTypes)
        % initialize matrices to store
        minNormPerturbMat = zeros(N,T);
        fragilityMat = zeros(N,T);
        del_table = cell(N, T);
        
        perturbationType = perturbationTypes(j);
        
        perturb_args = struct();
        perturb_args.perturbationType = perturbationType;
        perturb_args.w_space = w_space;
        perturb_args.radius = radius;
        
        parfor iTime=1:T
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
        % initialize struct to save

        perturbation_struct.(perturbationType).minNormPertMat = minNormPerturbMat;
        perturbation_struct.(perturbationType).timePoints = timePoints;
        perturbation_struct.(perturbationType).fragilityMat = fragilityMat;
        perturbation_struct.(perturbationType).del_table = del_table;
    end
    
    % save the perturbation struct result
    try
        save(fullfile(toSaveDir, filename), 'perturbation_struct');
    catch e
         save(fullfile(toSaveDir, filename), 'perturbation_struct', '-v7.3');
    end
    disp(['Saved file: ', filename]);
end