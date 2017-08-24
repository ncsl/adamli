patients = {...,
%      'pt1aw1','pt1aw2', ...
% %     'pt2aw2', 'pt2aslp2',...
% %     'pt1aslp1','pt1aslp2', ...
% %     'pt2aw1', 'pt2aw2', ...
% %     'pt2aslp1', 'pt2aslp2', ...
% %     'pt3aw1', ...
% %     'pt3aslp1', 'pt3aslp2', ...
% %     'pt1sz2', 'pt1sz3', 'pt1sz4',...
% %     'pt2sz1' 'pt2sz3' , 'pt2sz4', ...
% %     'pt3sz2' 'pt3sz4', ...
% %     'pt6sz3', 'pt6sz4', 'pt6sz5',...
% %     'pt7sz19', 'pt7sz21', 'pt7sz22',...
% %     'pt8sz1' 'pt8sz2' 'pt8sz3',...
% %     'pt10sz1','pt10sz2' 'pt10sz3', ...
% %     'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
% %     'pt12sz1', 'pt12sz2', ...
% %     'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5',...
% %     'pt14sz1' 'pt14sz2' 'pt14sz3'  'pt16sz1' 'pt16sz2' 'pt16sz3',...
% %     'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
% %     'pt16sz1' 'pt16sz2' 'pt16sz3',...
    'pt17sz1' 'pt17sz2', 'pt17sz3', ...
};

% parameters
winSize=250;
stepSize=125;
filterType = 'adaptivefilter';  % adaptive, notch, or no

%% Set Root Directories
% data directories to save data into - choose one
eegRootDirHD = '/Volumes/NIL Pass/';
eegRootDirHD = '/Volumes/ADAM LI/';
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                 % at ICM server 
eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';   % at home macbook
eegRootDirHome = 'test';
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';    % at JHU workstation
eegRootDirMarcctest = '/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/'; % at MARCC server
eegRootDirMarcc = '/scratch/groups/ssarma2/adamli/fragility_dataanalysis/';

% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
elseif ~isempty(dir(eegRootDirMarcc)), rootDir = eegRootDirMarcc;
elseif ~isempty(dir(eegRootDirHD)), rootDir = eegRootDirHD;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

addpath(genpath(fullfile(rootDir, '/fragility_library/')));
addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
addpath(rootDir);

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

for iPat=1:length(patients)
    patient = patients{iPat};
    [~, patient_id, seizure_id, seeg] = splitPatient(patient);

    [included_channels, ezone_labels, earlyspread_labels, latespread_labels, resection_labels, frequency_sampling, center] ...
        = determineClinicalAnnotations(patient_id, seizure_id);


    tempDir = fullfile(rootDir, 'server/devVaryingWindows/preProcess/tempData/',...
                strcat(typeTransform, '/', filterType,'_win', num2str(winSize), ...
                    '_step', num2str(stepSize), '_freq', num2str(fs)), patient);

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
        transformArgs.winSize = winSize;
        transformArgs.stepSize = stepSize;
        transformArgs.mtBandWidth = 4;
        transformArgs.mtFreqs = [];
    end

    for iChan=1:numChans
        eegWave = data(iChan, :);
    
        leneeg = floor(length(eegWave) / fs) * fs;
        eegWave = eegWave(1:leneeg);

        % set the number of harmonics
        numHarmonics = floor(fs/2/60) - 1;

        %- apply filtering on the eegWave
        if strcmp(filterType, 'notchfilter')
           % apply band notch filter to eeg data
            eegWave = buttfilt(eegWave,[59.5 60.5], fs,'stop',1);
            eegWave = buttfilt(eegWave,[119.5 120.5], fs,'stop',1);
            if fs >= 500
                eegWave = buttfilt(eegWave,[179.5 180.5], fs,'stop',1);
                eegWave = buttfilt(eegWave,[239.5 240.5], fs,'stop',1);

                if fs >= 1000
                    eegWave = buttfilt(eegWave,[299.5 300.5], fs,'stop',1);
                    eegWave = buttfilt(eegWave,[359.5 360.5], fs,'stop',1);
                    eegWave = buttfilt(eegWave,[419.5 420.5], fs,'stop',1);
                    eegWave = buttfilt(eegWave,[479.5 480.5], fs,'stop',1);
                end
            end
        elseif strcmp(filterType, 'adaptivefilter')
             % apply an adaptive filtering algorithm.
            eegWave = removePLI_multichan(eegWave, fs, numHarmonics, [50,0.01,4], [0.1,2,4], 2, 60);
        else 
            disp('no filtering?');
        end

        [powerMat, phaseMat, freqs, t_sec] = computeSpectralPower(eegWave, fs, typeTransform, transformArgs);
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
            [powerMat, t_sec] = timeBinSpectrogram(powerMat, fs, winSize, stepSize);
            [phaseMat, ~] = timeBinSpectrogram(phaseMat, fs, winSize, stepSize);

            [powerMatZ, ~] = timeBinSpectrogram(powerMatZ, fs, winSize, stepSize);

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
        if fs ~=1000
            winSizefs = winSize*fs/1000;
            stepSizefs = stepSize*fs/1000;
        end

        % create to save data struct
        chanData = struct();
        chanData.FILTERTYPE = filterType;
    %     chanData.eegWave = eegWave;
        chanData.chanNum = iChan;
        chanData.chanStr = elec_labels{iChan};
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
        chanFileName = strcat(num2str(iChan), '_', elec_labels{iChan}, '.mat');
        saveChannel(tempDir, chanFileName, chanData); 
    end
end