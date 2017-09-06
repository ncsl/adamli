function [doa_scores, outcomes, engel_scores] = computeDoaGroup(patients, winSize, stepSize, filterType, typeTransform, radius)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       ex: computeDoaGroup(patients, 250, 125, 'notchfilter', 'fourier',
%       1.5);
% function: computeDoaGroup
%
%-----------------------------------------------------------------------------------------
%
% Description:  For a group of patients (datasets), compute doa relative to
% row sum of the fragility matrix thresholded at various thresholds.
%
%-----------------------------------------------------------------------------------------
%   
%   Input:  
%   1. patients: A cell of different datasets (e.g. pt1sz1, pt1sz2, pt1sz3)
%   2. winSize: the window size that models were computed on (e.g. 250,
%   500)
%   3. stepSize: the step size that models were computed on (e.g. 250, 500,
%   125)
%   4. filterType: the filtering used (e.g. adaptivefilter, notchfilter)
%   5. typeTransform: the type of transformation used in broadband filter
%   (e.g. fourier, morlet)
%   6. radius: the radius in the perturbation model (e.g. 1.1, 1.25, 1.5,
%   1.75, 2.0)
% 
%   Output: 
%   1. doa_scores: a matrix of datasets X thresholds DOA
%   2. outcomes: a cell array of the outcomes (S, or F)
%   3. engel_scores: a vector of the engel scores ([1:4], or nan)
%                          
%-----------------------------------------------------------------------------------------
% Author: Adam Li
%
% Ver.: 1.0 - Date: 09/05/2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin==0
    patients = {...,
%             'JH103aslp1', 'JH103aw1', ...
%             'JH103sz1' 'JH103sz2' 'JH103sz3',...
%     'JH105aslp1', 'JH105aw1',...
%     'JH105sz1' 'JH105sz2' 'JH105sz3' 'JH105sz4' 'JH105sz5',...
    'UMMC001_sz1', 'UMMC001_sz2', 'UMMC001_sz3', ...
%     'UMMC002_sz1', 'UMMC002_sz2', 'UMMC002_sz3', ...
%     'UMMC003_sz1', 'UMMC003_sz2', 'UMMC003_sz3', ...
%     'UMMC004_sz1', 'UMMC004_sz2', 'UMMC004_sz3', ...
%     'UMMC005_sz1', 'UMMC005_sz2', 'UMMC005_sz3', ...
%     'UMMC006_sz1', 'UMMC006_sz2', 'UMMC006_sz3', ...
%     'UMMC007_sz1', 'UMMC007_sz2','UMMC007_sz3', ...
%     'UMMC008_sz1', 'UMMC008_sz2', 'UMMC008_sz3', ...
%     'UMMC009_sz1', 'UMMC009_sz2', 'UMMC009_sz3', ...
    };
    % data parameters to find correct directory
    radius = 1.5;             % spectral radius of perturbation
    winSize = 250;            % window size in milliseconds
    stepSize = 125; 
    filterType = 'notchfilter';  % adaptive, notch, or no
%     typeConnectivity = 'leastsquares'; 

    % broadband filter parameters
    typeTransform = 'fourier'; % morlet, or fourier
end

close all;

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

%% Set Parameters
% set perturbation type to plot
perturbationTypes = ['C', 'R'];
perturbationType = perturbationTypes(1);

% plotting parameters
FONTSIZE = 20;

% degree of agreement parameters
metric = 'default';
thresholds = [0.3, 0.6, 0.8, 0.9, 0.95, 0.99];

% set figure directory to save plots
figDir = fullfile(rootDir, '/figures', 'degreeOfAgreement', ...
    strcat(filterType), ...
    strcat('perturbation', perturbationType, '_win', num2str(winSize), '_step', num2str(stepSize), '_radius', num2str(radius)));

if ~exist(figDir, 'dir')
    mkdir(figDir);
end

%% Initialization and Code
% results of interest
success_d = []; % to store doa for successful patients
failure_d = []; % to store doa for failed patients
success_pats = {};
failure_pats = {};

outcomes = cell(length(patients), 1);
doa_scores = zeros(length(patients), length(thresholds));   % just to store doa 
engel_scores = zeros(length(patients),1); % store engel scores

% vector to store doa for this patient
pat_d = [];
for iPat=1:length(patients)
    patient = patients{iPat};
        
    % set patientID and seizureID
    [~, patient_id, seizure_id, seeg] = splitPatient(patient);

    [included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
        resection_labels, fs, center, success_or_failure] ...
            = determineClinicalAnnotations(patient_id, seizure_id);

    %- get perturbation directory for this patient
    pertDir = fullfile(dataDir, 'serverdata', 'pertmats', ...
        strcat(filterType), ...
        strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)));

    % notch and updated directory
    spectDir = fullfile(dataDir, strcat('/serverdata/spectral_analysis/'), typeTransform, ...
        strcat(filterType, '_win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)), ...
        patient);

    % extract data
    % load computed results
    try
        final_data = load(fullfile(pertDir, ...
            patient,...
            strcat(patient, '_pertmats', '.mat')));
    catch e
        final_data = load(fullfile(pertDir, ...
            patient, ...
            strcat(patient, '_pertmats_leastsquares_radius', num2str(radius), '.mat')));
    end
    final_data = final_data.perturbation_struct;

    % load meta data
    info = final_data.info;

    % load perturbation data
    pertDataStruct = final_data.(perturbationType);

    %- extract clinical data
%     ezone_labels = info.ezone_labels;
%     earlyspread_labels = info.earlyspread_labels;
%     latespread_labels = info.latespread_labels;
%     resection_labels = info.resection_labels;
    included_labels = info.all_labels;
    seizure_estart_ms = info.seizure_estart_ms;
    seizure_estart_mark = info.seizure_estart_mark;
    seizure_eend_ms = info.seizure_eend_ms;
    seizure_eend_mark = info.seizure_eend_mark;
    num_channels = length(info.all_labels);
    try
        engelscore = info.engelscore;
    catch e
        disp('Engel Score not set yet');
        engelscore = nan;
    end

    %- set global variable for plotting
    seizureStart = seizure_estart_ms;
    seizureEnd = seizure_eend_ms;
    seizureMarkStart = seizure_estart_mark;

     % remove POL from labels
    included_labels = upper(included_labels);
    included_labels = strrep(included_labels, 'POL', '');
    ezone_labels = strrep(ezone_labels, 'POL', '');
    earlyspread_labels = strrep(earlyspread_labels, 'POL', '');
    latespread_labels = strrep(latespread_labels, 'POL', '');
    resection_labels = strrep(resection_labels, 'POL', '');
    
    clinicalIndices = getClinicalIndices(included_labels, ezone_labels,...
                    earlyspread_labels, latespread_labels, resection_labels);

    % min norm perturbation, fragility matrix, minmax fragility matrix
    minNormPertMat = pertDataStruct.minNormPertMat;
    fragilityMat = pertDataStruct.fragilityMat;
    minmaxFragility = min_max_scale(minNormPertMat); % perform min max scaling

    % broadband filter for this patient
    timeWinsToReject = broadbandfilter(patient, typeTransform, winSize, stepSize, filterType, spectDir);

    % OPTIONAL: apply broadband filter and get rid of time windows
    % set time windows to nan
%     fragilityMat(timeWinsToReject) = nan;
%     minmaxFragility(timeWinsToReject) = nan;

%     tempMat = fragilityMat;
%     % OPTIONAL: only analyze the preictal states
%     if seizureMarkStart ~= size(fragilityMat, 2)
%         tempMat = tempMat(:, 1:seizureMarkStart);
%     end
%     fragilityMat = tempMat;

    % set outcome
    if success_or_failure == 1
        outcome = 'success';
    else
        outcome = 'failure';
    end

    % compute degree of agreement for varying thresholds
    doa_buff = doa_thresholds(fragilityMat, minmaxFragility, ezone_labels, included_labels, thresholds, metric);

    %% Store Results and Plot For Patient Result
    % store DOA, outcome, engel scores
    doa_scores(iPat,:) = doa_buff;
    outcomes{iPat} = outcome;
    engel_scores(iPat) = engelscore;

    if iPat==1 
        % plot degree of agreement for this patient
            figure;
            plot(thresholds, doa_buff, 'k-'); hold on; axes = gca; currfig = gcf;
            xlabel('Thresholds'); ylabel(strcat({'DOA using', metric}));
            title(['DOA for ', patient]);
            if strcmp(metric, 'default')
                axes.YLim = [-1, 1]; 
                plot(axes.XLim, [0, 0], 'k--'); 
            elseif strcmp(metric, 'jaccard')
                axes.YLim = [0, 1];
            end
            axes.FontSize = FONTSIZE;

            set(currfig, 'Units', 'inches');

        %     currfig.Position = [1986           1        1535        1121];
            currfig.Position = [17.3438         0   15.9896   11.6771];

            if ~exist(fullfile(figDir, patient_id), 'dir')
                mkdir(fullfile(figDir, patient_id));
            end
            toSaveFigFile = fullfile(figDir, patient_id, strcat(patient_id, 'allictal_line_doavsthreshold'));
%             toSaveFigFile = fullfile(figDir, patient_id, strcat(patient_id, 'ii_line_doavsthreshold'));
%             toSaveFigFile = fullfile(figDir, patient_id, strcat(patient_id, '_line_doavsthreshold'));
            
            print(toSaveFigFile, '-dpng', '-r0')
    end
end % loop through patients

% plot box plot for this one patient depending on threshold
figure;
for i=1:length(thresholds)
    subplot(1, length(thresholds), i);
    hold on; axes = gca; currfig = gcf;
    bh = boxplot(doa_scores(:,i));
    xlabel(patient_id);
    ylabel(strcat('Ictal Degree of Agreement (', metric, ')'));
    titleStr = strcat('Thresh =', {' '}, num2str(thresholds(i)));
    title(titleStr);

    axes.FontSize = FONTSIZE-4;
    if strcmp(metric, 'default')
        axes.YLim = [-1, 1]; 
        plot(axes.XLim, [0, 0], 'k--'); 
    elseif strcmp(metric, 'jaccard')
        axes.YLim = [0, 1];
    end
    currfig.Units = 'inches';
    currfig.PaperPosition = [0    0.6389   20.0000   10.5417];
    currfig.Position = [0    0.6389   20.0000   10.5417];
end
toSaveFigFile = fullfile(figDir, patient_id, strcat(patient_id, 'allictal_grouped_doavsthreshold'));
% toSaveFigFile = fullfile(figDir, patient_id, strcat(patient_id, 'ii_grouped_doavsthreshold'));
% toSaveFigFile = fullfile(figDir, patient_id, strcat(patient_id, '_grouped_doavsthreshold'));

print(toSaveFigFile, '-dpng', '-r0')
end
