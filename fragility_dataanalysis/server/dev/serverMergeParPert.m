function serverMergeParPert(patient, perturbationType)
    if nargin==0
        patient = 'pt1sz4';
    end
    tempDir = fullfile('../tempdata/', patient);
    fullDir = fullfile('../serverdata/icm_computed/', patient);
    
    %- set file name of merged parallelized perturbation matrix
    if ~exist(fullDir, 'dir')
        mkdir(fullDir);
    end
    
    % load in the meta data file
    info = load(fullfile(tempDir, 'infoPertMat'));
    info = info.info;
    TYPE_CONNECTIVITY = info.type_connectivity;
    ezone_labels = info.ezone_labels;
    earlyspread_labels = info.earlyspread_labels;
    latespread_labels = info.latespread_labels;
    resection_labels = info.resection_labels;
    labels = info.all_labels;
    seizureStart = info.seizure_start;
    seizureEnd = info.seizure_end;
    winSize = info.winSize;
    stepSize = info.stepSize;
    timePoints = info.timePoints;
    included_channels = info.included_channels;
    frequency_sampling = info.frequency_sampling;
    timePoints = info.timePoints;
    radius = info.radius;
    
    %- final filename to save merged data as
    filename = strcat(patient, '_', perturbationType, 'perturbation_', lower(TYPE_CONNECTIVITY), '_radius', num2str(radius), '.mat');
    
    % get list of mat files in order and merge them
    pertFiles = dir(fullfile(tempDir, '*.mat'));
    pertFiles = {pertFiles.name};
    
    % get rid of info mat file
    pertFiles(strcmp(pertFiles, 'infoPertMat.mat')) = [];
    
    % loop through each one and load it and construct it
    [T,~] = size(timePoints);
    
    for i=1:length(pertFiles)
        % load in mat file and then save the corresponding index in adjMats
        pertMat = load(fullfile(tempDir, pertFiles{i}));
        pertMat = pertMat.perturbation_struct;
        minPerturb = pertMat.minPerturb_time_chan;
        fragility = pertMat.fragility_rankings;
        del = pertMat.del_table;
        if i==1
            N = size(minPerturb,1);
            adjMats = zeros(T, N, N); 
            
            minPerturb_time_chan = zeros(N, T);
            del_table = cell(N,T);
            fragility_rankings = zeros(N,T);
        end
        minPerturb_time_chan(:,i) = minPerturb;
        del_table(:,i) = del;
        fragility_rankings(:,i) = fragility;
    end
    
    info.del_table = del_table;
    
    % initialize struct to save
    perturbation_struct = struct();
    perturbation_struct.info = info; % meta data info
    perturbation_struct.minNormPertMat = minPerturb_time_chan;
    perturbation_struct.timePoints = timePoints;
    perturbation_struct.fragility_rankings = fragility_rankings;

    
    flag = 0;
    try
        save(fullfile(fullDir, fileName), 'adjmat_struct');
        flag = 1
    catch e
        disp(e);
        save(fullfile(fullDir, fileName), 'adjmat_struct', '-v7.3');
        flag = 1;
    end
    
    %- once it is saved go through and delete all temporary files
    if flag
        delete(fullfile(tempDir, '*.mat'));
    end
end