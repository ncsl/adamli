close all;

%% INITIALIZATION
% data directories to save data into - choose one
eegRootDirHD = '/Volumes/ADAM LI/';
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                 % at ICM server 
eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';   % at home macbook
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';    % at JHU workstation
% eegRootDirMarcc = '/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/'; % at MARCC server
eegRootDirMarcc = '/scratch/groups/ssarma2/adamli/fragility_dataanalysis/';
% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
elseif ~isempty(dir(eegRootDirMarcc)), rootDir = eegRootDirMarcc;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

if     ~isempty(dir(eegRootDirServer)), dataDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHD)), dataDir = eegRootDirHD;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

addpath(genpath(fullfile(rootDir, '/fragility_library/')));
addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
addpath(rootDir);

%% Clinical Annotations
center = 'nih';
patient = 'pt7sz19';
center='cc';
patient = 'EZT019seiz001';
center = 'nih';
patient = 'pt1sz2';

% set patientID and seizureID
[~, patient_id, seizure_id, seeg] = splitPatient(patient);

%- Edit this file if new patients are added.
[included_channels, ezone_labels, earlyspread_labels,...
    latespread_labels, resection_labels, fs, ...
    center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);

dataDir = fullfile(dataDir, 'data', center);

% plotting options
FONTSIZE = 16;
figDir = fullfile(rootDir, 'fragility_theory', 'figures');
if ~exist(figDir, 'dir')
    mkdir(figDir);
end

% mvar model parameters
winSize = 250;
stepSize = 125;
l2regularization = 0;
OPTIONS.l2regularization = l2regularization;

% set perturbation parameters
perturbationTypes = ['C', 'R'];
perturbationType = perturbationTypes(1);
radius = 1.25;

w_space = linspace(-radius, radius, 51);
sigma = sqrt(radius^2 - w_space.^2); % move to the unit circle 1, for a plethora of different radial frequencies
% add to sigma and w to create a whole circle search
w_space = [w_space, w_space(2:end-1)];
sigma = [-sigma, sigma(2:end-1)];
b = [0; -1];                          % initialize for perturbation computation later

perturb_args = struct();
perturb_args.perturbationType = perturbationType;
perturb_args.w_space = w_space;
perturb_args.radius = radius;
perturb_args.sigma = sigma;


%% create small perturbation simulation from real data
%% Read in EEG Raw Data
if seeg
    patient_eeg_path = fullfile(dataDir, patient);
%     patient = strcat(patient_id, seizure_id); % for EZT pats
else
    patient_eeg_path = fullfile(dataDir, patient);
end

fprintf('Loading data...');
% READ EEG FILE Mat File
% files to process
data = load(fullfile(patient_eeg_path, strcat(patient, '.mat')));
eeg = data.data;
labels = data.elec_labels;
engelscore = data.engelscore;
frequency_sampling = data.fs;
outcome = data.outcome;
seizure_eonset_ms = data.seizure_eonset_ms;
seizure_eoffset_ms = data.seizure_eoffset_ms;
seizure_conset_ms = data.seizure_conset_ms;
seizure_coffset_ms = data.seizure_coffset_ms;
fprintf('Loaded data...');
clear data

%- initialize the number of samples in the window / step (ms) 
numSampsInWin = winSize * frequency_sampling / 1000;
numSampsInStep = stepSize * frequency_sampling / 1000;
numWins = floor(size(eeg, 2) / numSampsInStep - numSampsInWin/numSampsInStep + 1);


P = 3; % size of simulation
numSims = 200;
all_del_sizes = zeros(numSims, P, length(w_space));
for iSim=1:numSims
    randIndices = randsample(size(eeg,1), P);
    randTime = randsample(seizure_eonset_ms-winSize, 1);
    
    % get the window of data to compute adjacency
    tempeeg = eeg(randIndices, randTime:randTime+winSize-1);

    [numChans, numSamps] = size(tempeeg);
    
    % Perform Least Squares Computations
    fprintf('About to start least squares\n');
    % linear model: Ax = b; A\b -> x
    b = double(tempeeg(:)); % define b as vectorized by stacking columns on top of another
    b = b(numChans+1:end); % only get the time points after the first one

    % - use least square computation
    theta = computeLeastSquares(tempeeg, b, OPTIONS);
    fprintf('Finished least squares');
    adjMat = reshape(theta, numChans, numChans)';    % reshape fills in columns first, so must transpose
    
    % perform minimum norm perturbation
    [minPerturbation, del_table, del_freqs, del_size] = minNormPerturbation(adjMat, perturb_args);%, clinicalLabels)
    
    all_del_sizes(iSim,:,:) = del_size;
end

for i=1:numSims
    for j=1:N
        testindex = find(all_del_sizes(i,j,:) == min(all_del_sizes(i,j,:)));
        if testindex ~= 152 && testindex ~= 51
            disp(['Wrong at ', num2str(i), ' ', num2str(j)]);
        end
    end
end

colors = {'k', 'b', 'r'};

temp = squeeze(mean(all_del_sizes, 1));
tempstd = squeeze(std(all_del_sizes, 0, 1));
% figure;
for i=1:numChans
    figure;
    %     shadedErrorBar(1:length(w_space), temp(i,:), tempstd(i,:));
    plot(1:length(w_space), temp(i,:), 'Color', colors{i}); hold on;
    plot(1:length(w_space), squeeze(min(all_del_sizes(:,i,:))), 'LineStyle', ':', 'Color', colors{i});
%     plot(1:length(w_space), squeeze(max(all_del_sizes(:,i,:))), 'LineStyle', '--', 'Color', colors{i});
    ax = gca;
    ax.FontSize = FONTSIZE;
    xlabel('Along W Space');
    ylabel('Delta Norms');
    title(['Delta Norms over W Space']);
    legend('Average Norms', 'Min Norms', 'Max Norms');
    
    currfig = gcf;
    set(currfig, 'Units', 'inches');
    currfig.Position = [17.3438         0   15.9896   11.6771];
    
    toSaveFigFile = fullfile(figDir, strcat(patient, '_chanindex', num2str(i), '_realdata_randomtime'));
    print(toSaveFigFile, '-dpng', '-r0');
    
    close all
end

disp('done')