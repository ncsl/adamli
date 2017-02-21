% function runPlotsAndDOA(frequency_sampling, winSize, stepSize, radius)
% settings to run
patients = {,...,
'pt1sz2',...
    };

close all;

perturbationTypes = ['C', 'R'];
perturbationType = perturbationTypes(1);
PLOTALL = 1;
INTERICTAL = 0;

% data parameters to find correct directory
radius = 1.5;             % spectral radius
winSize = 500;            % 500 milliseconds
stepSize = 500; 
frequency_sampling = 1000; % in Hz
IS_SERVER = 0;
TEST_DESCRIP = 'noleftandrpp';
TEST_DESCRIP = 'after_first_removal';
TEST_DESCRIP = [];
TYPE_CONNECTIVITY = 'leastsquares';


% add libraries of functions
addpath('../');
addpath(genpath('../fragility_library/'));
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

patient = 'pt1sz2';
figDir = fullfile(rootDir, 'figures/sensitivityAnalysis/');
dataDir = fullfile(rootDir, 'serverdata/adjmats', patient);
numElecsToRemove = 1:25;

%%- Begin Loop Through Different Patients Here
for i=1:length(numElecsToRemove)
    patient

    % set patientID and seizureID
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

    [included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
        resection_labels, frequency_sampling, center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);
        
        
    %%- Extract an example
    finalDataDir = fullfile(dataDir, strcat(patient, '_numelecs', num2str(i)));
    
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
    y_resectionindices = findResectionIndices(included_labels, resection_labels);

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
        toSaveFigDir = fullfile(figDir, perturbationType, strcat(patient, '_', num2str(i), '_win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(frequency_sampling), '_radius', num2str(radius)))
        if ~exist(toSaveFigDir, 'dir')
            mkdir(toSaveFigDir);
        end
           
        %%- Extract an example
        finalDataDir = fullfile(dataDir, strcat(patient, '_numelecs', num2str(i)));

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
        info = final_data.info;
        timePoints = final_data.timePoints;
        
        seizureMarkStart = seizureStart/winSize;
        
        if seeg
            seizureMarkStart = (seizureStart-1) / winSize;
        end
        
        minPerturb_time_chan = minPerturb_time_chan(:, 1:seizureMarkStart+20);
        fragility_rankings = fragility_rankings(:, 1:seizureMarkStart+20);
        timePoints = timePoints(1:seizureMarkStart+20,:);
       
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
            [perturbationType, ' perturbation: ', ' Time Locked to Seizure'], ...
            ['With ', num2str(i), ' electrodes removed']};
        PLOTARGS.seizureMarkStart = seizureMarkStart;

        if INTERICTAL % interictal data
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
 
        PLOTARGS.toSaveFigFile = fullfile(toSaveFigDir, strcat(patient, '_minPerturbation'));
        if ~isempty(TEST_DESCRIP)
            PLOTARGS.toSaveFigFile = strcat(PLOTARGS.toSaveFigFile, '_', TEST_DESCRIP);
        end
        
        %% 2. Plot Min 2-Induced Norm Perturbation and Fragility Ranking
        plotMinimumPerturbation(minPerturb_time_chan, clinicalIndices, timeStart, timeEnd, PLOTARGS);
        
        if PLOTALL
            PLOTARGS.toSaveFigFile = fullfile(toSaveFigDir, strcat(patient, '_fragilityMetric_upto10secs'));
        else
            PLOTARGS.toSaveFigFile = fullfile(toSaveFigDir, strcat(patient, '_fragilityMetric'));
        end
        
        if ~isempty(TEST_DESCRIP)
            PLOTARGS.toSaveFigFile = strcat(PLOTARGS.toSaveFigFile, TEST_DESCRIP);
        end
        
        PLOTARGS.colorbarStr = 'Fragility Metric';
        PLOTARGS.titleStr = {['Fragility Metric (', patient, ')'], ...
            [perturbationType, ' perturbation: ', ' Time Locked to Seizure'],...
            ['With ', num2str(i), ' electrodes removed']};
        plotFragilityMetric(fragility_rankings, minPerturb_time_chan, clinicalIndices, timePoints./frequency_sampling, timeStart, timeEnd, PLOTARGS);
        
        close all
    end
end