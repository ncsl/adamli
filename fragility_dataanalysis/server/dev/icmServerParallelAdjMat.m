function icmServerParallelAdjMat(patient, currentWin, winSize, stepSize)
    addpath(genpath('../fragility_library/'));
    addpath(genpath('../eeg_toolbox/'));
    addpath(('../'));
    IS_SERVER = 1;
    if nargin == 0 % testing purposes
        patient='EZT005seiz001';
        patient='JH102sz6';
        patient='pt1sz4';
        % window paramters
        winSize = 500; % 500 milliseconds
        stepSize = 500; 
        frequency_sampling = 1000; % in Hz
        currentWin = 1;
    end

    setupScripts;

    % apply included channels to eeg and labels
    if ~isempty(included_channels)
        eeg = eeg(included_channels, :);
        labels = labels(included_channels);
    end

    tempDir = fullfile('../tempdata/', patient);
    if ~exist(tempDir, 'dir')
        mkdir(tempDir);
    end
    
    BP_FILTER_RAW=1;
    %- apply a bandpass filter raw data? (i.e. pre-filter the wave?)
    if BP_FILTER_RAW==1,
        preFiltFreq      = [1 499];   %[1 499] [2 250]; first bandpass filter data from 1-499 Hz
        preFiltType      = 'bandpass';
        preFiltOrder     = 2;
        preFiltStr       = sprintf('%s filter raw; %.1f - %.1f Hz',preFiltType,preFiltFreq);
        preFiltStrShort  = '_BPfilt';
    else
        preFiltFreq      = []; %keep this empty to avoid any filtering of the raw data
        preFiltType      = 'stop';
        preFiltOrder     = 1;
        preFiltStr       = 'Unfiltered raw traces';
        preFiltStrShort  = '_noFilt';
    end
    
    % set stepsize and window size to reflect sampling rate (milliseconds)
    stepSize = stepSize * frequency_sampling/1000; 
    winSize = winSize * frequency_sampling/1000;

    % paramters describing the data to be saved
    % window parameters - overlap, #samples, stepsize, window pointer
    lenData = size(eeg,2); % length of data in seconds
    numWindows = lenData/stepSize;

    % initialize timePoints vector and adjacency matrices
    timePoints = [1:stepSize:lenData-winSize+1; winSize:stepSize:lenData]';
    
    % apply band notch filter to eeg data
    eeg = buttfilt(eeg,[59.5 60.5], frequency_sampling,'stop',1);
    tempeeg = eeg(:, timePoints(currentWin,1):timePoints(currentWin,2));
    
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
        
        save(fullfile(tempDir, 'infoAdjMat'), 'info');
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

    serverComputeConnectivity(patient_id, seizure_id, currentWin, tempeeg, adj_args);
end