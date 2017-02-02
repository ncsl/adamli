close all;
clear;
clc;

patients = {,...
%     'pt1sz2', 'pt1sz3', 'pt1sz4',...
%     'pt2sz1', 'pt2sz3', 'pt2sz4',...
%     'pt3sz2', 'pt3sz4', ... 
%     'pt1aw1', 'pt1aw2', ...
%     'pt1aslp1', 'pt1aslp2', ...
%     'pt2aw1', 'pt2aw2', ...
% %     'pt2aslp1', 
% 'pt2aslp2', ...
% 'pt3aslp1', 'pt3aslp2',...
    'pt2aslp2', ...
    'pt3aslp1', 'pt3aslp2', ...
    'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
    'pt17sz1' 'pt17sz2',...
%     'pt3aw1', 'pt3aslp1', 'pt3aslp2',...
%     'pt8sz1' 'pt8sz2' 'pt8sz3',...
%     'pt10sz1' 'pt10sz2' 'pt10sz3', ...
%     'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
%     'pt14sz1' 'pt14sz2' 'pt14sz3' 'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
%     'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt17sz1' 'pt17sz2' 'pt17sz3',...
%     'JH101sz1' 'JH101sz2' 'JH102sz3' 'JH102sz4',...
% 	'JH102sz1' 'JH102sz2' 'JH102sz3' 'JH102sz4' 'JH102sz5' 'JH102sz6',...
% 	'JH103sz1' 'JH102sz2' 'JH102sz3',...
% 	'JH104sz1' 'JH104sz2' 'JH104sz3',...
% 	'JH105sz1' 'JH105sz2' 'JH105sz3' 'JH105sz4' 'JH105sz5',...
% 	'JH106sz1' 'JH106sz2' 'JH106sz3' 'JH106sz4' 'JH106sz5' 'JH106sz6',...
% 	'JH107sz1' 'JH107sz2' 'JH107sz3' 'JH107sz4' 'JH107sz5' 'JH107sz6' 'JH107sz7' 'JH107sz8' 'JH107sz8',...
% 'pt8sz1' 'pt8sz2' 'pt8sz3',...
%     'pt10sz1' 'pt10sz2' 'pt1git0sz3', ...
%     'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
%     'pt14sz1' 'pt14sz2' 'pt14sz3' 'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
%     'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt17sz1' 'pt17sz2',...
%   'EZT037seiz001', 'EZT037seiz002',...
%    'EZT019seiz001', 'EZT019seiz002',...
%    'EZT005seiz001', 'EZT005seiz002', 'EZT007seiz001', 'EZT007seiz002', ...
%    	'EZT070seiz001', 'EZT070seiz002', ...
    };

addpath(genpath('./spectral_library/'));

% REFERENCE ELECTRODE
% THIS_REF_TYPE = referenceType; 
% FILTERING OPTIONS
BP_FILTER_RAW = 1;  %-0 or 1: apply a bandpass filter to the raw traces (1-499 hz)
typeTransform = 'morlet';
winSize = 500;
stepSize = 250;

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
freqBandYticks  = unique([freqBandAr(1:7).rangeF]);
for iFB=1:length(freqBandYticks), freqBandYtickLabels{iFB} = sprintf('%.0f Hz', freqBandYticks(iFB)); end


%%- apply a bandpass filter raw data? (i.e. pre-filter the wave?)
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

%% LOAD EVENTS STRUCT AND SET DIRECTORIES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%------------------ STEP 1: Load events and set behavioral directories                   ---------------------------------------%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% data directories to save data into - choose one
eegRootDirWork = '/Users/liaj/Documents/MATLAB/paremap';     % work
% eegRootDirHome = '/Users/adam2392/Documents/MATLAB/Johns Hopkins/NINDS_Rotation';  % home
eegRootDirHome = '/Volumes/NIL_PASS';
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/data';
% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirWork)), eegRootDir = eegRootDirWork;
elseif ~isempty(dir(eegRootDirHome)), eegRootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), eegRootDir = eegRootDirJhu;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

%% FILTER AND PREPROCESS PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%------------------ STEP 3: DATA INPUT TO GETE_MS, MULTIPHASEVEC3 AND ZSCORE
%%------------------      AND SET UP POWER, POWERZ AND PHASE MATRICS        ---------------------%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BufferMS        = 1000;              % grab excess data before/after event window so filters don't have edge effect
resampledrate   = 1000;              % don't resample... keep the 1kHz native sample rate

%%- gets the range of frequencies using eeganalparams
waveletFreqs = eeganalparams('freqs');
waveletWidth = eeganalparams('width');

for iPat=1:length(patients)
    patient = patients{iPat};
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

    [included_channels, ezone_labels, earlyspread_labels, latespread_labels, resection_labels, frequency_sampling, center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);
        
    toSaveDir = fullfile(strcat('./serverdata/spectral_analysis/', 'win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), patient); % at lab

    if ~exist(toSaveDir, 'dir')
        mkdir(toSaveDir);
    end
    toSaveDir

    if seeg
        patient = strcat(patient_id, seizure_id);
        eegDir = fullfile(eegRootDir, center);
        data_struct = load(fullfile(eegDir, patient_id, patient));
    else
        eegDir = fullfile(eegRootDir, center);
        data_struct = load(fullfile(eegDir, patient, patient));
    end
    

    [numChannels, eventDurationMS] = size(data_struct.data);
    elec_labels = data_struct.elec_labels;
    seizure_start = data_struct.seiz_start_mark;
    seizure_end = data_struct.seiz_end_mark;
    data = data_struct.data;
    tWin = 0;
    
    parfor iChan=1:numChannels
        eegWaveV = data(iChan,:);
        % add buffer to the eeg wave
        eegWaveV = [zeros(1, BufferMS), eegWaveV, zeros(1, BufferMS)];
        
         % notch filter to eliminate 60 Hz noise
        eegWaveV = buttfilt(eegWaveV,[59.5 60.5],resampledrate,'stop',1); %-filter is overkill: order 1 --> 25 dB drop (removing 5-15dB peak)

        if strcmp(typeTransform, 'morlet') % OPTION 1: perform wavelet spectral analysis
            %%- i. multiphasevec3: get the phase and power
            % power, phase matrices for events x frequency x duration of time for each channel
            [rawPhase,rawPow] = multiphasevec3(waveletFreqs,eegWaveV,resampledrate,waveletWidth);
            
            %%- ii. REMOVE LEADING/TRAILING buffer areas from power, phase,
            %%eegWave, timeVector
            rawPow   = rawPow(:,:,BufferMS+1:end-BufferMS);
            rawPhase = rawPhase(:,:,BufferMS+1:end-BufferMS);
            eegWaveV = eegWaveV(:,BufferMS+1:end-BufferMS); % remove buffer area

            %%- iii. make powerMat, phaseMat and set time and freq axis
            % chan X event X freq X time
            % make power 10*log(power)
            powerMat = 10*log10(rawPow);
            phaseMat = rawPhase;
            freqs = waveletFreqs;
            
            disp(['Morlet wavelet computed and power matrix computed for ...', num2str(iChan)])
        end
        
%         powerMatZ = zeros(size(powerMat));
        iF  = 1:length(waveletFreqs); % # of freqs.
        iT  = 1:size(powerMat, 3); % # of time points

        %% B. Z-SCORE POWER MATRIX
        % indices of the powerMat to Z-score wrt
%         for iF = 1:length(freqs),
%             allVal = reshape(squeeze(powerMat(:,iF,iT)),length(1)*length(iT),1); %allVal for particular chan and freq
%             mu = mean(allVal); stdev = std(allVal);
% 
%             % create the power matrix
%             powerMatZ(:,iF,iT) = (powerMat(:,iF,iT)-mu)/stdev;
%             if sum(isnan(powerMatZ(:,iF,iT)))>0
%                 keyboard;
%             end
%         end
%         
        %%- condense matrices
        rangeFreqs = reshape([freqBandAr.rangeF], 2, 7)';
        if strcmp(typeTransform, 'morlet')
            %%- TIME BIN POWERMATZ WITH WINDOWSIZE AND OVERLAP
            powerMat = timeBinSpectrogram(powerMat, winSize, stepSize);
            phaseMat = timeBinSpectrogram(phaseMat, winSize, stepSize);
            
            %%- FREQUENCY BIN WITH FREQUENCY BANDS
%             powerMat = freqBinSpectrogram(powerMat, rangeFreqs, waveletFreqs);
%             phaseMat = freqBinSpectrogram(phaseMat, rangeFreqs, waveletFreqs);

            % create 2D array to show time windows occupied by each index of new
            % power matrix
            tWin = zeros(size(powerMat, 3), 2);
            tWin(:,1) = 0 : stepSize : eventDurationMS-winSize;
            tWin(:,2) = winSize : stepSize : eventDurationMS;
%             
%             tWin = zeros(size(powerMat, 3), 2);
%             tWin(:,1) = 0 : winSize : eventDurationMS-winSize;
%             tWin(:,2) = winSize : winSize : eventDurationMS;
        end
        
        % create to save data struct
        chanData = struct();
        chanData.eegWave = eegWaveV;
        chanData.chanNum = iChan;
        chanData.chanStr = elec_labels{iChan};
        chanData.freqBands = {freqBandAr.name};
        chanData.powerMat = squeeze(powerMat);
        chanData.phaseMat = squeeze(phaseMat);
        chanData.seizure_end = seizure_end;
        chanData.seizure_start = seizure_start;
        chanData.winSize = winSize;
        chanData.stepSize = stepSize;
        chanData.waveT = tWin;
        chanData.freqs = freqs;

        %%- SAVING DIR PARAMETERS
        chanFileName = strcat(num2str(iChan), '_', elec_labels{iChan}, '.mat');
        saveChannel(toSaveDir, chanFileName, chanData);
                
    end
end
