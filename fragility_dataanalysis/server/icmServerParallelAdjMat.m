function icmServerParallelAdjMat(patient, currentWin, winSize, stepSize)
    addpath(genpath('../fragility_library/'));
    addpath(genpath('../eeg_toolbox/'));
    addpath('../');
    IS_SERVER = 1;
    if nargin == 0 % testing purposes
        patient='EZT005seiz001';
        patient='JH102sz6';
        patient='pt1sz4';
        % window paramters
        winSize = 500; % 500 milliseconds
        stepSize = 500; 
        frequency_sampling = 1000; % in Hz
    end

    setupScripts;

    % apply included channels to eeg and labels
    if ~isempty(included_channels)
        eeg = eeg(included_channels, :);
        labels = labels(included_channels);
    end

    tempDir = '../tempdata/';
    
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
    % apply band notch filter to eeg data
    eeg = buttfilt(eeg,[59.5 60.5], frequency_sampling,'stop',1);
    
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

    serverComputeConnectivity(patient_id, seizure_id, currentWin, eeg, clinicalLabels, adj_args);
end