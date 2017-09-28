patients = {,...
%     'LA01_ICTAL', 'LA01_Inter', ...
%     'LA02_ICTAL', 'LA02_Inter', ...
%     'LA03_ICTAL', 'LA03_Inter', ...
%     'LA04_ICTAL', 'LA04_Inter', ...
%     'LA05_ICTAL', 'LA05_Inter', ...
    'LA09_ICTAL', 'LA09_Inter', ...
    'LA10_ICTAL', 'LA10_Inter', ...
    'LA11_ICTAL', 'LA11_Inter', ...
    'LA15_ICTAL', 'LA15_Inter', ...
    'LA16_ICTAL', 'LA16_Inter', ...
%     'LA07_ICTAL', 'LA07_Inter', ...
%     'LA12_ICTAL', 'LA12_Inter', ...
%     'LA13_ICTAL', 'LA13_Inter', ...
%     'LA14_ICTAL', 'LA14_Inter', ...
%     'LA17_ICTAL', 'LA17_Inter', ...
};
%% Set Root Directories
% data directories to save data into - choose one
eegRootDirHD = '/Volumes/NIL Pass/';
eegRootDirHD = '/Volumes/ADAM LI/';
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                 % at ICM server 
eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';   % at home macbook
% eegRootDirHome = 'test';
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';    % at JHU workstation
eegRootDirMarcctest = '/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/'; % at MARCC server
eegRootDirMarcc = '/scratch/groups/ssarma2/adamli/fragility_dataanalysis/';

% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
% elseif ~isempty(dir(eegRootDirHD)), rootDir = eegRootDirHD;
elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
elseif ~isempty(dir(eegRootDirMarcc)), rootDir = eegRootDirMarcc;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), dataDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHD)), dataDir = eegRootDirHD;
elseif ~isempty(dir(eegRootDirJhu)), dataDir = eegRootDirJhu;
elseif ~isempty(dir(eegRootDirMarcc)), dataDir = eegRootDirMarcc;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

addpath(genpath(fullfile(rootDir, '/fragility_library/')));
addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
addpath(rootDir);

% parameters
% data parameters to find correct directory
radius = 1.5;             % spectral radius of perturbation
winSize = 250;            % window size in milliseconds
stepSize = 125; 
filterType = 'notchfilter';  % adaptive, notch, or no
typeConnectivity = 'leastsquares'; 
reference = '';

% broadband filter parameters
typeTransform = 'fourier'; % morlet, or fourier
JOBTYPE = 1;

% for iPat=1:length(patients)
%     patient = patients{iPat};
%     % run a computation on checking patients if there is missing data
%     [toCompute, patWinsToCompute] = checkPatient(patient, rootDir, winSize, stepSize, filterType, radius, JOBTYPE);
%      
%     if toCompute
%         for iWin=1:length(patWinsToCompute)
%             winToCompute = patWinsToCompute(iWin);
%             parallelComputeConnectivity(patient, winSize, stepSize, winToCompute);
%         end
%     end
% end

%% Just Run Data
fprintf('Loading data...');

datafile = fullfile('/Volumes/ADAM LI/data/trev_data.mat');
data = load(datafile);

% READ EEG FILE Mat File
% files to process
eeg = data.data1;
fprintf('Loaded data...');
clear data

%% Parameters HARD CODED
%- 0 == no filtering
%- 1 == notch filtering
%- 2 == adaptive filtering
% FILTER_RAW = 2; 
filterType = 'notchfilter';
TYPE_CONNECTIVITY = 'leastsquares';
l2regularization = 0;
% set options for connectivity measurements
OPTIONS.l2regularization = l2regularization;
fs = 1000; % 1 kHz sampling by default

tempDir = fullfile(rootDir, 'server/marccDev/matlab_lib/tempData/', ...
                'connectivity', filterType, ...
                strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)), ...
                'trev');
if ~exist(tempDir, 'dir')
    mkdir(tempDir);
end

%- initialize the number of samples in the window / step (ms) 
numSampsInWin = winSize * fs / 1000;
numSampsInStep = stepSize * fs / 1000;
numWins = floor(size(eeg, 2) / numSampsInStep - numSampsInWin/numSampsInStep + 1);

% apply included channels to eeg and labels
included_channels = [];
if ~isempty(included_channels)
    eeg = eeg(included_channels, :);
end

%% Perform Preprocessing - Referencing and Filtering
% perform common average referencing if needed
if strcmp(reference, 'avgref')
    if size(eeg, 1) > size(eeg, 2)
        eeg = eeg';
    end
    avg = mean(eeg, 1);
    eeg = eeg-avg;
end

% paramters describing the data to be saved
% window parameters - overlap, #samples, stepsize, window pointer
lenData = size(eeg,2); % length of data in seconds
numChans = size(eeg,1);

%- apply filtering on the eegWave
if strcmp(filterType, 'notchfilter')
   % apply band notch filter to eeg data
    eeg = buttfilt(eeg,[59.5 60.5], fs,'stop',1);
    eeg = buttfilt(eeg,[119.5 120.5], fs,'stop',1);
    if fs >= 500
        eeg = buttfilt(eeg,[179.5 180.5], fs,'stop',1);
        eeg = buttfilt(eeg,[239.5 240.5], fs,'stop',1);

        if fs >= 1000
            eeg = buttfilt(eeg,[299.5 300.5], fs,'stop',1);
            eeg = buttfilt(eeg,[359.5 360.5], fs,'stop',1);
            eeg = buttfilt(eeg,[419.5 420.5], fs,'stop',1);
            eeg = buttfilt(eeg,[479.5 480.5], fs,'stop',1);
        end
    end
elseif strcmp(filterType, 'adaptivefilter')
    % set the number of harmonics
    numHarmonics = floor(fs/2/60) - 1;

     % apply an adaptive filtering algorithm.
    eeg = removePLI_multichan(eeg, fs, numHarmonics, [50,0.01,4], [0.1,2,4], 2, 60);
else 
    disp('no filtering?');
end

% initialize timePoints vector and adjacency matrices
timePoints = [1:numSampsInStep:lenData-numSampsInWin+1; numSampsInWin:numSampsInStep:lenData]';

for iTask=1:numWins
    % filename to be saved temporarily
    fileName = strcat('trev_adjmats_', num2str(iTask));

    % get the window of data to compute adjacency
    tempeeg = eeg(:, timePoints(iTask,1):timePoints(iTask,2));

    %% Perform Least Squares Computations
    % step 2: compute some functional connectivity 
    if strcmp(TYPE_CONNECTIVITY, 'leastsquares')
        fprintf('About to start least squares\n');
        % linear model: Ax = b; A\b -> x
        b = double(tempeeg(:)); % define b as vectorized by stacking columns on top of another
        b = b(numChans+1:end); % only get the time points after the first one

        % - use least square computation
        theta = computeLeastSquares(tempeeg, b, OPTIONS);
        fprintf('Finished least squares');
        theta_adj = reshape(theta, numChans, numChans)';    % reshape fills in columns first, so must transpose
    end

    % display a message for the user
    fprintf([reference, ' Finished: ', num2str(iTask), '\n']);

    % save the file in temporary dir
    save(fullfile(tempDir, fileName), 'theta_adj');
end
