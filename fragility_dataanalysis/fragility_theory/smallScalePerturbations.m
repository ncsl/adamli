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
patient = 'pt17sz1';
patient = 'pt1aw1';
patient = 'pt1aslp1';
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
% FONTSIZE = 16;
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

eeg = eeg(included_channels, :);

P = 20; % size of simulation
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

% get rid of all 'unrealistic' perturbations that are too large
% bad_indices = find(avg_minnorm > 1000000);
% avg_minnorm(bad_indices) = nan;
% var_minnorm(bad_indices) = nan;

%% figure to show along wspace what the min norm was at each point
FONTSIZE = 20;

fig = figure;
shadedErrorBar(1:length(w_space), avg_minnorm, var_minnorm, 'ko');
axes = gca;
axes.Box = 'off';
axes.FontSize = FONTSIZE;
hold on;
plot([26, 26], axes.YLim, 'r-');
plot([76, 76], axes.YLim, 'r-');
title('Distribution of Minimum Norm Perturbation Along Stability Radius', 'FontSize', FONTSIZE);
xlabel('W-space Index');
ylabel('Euclidean Norm of Perturbation');

pause(0.05);
legend('Delta Norms', 'Imaginary part = 0', 'Location', 'southeast');
set(fig, 'Units', 'inches');
fig.Position = [0.0417 0.6667 21.0694 13.0139];

toSaveFigFile = fullfile(figDir, strcat(patient, '_numchans', num2str(P), '_deltadistribution'));
print(toSaveFigFile, '-dpng', '-r0');


%% figure to show the distribution of average min norms
[mindel_overw, min_indices] = min(all_del_sizes);
[maxdel_overw, max_indices] = max(all_del_sizes);

xticklabs = {};
for i=1:length(w_space)
    xstr = strcat(num2str(round(sigma(i), 2)), '+', num2str(round(w_space(i),2)), 'j');
    xticklabs{end+1} = xstr;
end

fig = figure;
indices_to_plot = 60:80;
zero_indices = [26, 76];

subplot(211); % plot over entire instability radius
plot(1:length(w_space), min(all_del_sizes), 'ko');
xlim([1 length(w_space)]);
axes = gca;
axes.FontSize = FONTSIZE;
xticklocs = axes.XTick;
axes.XTickLabel = xticklabs(xticklocs);
axes.Box = 'off';
hold on;
plot([26, 26], axes.YLim, 'r-');
plot([76, 76], axes.YLim, 'r-');
plot([indices_to_plot(1), indices_to_plot(1)], axes.YLim, 'g--');
plot([indices_to_plot(end) indices_to_plot(end)], axes.YLim, 'g--');
title('Minimum Norm At Each Point Along Stability Radius', 'FontSize', FONTSIZE);
ylab1 = ylabel('Minimum Norm');
ylab1.Position = ylab1.Position + [-3, 0 , 0];

subplot(212); % plot over area around w = 0
plot(indices_to_plot, mindel_overw(indices_to_plot), 'ko');
axes = gca;
axes.FontSize = FONTSIZE;
axes.XTickLabel = xticklabs(indices_to_plot);
axes.Box = 'off';
hold on;
plot([76, 76], axes.YLim, 'r-');
title('Minimum Norm At Each Point Along Stability Radius', 'FontSize', FONTSIZE);
ylab2 = ylabel('Minimum Norm');
% ylab2.Position = ylab2.Position + [-3, 0 , 0];

pause(0.05);
legend('Delta Norms', 'Imaginary part = 0', 'Location', 'southeast');
set(fig, 'Units', 'inches');
% fig_heatmap.Position = [17.3438         0   15.9896   11.6771];
fig.Position = [0.0417 0.6667 21.0694 13.0139];

toSaveFigFile = fullfile(figDir, strcat(patient, '_numchans', num2str(P), '_realdata_randomtime'));
print(toSaveFigFile, '-dpng', '-r0');

%% Figure of Eigenspectrum of A matrix at minimum/maximum minperturbation
% add subplot of histogram of time of simulation that this occurred
% subplot(311);
% hist(min_indices);

fig = figure;
subplot(221);
min_index_forA = ceil(min_indices(zero_indices(2)) / 3);
min_adjmat = squeeze(all_adjmats(min_index_forA, :, :));
imagesc(min_adjmat); colorbar(); colormap('jet');
ax = gca;
hold on; axis tight;
set(ax, 'box', 'off'); set(ax, 'YDir', 'normal');

subplot(223);
plot(real(eig(min_adjmat)), imag(eig(min_adjmat)), 'b*', 'MarkerSize', 5); hold on;
axes = gca;
xlabelStr = 'Real Part';
ylabelStr = 'Imag Part';
titleStr = ['Eigenspectrum of ', perturbationType, ' Perturbation'];
labelBasicAxes(axes, titleStr, ylabelStr, xlabelStr, FONTSIZE);
% xlim([-radius radius]);
% ylim([-radius radius]);
% plot(get(axes, 'XLim'), [0 0], 'k');
% plot([0 0], get(axes, 'YLim'), 'k');
% th = 0:pi/50:2*pi;
% r = 1; x = 0; y = 0;
% xunit = r * cos(th) + x;
% yunit = r * sin(th) + y;
% h = plot(xunit, yunit);

subplot(222);
max_index_forA = ceil(max_indices(zero_indices(2)) / 3);
max_adjmat = squeeze(all_adjmats(max_index_forA, :, :));
imagesc(max_adjmat); colorbar(); colormap('jet');
ax = gca;
hold on; axis tight;
set(ax, 'box', 'off'); set(ax, 'YDir', 'normal');

subplot(224);
plot(real(eig(max_adjmat)), imag(eig(max_adjmat)), 'b*', 'MarkerSize', 5); hold on;
axes = gca;
xlabelStr = 'Real Part';
ylabelStr = 'Imag Part';
titleStr = ['Eigenspectrum of ', perturbationType, ' Perturbation'];
labelBasicAxes(axes, titleStr, ylabelStr, xlabelStr, FONTSIZE);


