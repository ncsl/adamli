function serverComputePerturbations(patient, winSize, stepSize, radius, currentWin)
if nargin==0
    patient = 'pt1sz2';
    currentWin = 3;
    winSize = 500;
    stepSize=500;
    radius = 1.5;
end
FILTERTYPE = 2;

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


%% Parameters for Analysis
TYPE_CONNECTIVITY = 'leastsquares';
TEST_DESCRIP = 'after_first_removal';
TEST_DESCRIP = [];

perturbationTypes = ['C', 'R'];
w_space = linspace(-radius, radius, 51);
sigma = sqrt(radius^2 - w_space.^2); % move to the unit circle 1, for a plethora of different radial frequencies
b = [0; 1];                          % initialize for perturbation computation later

% add to sigma and w to create a whole circle search
w_space = [w_space, w_space];
sigma = [-sigma, sigma];

tempDir = fullfile('./tempData/', 'perturbation', strcat('win', num2str(winSize), ...
    '_step', num2str(stepSize)), patient);
if ~exist(tempDir, 'dir')
    mkdir(tempDir);
end

%% extract adjMat for this patient from temp dir
% set directory to save merged computed data
if FILTERTYPE == 1
    connDir = fullfile(rootDir, 'serverdata/adjmats/notchfilter_adjmats/', strcat('win', num2str(winSize), ...
    '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), patient); % at lab
elseif FILTERTYPE == 2
    connDir = fullfile(rootDir, 'serverdata/adjmats/adaptivefilter_adjmats/', strcat('win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), patient); % at lab
else 
    connDir = fullfile(rootDir, 'serverdata/adjmats/nofilter_adjmats/', strcat('win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), patient); % at lab
end

%- load in adjmat struct    
data = load(fullfile(connDir, patient));
adjmat_struct = data.adjmat_struct;
adjMat = theta_adj;
N = size(adjMat, 1);

% extract info mat file from tempDir
load(fullfile(tempDir, 'infoAdjMat.mat'));
TYPE_CONNECTIVITY = info.type_connectivity;
ezone_labels = info.ezone_labels;
earlyspread_labels = info.earlyspread_labels;
latespread_labels = info.latespread_labels;
resection_labels = info.resection_labels;
labels = info.all_labels;
seizureStart = info.seizure_start;
seizureEnd = info.seizure_end;
winSize = info.winSize;
stepSize = info.stepSize;
timePoints = info.timePoints;
included_channels = info.included_channels;
frequency_sampling = info.frequency_sampling;

%- set meta data struct
info.ezone_labels = ezone_labels;
info.earlyspread_labels = earlyspread_labels;
info.latespread_labels = latespread_labels;
info.resection_labels = resection_labels;
info.all_labels = all_labels;
info.seizure_start = seizure_start;
info.seizure_end = seizure_end;
info.winSize = winSize;
info.stepSize = stepSize;
info.frequency_sampling = frequency_sampling;
info.included_channels = included_channels;

%% 1: Begin Perturbation Analysis
%- initialize matrices for colsum, rowsum, and minimum perturbation\
minPerturb_time_chan = zeros(N,1);
del_table = cell(N,1);

% loop through mat files
tic; % start counter

if max(abs(eig(adjMat))) > radius
    errormsg = ['Max eigenvalue in window ', num2str(currentWin), ' is larger then radius'];
    error('ServerComputePerturbation:illposedproblem', errormsg);
elseif abs(max(abs(eig(adjMat))) - radius) < 1e-8
    errormsg = ['Max eigenvalue in window ', num2str(currentWin), ' is equal to radius'];
    error('ServerComputePerturbation:illposedproblem', errormsg);
end

for iPert=1:length(perturbationTypes)
    perturbationType = perturbationTypes(iPert);
    
    % initialize vectors to store
    minNormPerturbMat = zeros(N,1);
    fragilityMat = zeros(N,1);
    del_table = cell(N,1);
    
    perturb_args = struct();
    perturb_args.perturbationType = perturbationType;
    perturb_args.w_space = w_space;
    perturb_args.radius = radius;
    
    [minNormPert, del_vecs, ERRORS] = minNormPerturbation(patient, adjMat, perturb_args);

    % store results
    minNormPerturbMat = minNormPert;
    del_table = del_vecs;

    %% 3. Compute fragility rankings per column by normalization
    % Compute fragility rankings per column by normalization
    for i=1:N      % loop through each channel
        fragilityMat(i) = (max(minNormPerturbMat(:)) - minNormPerturbMat(i)) ...
                                    / max(minNormPerturbMat(:));
    end

    % initialize struct to save
    perturbation_struct = struct();
    perturbation_struct.del_table = del_table;
    perturbation_struct.minNormPertMat = minNormPerturbMat;
    perturbation_struct.fragilityMat = fragilityMat;

    % display a message for the user
    disp(['Finished: ', num2str(currentWin)]);

    % save the file in temporary dir
    fileName = strcat(patient, '_', perturbationType, '_pert_', num2str(currentWin));
    save(fullfile(tempDir, fileName), 'perturbation_struct');
end
end