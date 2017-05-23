function computeChannelSpectrum(patient, winSize, stepSize, typeTransform, currentChan)
if nargin==0
    patient='pt1sz2';
%     patient='UMMC003_sz1';
    winSize=250;
    stepSize=125;
    typeTransform='fourier';
    typeTransform = 'morlet';
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
    FILTER_RAW = 1; 
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
        latespread_labels, resection_labels, frequency_sampling, ...
        center] ...
                = determineClinicalAnnotations(patient_id, seizure_id);
    patient_id = buffpatid;
    
    % set directory to save computed data
    tempDir = fullfile(rootDir, 'server/devVaryingWindows/preProcess/tempData/',...
        strcat('win', num2str(winSize), '_step', num2str(stepSize)), ...
        strcat(patient, '_', typeTransform));

    if ~exist(tempDir, 'dir')
        mkdir(tempDir);
    end
    
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
    seizure_start = data_struct.seizure_eonset_ms;
    seizure_end = data_struct.seizure_eoffset_ms;
    data = data_struct.data;
    
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
    
    leneeg = floor(length(eegWave) / frequency_sampling) * frequency_sampling;
    eegWave = eegWave(1:leneeg);
    
    % set the number of harmonics
    numHarmonics = floor(frequency_sampling/2/60) - 1;

    %- apply filtering on the eegWave
    if FILTER_RAW == 1
       % apply band notch filter to eeg data
        eegWave = buttfilt(eegWave,[59.5 60.5], frequency_sampling,'stop',1);
        eegWave = buttfilt(eegWave,[119.5 120.5], frequency_sampling,'stop',1);
        if frequency_sampling >= 250
            eegWave = buttfilt(eegWave,[179.5 180.5], frequency_sampling,'stop',1);
            eegWave = buttfilt(eegWave,[239.5 240.5], frequency_sampling,'stop',1);
            
            if frequency_sampling >= 500
                eegWave = buttfilt(eegWave,[299.5 300.5], frequency_sampling,'stop',1);
                eegWave = buttfilt(eegWave,[359.5 360.5], frequency_sampling,'stop',1);
                eegWave = buttfilt(eegWave,[419.5 420.5], frequency_sampling,'stop',1);
                eegWave = buttfilt(eegWave,[479.5 480.5], frequency_sampling,'stop',1);
            end
        end
    elseif FILTER_RAW == 2
         % apply an adaptive filtering algorithm.
        eegWave = removePLI(eegWave, frequency_sampling, numHarmonics, [50,0.01,4], [0.1,2,4], 2, 60);
    else 
        disp('no filtering?');
    end
    
    [powerMat, phaseMat, freqs, t_sec] = computeSpectralPower(eegWave, frequency_sampling, typeTransform, transformArgs);
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
    if strcmp(typeTransform, 'morlet')
        %%- TIME BIN POWERMATZ WITH WINDOWSIZE AND OVERLAP
        [powerMat, t_sec] = timeBinSpectrogram(powerMat, frequency_sampling, winSize, stepSize);
        [phaseMat, ~] = timeBinSpectrogram(phaseMat, frequency_sampling, winSize, stepSize);
        
        [powerMatZ, ~] = timeBinSpectrogram(powerMatZ, frequency_sampling, winSize, stepSize);

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
    if frequency_sampling ~=1000
        winSizefs = winSize*frequency_sampling/1000;
        stepSizefs = stepSize*frequency_sampling/1000;
    end

    % create to save data struct
    chanData = struct();
    chanData.FILTERTYPE = FILTER_RAW;
%     chanData.eegWave = eegWave;
    chanData.chanNum = currentChan;
    chanData.chanStr = elec_labels{currentChan};
    chanData.powerMat = squeeze(powerMat);
    chanData.powerMatZ = squeeze(powerMatZ);
%     chanData.phaseMat = squeeze(phaseMat);
    chanData.seizure_end = seizure_end;
    chanData.seizure_start = seizure_start;
    chanData.winSizeMS = winSize;
    chanData.stepSizeMS = stepSize;
    chanData.waveT = t_sec;
    chanData.freqs = freqs;

    %%- SAVING DIR PARAMETERS
    chanFileName = strcat(num2str(currentChan), '_', elec_labels{currentChan}, '.mat');
    saveChannel(tempDir, chanFileName, chanData); 
end