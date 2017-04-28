%- script to run to produce figures for EMBC 2017 Paper
% Jeju Island, South Korea
%
% Author: Adam Li
% Linear Time Varying Model Characterizes Invasive EEG Signals Generated
% From Complex Epileptic Networks
%
% This script runs a test on the computational time for model as a function
% of window size.

patient = 'pt1sz2';
winSizes = [250, 500, 1000];
l2regularization = 0;
TYPE_CONNECTIVITY = 'leastsquares';

%- add dirs
%% Set Working Directories
% set working directory
% data directories to save data into - choose one
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                      % ICM SERVER
% eegRootDirHome = '/Users/adam2392/Documents/MATLAB/Johns Hopkins/NINDS_Rotation'; % home
eegRootDirHome = '/Volumes/NIL_PASS/';                                              % external HD
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';         % at work - JHU

% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
else   error('Neither Work nor Home EEG directories exist! Exiting.'); end

addpath(genpath(fullfile(rootDir, '/fragility_library/')));
addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
addpath(rootDir);

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
    resection_labels, frequency_sampling, center, success_or_failure] ...
        = determineClinicalAnnotations(patient_id, seizure_id);

%- load data
dataDir = fullfile(rootDir, 'data', center, patient);
data = load(fullfile(dataDir, strcat(patient, '.mat')));
eeg = data.data; 
labels = data.elec_labels;
onset_time = data.seizure_eonset_ms;
offset_time = data.seizure_eoffset_ms;
[numchans, numtimes] = size(eeg);

numchans
numchans-10
winTimes = zeros(length(winSizes),11);

for N=numchans:-1:numchans-10
    randchans = randsample(numchans, N);

    %- run computation on all window sizes   
    for i=1:length(winSizes)
        %- non-overlapping windows
        winSize = winSizes(i);
        stepSize = winSize;

        % define args for computing the functional connectivity
        adj_args = struct();
        adj_args.BP_FILTER_RAW = 1;                         % apply notch filter or not?
        adj_args.frequency_sampling = frequency_sampling;   % frequency that this eeg data was sampled at
        adj_args.winSize = winSize;                         % window size
        adj_args.stepSize = stepSize;                       % step size
        adj_args.seizureStart = onset_time;               % the second relative to start of seizure
        adj_args.seizureEnd = offset_time;                   % the second relative to end of seizure
        adj_args.l2regularization = l2regularization; 
        adj_args.TYPE_CONNECTIVITY = TYPE_CONNECTIVITY;

        tic;
        % compute connectivity
        [adjMats, timePoints] = computeConnectivity(eeg, adj_args);
        wintimes(i, N) = toc;
    end
end

%- plot computation time vs. window size
figure;
% plot(mean(winSizes, 2), winTimes, 'k-');
shadedErrorBar(winSizes, mean(winTimes, 2), std(winTimes, 1, 2));
axes = gca;
title('Window Sizes vs. Computation Time for LTV Model');
xlabel('Window Size (ms)');
ylabel('Computation Time (sec)');
axes.FontSize = 20;

