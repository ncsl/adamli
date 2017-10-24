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
all_del_sizes = zeros(numSims*P, length(w_space)); % store all min del vectors for all wspace
all_adjmats = zeros(numSims, P, P);                 % store all adjmats used
% all_del_freqs = cell(numSims, P);
all_del_freqs = cell(numSims, 1);
fprintf('Starting simulation for loop\n');
for iSim=1:numSims
    randIndices = randsample(size(eeg,1), P);
    randTime = randsample(seizure_eonset_ms-winSize, 1);
    
    % get the window of data to compute adjacency
    tempeeg = eeg(randIndices, randTime:randTime+winSize-1);
    
    numChans = size(tempeeg, 1);
    
    % Perform Least Squares Computations
    % linear model: Ax = b; A\b -> x
    b = double(tempeeg(:)); % define b as vectorized by stacking columns on top of another
    b = b(numChans+1:end); % only get the time points after the first one

    % - use least square computation
    theta = computeLeastSquares(tempeeg, b, OPTIONS);
    adjMat = reshape(theta, numChans, numChans)';    % reshape fills in columns first, so must transpose
    
    % perform minimum norm perturbation
    [minPerturbation, del_table, del_freqs, del_size] = minNormPerturbation(adjMat, perturb_args);%, clinicalLabels)
    
    i = iSim-1;
    all_del_sizes(P*i+1:P*(i+1),:) = del_size;
    all_del_freqs{iSim} = del_freqs;
    all_adjmats(iSim, :, :) = adjMat;
end
fprintf('Finished simulation for loop\n');

% get A matrix when the minimum is not at w=0; if possible
list_allfreqs = [all_del_freqs{:}];
% indices = find([all_del_freqs{:}] ~= radius);

% get vector when minimum is not at w=0
% minvec = del_table(indices);

% create variables for plotting
% avg_minnorm = nanmean(reshape(all_del_sizes, numSims*P, length(w_space)), 1);
% var_minnorm = nanvar(reshape(all_del_sizes, numSims*P, length(w_space)), [], 1);
avg_minnorm = nanmean(all_del_sizes, 1);
var_minnorm = nanvar(all_del_sizes, [], 1);

%% figure to show along wspace waht the min norm was at each point
figure;
shadedErrorBar(1:length(w_space), avg_minnorm, var_minnorm, 'ko');
axes = gca;
title('Distribution of Minimum Norm Perturbation Along Stability Radius');
xlabel('W-space Index');
ylabel('Euclidean Norm of Perturbation');

%% figure to show the distribution of average min norms
mindel_overw = min(all_del_sizes);

xticklabs = {};
for i=1:length(w_space)
    xstr = strcat(num2str(sigma(i)), '+', num2str(w_space(i)), 'j');
    xticklabs{end+1} = xstr;
end

figure;
subplot(211); % plot over entire instability radius
plot(1:length(w_space), min(all_del_sizes), 'ko');
xlim([1 length(w_space)]);
axes = gca;
xticklocs = axes.XTick;
axes.XTickLabel = xticklabs(xticklocs);
hold on;
plot([26, 26], axes.YLim, 'r-');
plot([76, 76], axes.YLim, 'r-');
title('Minimum Norm At Each Point Along Stability Radius');
ylabel('Minimum Norm');

subplot(212); % plot over area around w = 0
indices_to_plot = 60:80;
plot(indices_to_plot, mindel_overw(indices_to_plot), 'ko');
axes = gca;
% axes.XTickLabel = xticklabs(indices_to_plot);
hold on;
title('Minimum Norm At Each Point Along Stability Radius');
ylabel('Minimum Norm');


% colors = {'k', 'b', 'r'};
% 
% temp = squeeze(mean(all_del_sizes, 1));
% tempstd = squeeze(std(all_del_sizes, 0, 1));
% % figure;
% for i=1:numChans
%     figure;
%     %     shadedErrorBar(1:length(w_space), temp(i,:), tempstd(i,:));
%     plot(1:length(w_space), temp(i,:), 'Color', colors{i}); hold on;
%     plot(1:length(w_space), squeeze(min(all_del_sizes(:,i,:))), 'LineStyle', ':', 'Color', colors{i});
% %     plot(1:length(w_space), squeeze(max(all_del_sizes(:,i,:))), 'LineStyle', '--', 'Color', colors{i});
%     ax = gca;
%     ax.FontSize = FONTSIZE;
%     xlabel('Along W Space');
%     ylabel('Delta Norms');
%     title(['Delta Norms over W Space']);
%     legend('Average Norms', 'Min Norms', 'Max Norms');
%     
%     currfig = gcf;
%     set(currfig, 'Units', 'inches');
%     currfig.Position = [17.3438         0   15.9896   11.6771];
%     
%     toSaveFigFile = fullfile(figDir, strcat(patient, '_chanindex', num2str(i), '_realdata_randomtime'));
%     print(toSaveFigFile, '-dpng', '-r0');
%     
%     close all
% end
% 
% disp('done')