function computeChannelSpectrum(patient, winSize, stepSize, typeTransform, currentChan)
if nargin==0
    patient='pt1sz2';
    winSize=500;
    stepSize=250;
    typeTransform='fourier';
    currentChan=2;
end

     %% Initialization
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
%     winSize = 500;
%     stepSize = 250;

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

    % array of frequency bands
    freqBandAr(1).name    = 'delta';
    freqBandAr(1).rangeF  = [2 4];          %[2 4]
    freqBandAr(2).name    = 'theta';
    freqBandAr(2).rangeF  = [4 8];          %[4 8]
    freqBandAr(3).name    = 'alpha';
    freqBandAr(3).rangeF  = [8 16];         %[8 12]
    freqBandAr(4).name    = 'beta';
    freqBandAr(4).rangeF  = [16 32];        %[12 30]
    freqBandAr(5).name    = 'low gamma';
    freqBandAr(5).rangeF  = [32 80];        %[30 70]
    freqBandAr(6).name    = 'high gamma';
    freqBandAr(6).rangeF  = [80 160];       %[70 150]
    freqBandAr(7).name    = 'HFO';
    freqBandAr(7).rangeF  = [160 400];      %[150 400]


    % set the frequency bands to certain ranges for plotting
    for iFB=1:length(freqBandAr),
        freqBandAr(iFB).centerF = mean(freqBandAr(iFB).rangeF);
        %freqBandAr(iFB).label   = sprintf('%s-%.0fHz', freqBandAr(iFB).name(1:[ min( [length(freqBandAr(iFB).name), 6] )]), freqBandAr(iFB).centerF);
        freqBandAr(iFB).label   = sprintf('%s [%.0f-%.0f Hz]', freqBandAr(iFB).name, freqBandAr(iFB).rangeF);
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
        toSaveDir = fullfile(rootDir, strcat('/serverdata/spectral_analysis/', typeTransform, '/notchharmonics_win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
    elseif FILTER_RAW == 2
        toSaveDir = fullfile(rootDir, strcat('/serverdata/spectral_analysis/', typeTransform, '/adaptivefilter_win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
    else 
        toSaveDir = fullfile(rootDir, strcat('/serverdata/spectral_analysis/', typeTransform, '/nofilter_', 'win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
    end

    % create directory if it does not exist
    if ~exist(toSaveDir, 'dir')
        mkdir(toSaveDir);
    end

    % put clinical annotations into a struct
    clinicalLabels = struct();
    clinicalLabels.ezone_labels = ezone_labels;
    clinicalLabels.earlyspread_labels = earlyspread_labels;
    clinicalLabels.latespread_labels = latespread_labels;
    clinicalLabels.resection_labels = resection_labels;
    
    if seeg
        patient = strcat(patient_id, seizure_id);
        eegDir = fullfile(rootDir, 'data', center);
        data_struct = load(fullfile(eegDir, patient_id, patient));
    else
        eegDir = fullfile(rootDir, 'data', center);
        data_struct = load(fullfile(eegDir, patient, patient));
    end
    
    [numChans, eventDurationMS] = size(data_struct.data);
    elec_labels = data_struct.elec_labels;
    seizure_start = data_struct.seiz_start_mark;
    seizure_end = data_struct.seiz_end_mark;
    data = data_struct.data;
    tWin = 0;
    
    if strcmp(typeTransform, 'morlet')
        %%- gets the range of frequencies using eeganalparams
        waveletFreqs = eeganalparams('freqs');
        waveletWidth = eeganalparams('width');
        transformArgs.waveletWidth = waveletWidth;
        transformArgs.waveletFreqs = waveletFreqs;
    elseif strcmp(typeTransform, 'fourier')
        transformArgs.winSize = 500;
        transformArgs.stepSize = 250;
        transformArgs.mtBandWidth = 4;
        transformArgs.mtFreqs = [];
    end
    
    eegWave = data(currentChan, :);
        
    [powerMat, phaseMat, freqs] = computeSpectralPower(eegWave, fs, typeTransform, transformArgs);
    % squeeze channel dimension
    powerMat = squeeze(powerMat);
    phaseMat = squeeze(phaseMat);

    powerMatZ = zeros(size(powerMat));
    [numFreqs, numTime] = size(powerMat);
    iF  = 1:numFreqs; % # of freqs.
    iT  = 1:numTime; % # of time points

    %% Z-SCORE POWER MATRIX
    % indices of the powerMat to Z-score wrt
    for iF = 1:length(freqs),
        allVal = reshape(powerMat(iF,iT),length(1)*length(iT),1); %allVal for particular chan and freq
        mu = mean(allVal); stdev = std(allVal);

        % create the power matrix
        powerMatZ(iF,iT) = (powerMat(iF,iT)-mu)/stdev;
        if sum(isnan(powerMatZ(iF,iT)))>0
            disp('Wrong');
            keyboard;
        end
    end

    %%- condense matrices
    rangeFreqs = reshape([freqBandAr.rangeF], 2, 7)';
    if strcmp(typeTransform, 'morlet')
        %%- TIME BIN POWERMATZ WITH WINDOWSIZE AND OVERLAP
        powerMat = timeBinSpectrogram(powerMat, winSize, stepSize);
        phaseMat = timeBinSpectrogram(phaseMat, winSize, stepSize);
        
        powerMatZ = timeBinSpectrogram(powerMatZ, winSize, stepSize);

        %%- FREQUENCY BIN WITH FREQUENCY BANDS
%             powerMat = freqBinSpectrogram(powerMat, rangeFreqs, waveletFreqs);
%             phaseMat = freqBinSpectrogram(phaseMat, rangeFreqs, waveletFreqs);
    elseif strcmp(typeTransform, 'multitaper')
        disp('doing multitaper');
        %%- FREQUENCY BIN
%             powerMatZ = freqBinSpectrogram(powerMatZ, rangeFreqs, waveletFreqs);
    end

    % create 2D array to show time windows occupied by each index of new
    % power matrix
    tWin = zeros(size(powerMat, 2), 2);
    tWin(:,1) = 0 : stepSize : eventDurationMS-winSize;
    tWin(:,2) = winSize : stepSize : eventDurationMS;

    % create to save data struct
    chanData = struct();
    chanData.FILTERTYPE = FILTER_RAW;
    chanData.eegWave = eegWave;
    chanData.chanNum = currentChan;
    chanData.chanStr = elec_labels{currentChan};
    chanData.powerMat = squeeze(powerMat);
    chanData.powerMatZ = squeeze(powerMatZ);
    chanData.phaseMat = squeeze(phaseMat);
    chanData.seizure_end = seizure_end;
    chanData.seizure_start = seizure_start;
    chanData.winSize = winSize;
    chanData.stepSize = stepSize;
    chanData.waveT = tWin;
    chanData.freqs = freqs;

    %%- SAVING DIR PARAMETERS
    chanFileName = strcat(num2str(currentChan), '_', elec_labels{currentChan}, '.mat');
    saveChannel(toSaveDir, chanFileName, chanData); 
end