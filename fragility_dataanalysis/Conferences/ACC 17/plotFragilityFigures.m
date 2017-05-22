% function runPlotsAndDOA(frequency_sampling, winSize, stepSize, radius)
% settings to run
patients = {...
    'pt1sz2', 'pt1sz3',...
    'pt2sz1' 'pt2sz3', ...
};

close all;

perturbationTypes = ['C', 'R'];
perturbationType = perturbationTypes(1);
PLOTALL = 1;

% data parameters to find correct directory
radius = 1.5;             % spectral radius
winSize = 250;            % 500 milliseconds
stepSize = 125; 
FILTER_RAW = 2;
fs = 1000; % in Hz
% TEST_DESCRIP = 'noleftandrpp';
% TEST_DESCRIP = 'after_first_removal';
TEST_DESCRIP = [];
TYPE_CONNECTIVITY = 'leastsquares';

addpath(('/Users/adam2392/Documents/adamli/fragility_dataanalysis/'));

% set working directory
% data directories to save data into - choose one
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';     % work
eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';  % home
% eegRootDirHome = '/Volumes/NIL_PASS/';
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';
% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

figDir = fullfile(rootDir, '/figures/adaptivefiltered/', ...
    strcat('win', num2str(winSize), '_step', num2str(stepSize), '_radius', num2str(radius)));

%%- Begin Loop Through Different Patients Here
for p=1:length(patients)
    patient = patients{p};

    % set patientID and seizureID
    patient_id = patient(1:strfind(patient, 'seiz')-1);
    seizure_id = strcat('_', patient(strfind(patient, 'seiz'):end));
    seeg = 1;
    INTERICTAL = 0;
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'sz')-1);
        seizure_id = patient(strfind(patient, 'sz'):end);
        seeg = 0;
    end
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'aslp')-1);
        seizure_id = patient(strfind(patient, 'aslp'):end);
        seeg = 0;
        INTERICTAL = 1;
    end
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'aw')-1);
        seizure_id = patient(strfind(patient, 'aw'):end);
        seeg = 0;
        INTERICTAL = 1;
    end

    buffpatid = patient_id;
    if strcmp(patient_id(end), '_')
        patient_id = patient_id(1:end-1);
    end
    
    [included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
        resection_labels, fs, center, success_or_failure] ...
            = determineClinicalAnnotations(patient_id, seizure_id);
        
    serverDir = fullfile(rootDir, '/serverdata/');
    %%- Extract an example
    if FILTER_RAW == 1
        adjMatDir = fullfile(rootDir, 'serverdata/adjmats/notchfilter/', strcat('win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
        
        finalDataDir = fullfile(rootDir, strcat('/serverdata/perturbationmats/notchfilter', '/win', num2str(winSize), ...
                '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)), patient); % at lab

    elseif FILTER_RAW == 2
        adjMatDir = fullfile(rootDir, 'serverdata/adjmats/adaptivefilter/', strcat('win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
        
        finalDataDir = fullfile(rootDir, strcat('/serverdata/perturbationmats/adaptivefilter', '/win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)), patient); % at lab
    else 
        adjMatDir = fullfile(rootDir, 'serverdata/adjmats/nofilter/', strcat('win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
        
        finalDataDir = fullfile(rootDir, strcat('/serverdata/perturbationmats/nofilter', 'win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)), patient); % at lab
    end
    
    
    try
        final_data = load(fullfile(finalDataDir, strcat(patient, ...
            '_pertmats_', lower(TYPE_CONNECTIVITY), '_radius', num2str(radius), '.mat')));
        final_data = final_data.perturbation_struct;
    catch e
        disp(e)
        final_data = load(fullfile(finalDataDir, strcat(patient, ...
            '_', perturbationType, 'perturbation_', lower(TYPE_CONNECTIVITY), ...
            '_radius', num2str(radius), '.mat')));
        final_data = final_data.perturbation_struct;
    end
    % set data to local variables
    info = final_data.info;
    
    %- extract clinical data
%     ezone_labels = info.ezone_labels;
%     earlyspread_labels = info.earlyspread_labels;
%     latespread_labels = info.latespread_labels;
%     resection_labels = info.resection_labels;
    included_labels = info.all_labels;
    seizure_estart_ms = info.seizure_estart_ms;
    seizure_estart_mark = info.seizure_estart_mark;
    seizure_eend_ms = info.seizure_eend_ms;
    seizure_eend_mark = info.seizure_eend_mark;
    num_channels = length(info.all_labels);
    
    %- set global variable for plotting
    seizureStart = seizure_estart_ms;
    seizureEnd = seizure_eend_ms;
    seizureMarkStart = seizure_estart_mark;
    
    %%- Get Indices for All Clinical Annotations
    ezone_indices = findElectrodeIndices(ezone_labels, included_labels);
    earlyspread_indices = findElectrodeIndices(earlyspread_labels, included_labels);
    latespread_indices = findElectrodeIndices(latespread_labels, included_labels);

    allYTicks = 1:num_channels; 
    y_indices = setdiff(allYTicks, [ezone_indices; earlyspread_indices]);
    if sum(latespread_indices > 0)
        latespread_indices(latespread_indices ==0) = [];
        y_indices = setdiff(allYTicks, [ezone_indices; earlyspread_indices; latespread_indices]);
    end
    y_ezoneindices = sort(ezone_indices);
    y_earlyspreadindices = sort(earlyspread_indices);
    y_latespreadindices = sort(latespread_indices);
    
    % find resection indices
%     y_resectionindices = findResectionIndices(included_labels, resection_labels);
    y_resectionindices = [];
    
    % create struct for clinical indices
    clinicalIndices.all_indices = y_indices;
    clinicalIndices.ezone_indices = y_ezoneindices;
    clinicalIndices.earlyspread_indices = y_earlyspreadindices;
    clinicalIndices.latespread_indices = y_latespreadindices;
    clinicalIndices.resection_indices = y_resectionindices;
    clinicalIndices.included_labels = included_labels;
    
    %% PLOT PERTURBATION RESULTS
    for j=1:length(perturbationTypes)
        perturbationType = perturbationTypes(j);
        
        %- initialize directories to save things and where to get
        %- perturbation structs
        toSaveFigDir = fullfile(figDir, perturbationType, strcat(patient, '_win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)))
        if ~exist(toSaveFigDir, 'dir')
            mkdir(toSaveFigDir);
        end
           
        pertDataStruct = final_data.(perturbationType);
        
        tempWinSize = winSize;
        tempStepSize = stepSize;
        if fs ~=1000
            tempWinSize = winSize*fs/1000;
            tempStepSize = stepSize*fs/1000;
        end
        
        % set data to local variables
        minPerturb_time_chan = pertDataStruct.minNormPertMat;
        fragility_rankings = pertDataStruct.fragilityMat;
        timePoints = pertDataStruct.timePoints;
        del_table = pertDataStruct.del_table;
        
        if isnan(seizureStart)
            seizureStart = timePoints(end,1);
            seizureEnd = timePoints(end,1);
            seizureMarkStart = size(timePoints, 1);
        end
        
        if seeg
            seizureMarkStart = (seizureStart-1) / tempStepSize;
        end
        
        % for ACC
%         minPerturb_time_chan = minPerturb_time_chan(:, seizureMarkStart-121:seizureMarkStart);
%         fragility_rankings = fragility_rankings(:, seizureMarkStart-121:seizureMarkStart);
%         timePoints = timePoints(seizureMarkStart-121:seizureMarkStart,:);

        %% 1: Extract Processed Data and Begin Plotting and Save in finalDataDir
        %%- initialize plotting args
        FONTSIZE = 20;
        PLOTARGS = struct();
        PLOTARGS.SAVEFIG = 1;
        PLOTARGS.YAXFontSize = 9;
        PLOTARGS.FONTSIZE = FONTSIZE;
        PLOTARGS.xlabelStr = 'Time With Respect To Seizure (sec)';
        if isnan(info.seizure_estart_ms)
            PLOTARGS.xlabelStr = 'Time (sec)';
        end
        PLOTARGS.colorbarStr = 'Minimum 2-Induced Norm Perturbation';
        PLOTARGS.ylabelStr = 'Electrode Channels';
        PLOTARGS.xTickStep = 10*winSize/stepSize;
        PLOTARGS.titleStr = {['Minimum Norm Perturbation (', patient, ')'], ...
            [perturbationType, ' perturbation: ', ' Time Locked to Seizure']};
        PLOTARGS.seizureMarkStart = seizureMarkStart;
        PLOTARGS.frequency_sampling = fs;
        PLOTARGS.stepSize = stepSize;


        if seizureStart == size(minPerturb_time_chan,1)*winSize % interictal data
            timeStart = 1;
            timeEnd = timePoints(size(minPerturb_time_chan,2),1) / fs;
            if PLOTALL
                PLOTARGS.toSaveFigFile = fullfile(toSaveFigDir, strcat(patient, '_minPerturbation_alldata'));
            else
                PLOTARGS.toSaveFigFile = fullfile(toSaveFigDir, strcat(patient, '_minPerturbation'));
            end
        else % some seizure data
            timeIndex = find(seizureStart<timePoints(:,2),1) - 1;
            if PLOTALL % plot entire data series
                seizureIndex = timeIndex;
                seizureEndIndex = find(seizureEnd < timePoints(:,2),1) + 1;
                
                % plotting from beginning of recording -> some time
                % specified up there
                timeStart = -seizureStart / fs;
                timeEnd = (timePoints(size(minPerturb_time_chan, 2), 2) - seizureStart)/fs;
                timeEnd = (timePoints(size(minPerturb_time_chan, 2), 2) - seizureStart + 1)/fs;
                
                % for ACC
%                 timeStart = ceil((timePoints(1,2) - seizureStart) / frequency_sampling);
%                 timeEnd = (timePoints(end,2) - seizureStart) / frequency_sampling;
                
%                 PLOTARGS.seizureIndex = seizureIndex;
%                 PLOTARGS.seizureEnd = seizureEndIndex;
%                 PLOTARGS.seizureEnd = seizureIndex;
                PLOTARGS.toSaveFigFile = fullfile(toSaveFigDir, strcat(patient, '_minPerturbation'));
            else % only plot window of data
                postWindow = 10;
                preWindow = 60;
                % find index of seizureStart
                timeStart = (timeIndex - preWindow - timeIndex)*tempWinSize/fs; 
                timeEnd = (timeIndex - timeIndex + postWindow)*tempWinSize/fs;
                minPerturb_time_chan = minPerturb_time_chan(:, timeIndex-60:timeIndex + postWindow);
                fragility_rankings = fragility_rankings(:, timeIndex-60:timeIndex + postWindow);
                PLOTARGS.seizureIndex = abs(timeStart);
                PLOTARGS.seizureEnd = abs(timeStart);
                PLOTARGS.toSaveFigFile = fullfile(toSaveFigDir, strcat(patient, '_minPerturbation'));
            end
        end
        
        %% 2. Plot Fragility Ranking
        if PLOTALL
            PLOTARGS.toSaveFigFile = fullfile(toSaveFigDir, strcat(patient, '_fragilityMetric'));
        else
            PLOTARGS.toSaveFigFile = fullfile(toSaveFigDir, strcat(patient, '_fragilityMetric'));
        end
        
        if ~isempty(TEST_DESCRIP)
            PLOTARGS.toSaveFigFile = strcat(PLOTARGS.toSaveFigFile, TEST_DESCRIP);
        end
%         seizure_id = strcat('seiz', num2str(p));
        PLOTARGS.colorbarStr = 'Fragility Metric';
        if success_or_failure == 1
            PLOTARGS.titleStr = {['Success: Fragility Metric (', strcat(patient_id, seizure_id), ')'], ...
            [perturbationType, ' Perturbation: ', ' Time Locked to Seizure']};
        elseif success_or_failure == 0
            PLOTARGS.titleStr = {['Failure: Fragility Metric (', strcat(patient_id, seizure_id), ')'], ...
            [perturbationType, ' Perturbation: ', ' Time Locked to Seizure']};
        else % not set
            PLOTARGS.titleStr = {['Fragility Metric (', strcat(patient_id, seizure_id(2:end)), ')'], ...
            [perturbationType, ' Perturbation: ', ' Time Locked to Seizure']};
        end
        plotACCFragilityMetric(fragility_rankings, clinicalIndices, timePoints./fs, timeStart, timeEnd, PLOTARGS);
        
        close all
    end
end