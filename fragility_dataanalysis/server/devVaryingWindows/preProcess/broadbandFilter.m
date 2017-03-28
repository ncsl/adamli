%
% Description
% 1. Take spectral power computed before and load in per channel
% 2. For each channel, compute a power distribution for each frequency
% 3. For each channel, go across time and look if there are frequencies in
% tails of the power distribution
% 4. apply thresholding
% 5. Return time points that are broadband noise affected
patients = {
%     'UMMC001_sz1', 'UMMC001_sz2', 'UMMC001_sz3', ...
%     'UMMC002_sz1', 'UMMC002_sz2', 'UMMC002_sz3', ...
%     'UMMC003_sz1', 'UMMC003_sz2', 'UMMC003_sz3', ...
%     'UMMC004_sz1', 'UMMC004_sz2', 'UMMC004_sz3', ...
%     'UMMC005_sz1', 'UMMC005_sz2', 'UMMC005_sz3', ...
%     'UMMC006_sz1', 'UMMC006_sz2', 'UMMC006_sz3', ...
%     'UMMC007_sz1', 'UMMC007_sz2','UMMC007_sz3', ...
%     'UMMC008_sz1', 'UMMC008_sz2', 'UMMC008_sz3', ...
%     'UMMC009_sz1', 'UMMC009_sz2', 'UMMC009_sz3', ...
    'pt1aw2', 'pt1sz4', ...
};
patient = patients{1};
typeTransform = 'morlet';

    % Initialization
    %- 0 == no filtering
    %- 1 == notch filtering
    %- 2 == adaptive filtering
    FILTER_RAW = 2; 
    winSize = 500;
    stepSize = 250;
    
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
    buffpatid = patient_id;
    if strcmp(patient_id(end), '_')
        patient_id = patient_id(1:end-1);
    end
    
    %% DEFINE OUTPUT DIRS AND CLINICAL ANNOTATIONS
    %- Edit this file if new patients are added.
    [included_channels, ezone_labels, earlyspread_labels,...
        latespread_labels, resection_labels, fs, ...
        center] ...
                = determineClinicalAnnotations(patient_id, seizure_id);
    patient_id = buffpatid;
    
    % set directory to save computed data
    if FILTER_RAW == 1
        spectDir = fullfile(rootDir, strcat('/serverdata/spectral_analysis/', typeTransform, '/notchharmonics_win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
    elseif FILTER_RAW == 2
        spectDir = fullfile(rootDir, strcat('/serverdata/spectral_analysis/', typeTransform, '/adaptivefilter/win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
    else 
        spectDir = fullfile(rootDir, strcat('/serverdata/spectral_analysis/', typeTransform, '/nofilter_', 'win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
    end
    
    % get all the spectral power files for this patient
    elecFile = fullfile(spectDir, strcat(patient, '_', typeTransform));
    
    % load in the electrode file
    data = load(elecFile);
    data = data.data;
    
    chanStrs = data.chanStr;
    winSize = data.winSize;
    stepSize = data.stepSize;
    seizureStart = data.seizure_start;
    seizureEnd = data.seizure_end;
    timePoints = data.waveT;
    freqs = data.freqs;
    powerMatZ = data.powerMatZ;
    
    % get seizure marks in window
    seizureStartMark = seizureStart / stepSize - (winSize/stepSize - 1);
    seizureEndMark = seizureEnd / stepSize - (winSize/stepSize - 1);
    
    [numChans, numFreqs, numTimes] = size(powerMatZ);
    lowperctile = 1;
    highperctile = 99;
    perctiles = zeros(numFreqs, 2);
    %% Loop Through Channels and Apply Broadband Filter
    for iChan=1:numChans
        %- get channel power matrix
        chanPowerMat = squeeze(powerMatZ(iChan, :, 1:seizureStartMark));
        mask = zeros(size(chanPowerMat));
        
        %- compute low and high percentiles
        perctiles(:, 1) = prctile(chanPowerMat, lowperctile, 2);
        perctiles(:, 2) = prctile(chanPowerMat, highperctile, 2);
        
        %- apply mask to each frequency in the power matrix
        for i=1:numFreqs
            indices = chanPowerMat(i, :) > perctiles(i, 2);
            mask(i, indices) = 1;
            
            indices = chanPowerMat(i, :) < perctiles(i, 1);
            mask(i, indices) = -1;
        end
        
        %- create matrix on the mask of only high powers
        highmask = zeros(size(mask));
        highmask(mask == 1) = 1;
        highinteg = trapz(freqs, highmask, 1) ./ trapz(freqs, ones(size(highmask)), 1);
        
        imagesc(highinteg);
        figure;
        imagesc(mask);
        colorbar(); hold on;
        plot([seizureStartMark seizureStartMark], [1 41], 'k')
        
    end
    
    
    
    