function serverMergeParAdj(patient)
    tempDir = fullfile('../tempdata/', patient);
    
    % load in the meta data file
    info = load(fullfile(tempDir, 'infoAdjMat'));
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
    
    % get list of mat files in order and merge them
    matFiles = dir(fullfile(tempDir, '*.mat'));
    matFiles = {matFiles.name};
    
    % get rid of info mat file
    
    % loop through each one and load it and construct it
    [T,N] = size(timePoints);
    
    adjMats = zeros(T, N, N);
    for i=1:length(matFiles)
        % load in mat file and then save the corresponding index in adjMats
        
    end
    
    adjmat_struct = struct();
    adjmat_struct.type_connectivity = TYPE_CONNECTIVITY;
    adjmat_struct.ezone_labels = ezone_labels;
    adjmat_struct.earlyspread_labels = earlyspread_labels;
    adjmat_struct.latespread_labels = latespread_labels;
    adjmat_struct.resection_labels = resection_labels;
    adjmat_struct.all_labels = labels;
    adjmat_struct.seizure_start = seizureStart;
    adjmat_struct.seizure_end = seizureEnd;
    adjmat_struct.winSize = winSize;
    adjmat_struct.stepSize = stepSize;
    adjmat_struct.timePoints = timePoints;
    adjmat_struct.adjMats = adjMats;
    adjmat_struct.included_channels = included_channels;
    adjmat_struct.frequency_sampling = frequency_sampling;
    
    flag = 0;
    try
        save(fullfile(toSaveAdjDir, fileName), 'adjmat_struct');
        flag = 1
    catch e
        disp(e);
        save(fullfile(toSaveAdjDir, fileName), 'adjmat_struct', '-v7.3');
        flag = 1;
    end
    
    %- once it is saved go through and delete all temporary files
    if flag
        delete(fullfile(tempDir, '*.mat'));
    end
end