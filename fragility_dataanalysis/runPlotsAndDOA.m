% function runPlotsAndDOA(frequency_sampling, winSize, stepSize, radius)
% settings to run
patients = {,...,
%      'pt1aw1','pt1aw2', ...
%     'pt1aslp1', 'pt1aslp2', ...
%     'pt2aw1', 'pt2aw2', ...
%     'pt2aslp1', 'pt2aslp2', ...
%     'pt3aw1', ...
%     'pt3aslp1', 'pt3aslp2', ...
%     'pt1sz2', 'pt1sz3', 'pt1sz4',...
%     'pt2sz1' 'pt2sz3' , 'pt2sz4', ...
%     'pt3sz2' 'pt3sz4', ...
%     'pt6sz3', 'pt6sz4', 'pt6sz5',...
%     'pt7sz19', 'pt7sz21', 'pt7sz22',...
%     'pt8sz1' 'pt8sz2' 'pt8sz3',...
%     'pt10sz1','pt10sz2' 'pt10sz3', ...
%     'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
%     'pt12sz1', 'pt12sz2', ...
%     'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5',...
%     'pt14sz1' 'pt14sz2' 'pt14sz3'  'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
%     'pt16sz1' 'pt16sz2' 'pt16sz3',...
    'pt17sz1' 'pt17sz2',...
%     'JH101sz1' 'JH101sz2' 'JH101sz3' 'JH101sz4',...
% 	'JH102sz1' 'JH102sz2' 'JH102sz3' 'JH102sz4' 'JH102sz5' 'JH102sz6',...
% 	'JH103sz1' 'JH103sz2' 'JH103sz3',...
% 	'JH104sz1' 'JH104sz2' 'JH104sz3',...
% 	'JH105sz1' 'JH105sz2' 'JH105sz3' 'JH105sz4' 'JH105sz5',...
% 	'JH106sz1' 'JH106sz2' 'JH106sz3' 'JH106sz4' 'JH106sz5' 'JH106sz6',...
% 	'JH107sz1' 'JH107sz2' 'JH107sz3' 'JH107sz4' 'JH107sz5' 
%     'JH107sz6' 'JH107sz7' 'JH107sz8' 'JH107sz9',...
%    'JH108sz1', 'JH108sz2', 'JH108sz3', 'JH108sz4', 'JH108sz5', 'JH108sz6', 'JH108sz7',...
%     'EZT004seiz001', 'EZT004seiz002', ...
%     'EZT006seiz001', 'EZT006seiz002', ...
%     'EZT008seiz001', 'EZT008seiz002', ...
%     'EZT009seiz001', 'EZT009seiz002', ...    
%     'EZT011seiz001', 'EZT011seiz002', ...
%     'EZT013seiz001', 'EZT013seiz002', ...
%     'EZT020seiz001', 'EZT020seiz002', ...
%     'EZT025seiz001', 'EZT025seiz002', ...
%     'EZT026seiz001', 'EZT026seiz002', ...
%     'EZT028seiz001', 'EZT028seiz002', ...
%    'EZT037seiz001', 'EZT037seiz002',...
%    'EZT019seiz001', 'EZT019seiz002',...
%    'EZT005seiz001', 'EZT005seiz002',...
%     'EZT007seiz001', 'EZT007seiz002', ...
%    	'EZT070seiz001', 'EZT070seiz002', ...
%     'Pat2sz1p', 'Pat2sz2p', 'Pat2sz3p', ...
%     'Pat16sz1p', 'Pat16sz2p', 'Pat16sz3p',...
    };

close all;

perturbationTypes = ['C', 'R'];
perturbationType = perturbationTypes(1);
PLOTALL = 1;

% data parameters to find correct directory
radius = 1.5;             % spectral radius
winSize = 500;            % 500 milliseconds
stepSize = 500; 

% winSize = 250;
% stepSize = 125;

frequency_sampling = 1000; % in Hz
IS_SERVER = 0;
% TEST_DESCRIP = 'noleftandrpp';
TEST_DESCRIP = 'after_first_removal';
TEST_DESCRIP = [];
TYPE_CONNECTIVITY = 'leastsquares';

figDir = './figures/fixedperts/';

% add libraries of functions
addpath(genpath('./fragility_library/'));
addpath(genpath('/Users/adam2392/Dropbox/eeg_toolbox'));
addpath(genpath('/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/eeg_toolbox/'));

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

    [included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
        resection_labels, frequency_sampling, center, success_or_failure] ...
            = determineClinicalAnnotations(patient_id, seizure_id);
      
%     if frequency_sampling ~=1000
%         winSize = winSize*frequency_sampling/1000;
%         stepSize = stepSize*frequency_sampling/1000;
%     end
        
    serverDir = fullfile(rootDir, '/serverdata/');
    %%- Extract an example
    adjMatDir = fullfile(serverDir, 'adjmats', strcat('win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), patient);
    
    if ~isempty(TEST_DESCRIP)
        adjMatDir = fullfile(adjMatDir, TEST_DESCRIP);
    end
    
    % directory that computed perturbation structs are saved
    finalDataDir = fullfile(serverDir, strcat(perturbationType, '_perturbations', ...
            '_radius', num2str(radius)), strcat('win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), patient);
        
    % directory that computed perturbation structs without 0 Hz inside
%     finalDataDir = fullfile(serverDir, strcat(perturbationType, '_perturbations', ...
%             '_radius', num2str(radius)), 'no0hz_win500_step500_freq1000', patient);
        
    if ~isempty(TEST_DESCRIP)
        finalDataDir = fullfile(finalDataDir, TEST_DESCRIP);
    end
    try
        final_data = load(fullfile(finalDataDir, strcat(patient, ...
            '_', perturbationType, 'perturbation_', lower(TYPE_CONNECTIVITY), '.mat')));
        final_data = final_data.perturbation_struct;
    catch e
        disp(e)
        final_data = load(fullfile(finalDataDir, strcat(patient, ...
            '_', perturbationType, 'perturbation_', lower(TYPE_CONNECTIVITY), ...
            '_radius', num2str(radius), '.mat')));
        final_data = final_data.perturbation_struct;
    end
    % set data to local variables
    minPerturb_time_chan = final_data.minNormPertMat;
    fragility_rankings = final_data.fragilityMat;
    timePoints = final_data.timePoints;
    info = final_data.info;
    num_channels = size(minPerturb_time_chan,1);
    seizureStart = info.seizure_start;
    seizureEnd = info.seizure_end;
    included_labels = info.all_labels;
 
    %%- Get Indices for All Clinical Annotations
%     if ~isempty(included_channels)
%         included_labels = labels(included_channels);
%     else
%         included_labels = labels;
%     end
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
            '_step', num2str(stepSize), '_freq', num2str(frequency_sampling), '_radius', num2str(radius)))
        if ~exist(toSaveFigDir, 'dir')
            mkdir(toSaveFigDir);
        end
        toSaveWeightsDir = fullfile(figDir, strcat(perturbationType, '_electrode_weights'), strcat(patient, num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(frequency_sampling), '_radius', num2str(radius)))
        if ~exist(toSaveWeightsDir, 'dir')
            mkdir(toSaveWeightsDir);
        end
           
        % directory that computed perturbation structs are saved
        finalDataDir = fullfile(serverDir, strcat(perturbationType, '_perturbations', ...
            '_radius', num2str(radius)), strcat('win', num2str(winSize),...
            '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), patient);
        
%             % directory that computed perturbation structs without 0 Hz inside
%         finalDataDir = fullfile(serverDir, strcat(perturbationType, '_perturbations', ...
%             '_radius', num2str(radius)), 'no0hz_win500_step500_freq1000', patient);
        
        if ~isempty(TEST_DESCRIP)
            finalDataDir = fullfile(finalDataDir, TEST_DESCRIP);
        end

        try
            final_data = load(fullfile(finalDataDir, strcat(patient, ...
                '_', perturbationType, 'perturbation_', lower(TYPE_CONNECTIVITY), ...
                '_radius', num2str(radius), '.mat')));
            final_data = final_data.perturbation_struct;
        catch e
            disp(e)
        end
        % set data to local variables
        minPerturb_time_chan = final_data.minNormPertMat;
        fragility_rankings = final_data.fragilityMat;
        info = final_data.info;
        timePoints = final_data.timePoints;
        
        seizureMarkStart = seizureStart/stepSize - 1;
        
        if seeg
            seizureMarkStart = (seizureStart-1) / stepSize;
        end
        
%         if ~INTERICTAL
%             minPerturb_time_chan = minPerturb_time_chan(:, 1:seizureMarkStart+20);
%             fragility_rankings = fragility_rankings(:, 1:seizureMarkStart+20);
%             timePoints = timePoints(1:seizureMarkStart+20,:);
%         end
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
        PLOTARGS.colorbarStr = 'Minimum 2-Induced Norm Perturbation';
        PLOTARGS.ylabelStr = 'Electrode Channels';
        PLOTARGS.xTickStep = 10*winSize/stepSize;
        PLOTARGS.titleStr = {['Minimum Norm Perturbation (', patient, ')'], ...
            [perturbationType, ' perturbation: ', ' Time Locked to Seizure']};
%         PLOTARGS.titleStr = {['Minimum Norm Perturbation For All Channels'], ...
%             ['C Perturbation: Time Locked To Seizure']};
        PLOTARGS.seizureMarkStart = seizureMarkStart;
        PLOTARGS.frequency_sampling = frequency_sampling;
        PLOTARGS.stepSize = stepSize;

        if seizureStart == size(minPerturb_time_chan,1)*winSize % interictal data
            timeStart = 1;
            timeEnd = timePoints(size(minPerturb_time_chan,2),1) / frequency_sampling;
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
                timeStart = -seizureStart / frequency_sampling;
                timeEnd = (timePoints(size(minPerturb_time_chan, 2), 2) - seizureStart)/frequency_sampling;
                
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
                timeStart = (timeIndex - preWindow - timeIndex)*winSize/frequency_sampling; 
                timeEnd = (timeIndex - timeIndex + postWindow)*winSize/frequency_sampling;
                minPerturb_time_chan = minPerturb_time_chan(:, timeIndex-60:timeIndex + postWindow);
                fragility_rankings = fragility_rankings(:, timeIndex-60:timeIndex + postWindow);
                PLOTARGS.seizureIndex = abs(timeStart);
                PLOTARGS.seizureEnd = abs(timeStart);
                PLOTARGS.toSaveFigFile = fullfile(toSaveFigDir, strcat(patient, '_minPerturbation'));
            end
        end
        
 
        if ~isempty(TEST_DESCRIP)
            PLOTARGS.toSaveFigFile = strcat(PLOTARGS.toSaveFigFile, '_', TEST_DESCRIP);
        end
        
        %% 2. Plot Min 2-Induced Norm Perturbation and Fragility Ranking
%         plotMinimumPerturbation(minPerturb_time_chan, clinicalIndices, timeStart, timeEnd, PLOTARGS);
        
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
            PLOTARGS.titleStr = {['Fragility Metric (', strcat(patient_id, seizure_id), ')'], ...
            [perturbationType, ' Perturbation: ', ' Time Locked to Seizure']};
        end
        plotFragilityMetric(fragility_rankings, minPerturb_time_chan, clinicalIndices, timePoints./frequency_sampling, timeStart, timeEnd, PLOTARGS);
        
        close all
    end
end