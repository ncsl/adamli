% if nargin==0
    patients = {...,
%             'JH103aslp1', 'JH103aw1', ...
%             'JH103sz1' 'JH103sz2' 'JH103sz3',...
%     'JH105aslp1', 'JH105aw1',...
%     'JH105sz1' 'JH105sz2' 'JH105sz3' 'JH105sz4' 'JH105sz5',...
%     'UMMC001_sz1', 'UMMC001_sz2', 'UMMC001_sz3', ...
%     'UMMC002_sz1', 'UMMC002_sz2', 'UMMC002_sz3', ...
%     'UMMC003_sz1', 'UMMC003_sz2', 'UMMC003_sz3', ...
%     'UMMC004_sz1', 'UMMC004_sz2', 'UMMC004_sz3', ...
%     'UMMC005_sz1', 'UMMC005_sz2', 'UMMC005_sz3', ...
%     'UMMC006_sz1', 'UMMC006_sz2', 'UMMC006_sz3', ...
%     'UMMC007_sz1', 'UMMC007_sz2','UMMC007_sz3', ...
%     'UMMC008_sz1', 'UMMC008_sz2', 'UMMC008_sz3', ...
%     'UMMC009_sz1', 'UMMC009_sz2', 'UMMC009_sz3', ...
%      'pt1aw1', 'pt1aw2', ...
%     'pt1aslp1', 'pt1aslp2', ...
%     'pt2aw1', 'pt2aw2', ...
%     'pt2aslp1', 'pt2aslp2', ...
%     'pt3aw1', ...
%     'pt3aslp1', 'pt3aslp2', ...
%     'pt1sz2', 'pt1sz3', 'pt1sz4',...
%     'pt2sz1' 'pt2sz3' 'pt2sz4', ...
%     'pt3sz2' 'pt3sz4', ...
%     'pt6sz3', 'pt6sz4', 'pt6sz5', ...
%     'pt8sz1' 'pt8sz2','pt8sz3',...
%     'pt10sz1', 'pt10sz2' 'pt10sz3', ...
%     'pt7sz19', 'pt7sz21', 'pt7sz22',...
%     'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5',...
%     'pt14sz1' 'pt14sz2' 'pt14sz3',...
%     'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
%     'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt1sz4',...
%     'pt6sz3', 'pt6sz4', 'pt6sz5', ...
%     'pt8sz1' 'pt8sz2','pt8sz3',...
%     'pt7sz21', 'pt13sz5',...
%     'pt14sz1' 'pt14sz2' 'pt14sz3',...
%     'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
%     'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt11sz1', 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
%     'pt12sz1', 'pt12sz2', ...
%     'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5',...
%     'pt14sz1' 'pt14sz2' 'pt14sz3',...
%     'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
%     'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt17sz1' 'pt17sz2','pt17sz3'...
        'Pat2sz1p', 'Pat2sz2p', 'Pat2sz3p', ...
        'Pat16sz1p', 'Pat16sz2p', 'Pat16sz3p', ...
    };

times = [15, 20, 10]; % pt1
times = [60, 60, 75]; % pt2
times = [30, 20]; % pt3
times = [20, 20 20]; % pt 6
times = [30 30 65]; % pt 7
% times = [10 10 10]; % pt 8
% times = [150 130 150]; % pt 10
% times = [10 10 10 10]; % pt13
% times = [60 55 55]; % pt 14
% times = [30 40 15 25]; % pt 15


% set which pertrubation model to analyze
perturbationTypes = ['C', 'R'];
perturbationType = perturbationTypes(1);

% end

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
% parameters
winSize = 250;
stepSize = 125;
filterType = 'notchfilter';
% filterType = 'adaptivefilter';
radius = 1.5;
typeConnectivity = 'leastsquares';
typeTransform = 'fourier';
rejectThreshold = 0.3;
reference = '';

% plotting parameters
FONTSIZE = 20;

% set figure directory to save plots
figDir = fullfile(rootDir, '/figures', 'fragilityStats', ...
    strcat(filterType), ...
    strcat('perturbation', perturbationType, '_win', num2str(winSize), '_step', num2str(stepSize), '_radius', num2str(radius)));

if ~exist(figDir, 'dir')
    mkdir(figDir);
end

for iPat=1:length(patients)
    patient = patients{iPat}

    %% 1. Extract Data
    % set patientID and seizureID and extract relevant clinical meta data
    [~, patient_id, seizure_id, seeg] = splitPatient(patient);
    [included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
        resection_labels, fs, center, success_or_failure] ...
            = determineClinicalAnnotations(patient_id, seizure_id);

    % perturbation directory for this patient
    pertDir = fullfile(dataDir, 'serverdata', 'pertmats', ...
        strcat(filterType), ...
        strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)));

    % notch and updated spectral analysis directory
    spectDir = fullfile(dataDir, strcat('/serverdata/spectral_analysis/'), typeTransform, ...
        strcat(filterType, '_win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)), ...
        patient);

    % extract data - load computed results
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
    seizureMarkEnd = seizure_eend_mark;
    
    % remove POL from labels & get clinical indices
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

    %% 2. Perform any Preprocessing
    % broadband filter for this patient
    timeWinsToReject = broadbandfilter(patient, typeTransform, winSize, stepSize, filterType, spectDir);
    rejectThreshold = 0.3;
    timeWinsToReject(timeWinsToReject > rejectThreshold) = 1;
    timeWinsToReject(timeWinsToReject <= rejectThreshold) = 0;
    
    % OPTIONAL: apply broadband filter and get rid of time windows
    % set time windows to nan
    fragilityMat(logical(timeWinsToReject)) = nan;
%     minmaxFragility(timeWinsToReject) = nan;

    % OPTIONAL: only analyze the preictal states
%     tempMat = fragilityMat;
%     if seizureMarkStart ~= size(fragilityMat, 2)
%         tempMat = tempMat(:, 1:seizureMarkStart);
%     end
%     fragilityMat = tempMat;

    % only analyze fragility until ictal off
%     fragilityMat = fragilityMat(:, 1:seizureMarkEnd);
%     minNormPertMat = minNormPertMat(:, 1:seizureMarkEnd);

    % set outcome
    if success_or_failure == 1
        outcome = 'success';
    else
        outcome = 'failure';
    end
    
    % Get Indices for All Clinical Annotations on electrodes
    ezone_indices = findElectrodeIndices(ezone_labels, included_labels);
    earlyspread_indices = findElectrodeIndices(earlyspread_labels, included_labels);
    latespread_indices = findElectrodeIndices(latespread_labels, included_labels);
    resection_indices = findElectrodeIndices(resection_labels, included_labels);
    all_indices = 1:length(included_labels);
    
    %% 3. Compute Statistics of Fragility Model
    features_struct = struct();
    
    % compute mean, variance and coefficient of variation for each time
    avg = nanmean(fragilityMat, 1);
    vari = nanvar(fragilityMat, 0, 1);
    cfvar_time = avg ./ vari;
    
    % compute mean, variance and coefficient of variation for each chan
    avg = nanmean(fragilityMat, 2);
    vari = nanvar(fragilityMat, 0, 2);
    cfvar_chan = avg ./ vari;
    
    % compute coefficient of var for preictal
    preavg = nanmean(fragilityMat(:, 1:seizureMarkStart), 2);
    prevari = nanvar(fragilityMat(:, 1:seizureMarkStart), 0, 2);
    precfvar_chan = preavg ./ prevari;
    
    % vector of hard coded time windows to go to for each patient
%     time = times(iPat);
%     try
%         timesz = info.rawtimePoints(seizureMarkStart, 2)/fs;
%         post_index = find(info.rawtimePoints(:, 2)/fs == timesz + time);
%     catch e
%         timesz = info.timePoints(seizureMarkStart, 2)/fs;
%         post_index = find(info.timePoints(:, 2)/fs == timesz + time);
%     end
%     seizureMarkStart
%     post_index
%     if isempty(post_index)
%         patient
%     end
    
    % compute coefficient of var for ictal 
    try
        timesz = info.rawtimePoints(seizureMarkStart, 2)/fs;
        post_index = find(info.rawtimePoints(:, 2)/fs == timesz + 10);
    catch e
        timesz = info.timePoints(seizureMarkStart, 2)/fs;
        post_index = find(info.timePoints(:, 2)/fs == timesz + 10);
    end
    seizureMarkStart
    post_index
    if isempty(post_index)
        patient
    end

    postcfvar_chan = computecoeffvar(fragilityMat, seizureMarkStart, post_index);
    
    % compute coefficient of var for ictal + 20 seconds
    try
        timesz = info.rawtimePoints(seizureMarkStart, 2)/fs;
        post_index = find(info.rawtimePoints(:, 2)/fs == timesz + 20);
    catch e
        timesz = info.timePoints(seizureMarkStart, 2)/fs;
        post_index = find(info.timePoints(:, 2)/fs == timesz + 20);
    end
    post20cfvar_chan = computecoeffvar(fragilityMat, seizureMarkStart, post_index);
    
    % compute coefficient of var for ictal + 30 seconds
    try
        timesz = info.rawtimePoints(seizureMarkStart, 2)/fs;
        post_index = find(info.rawtimePoints(:, 2)/fs == timesz + 30);
    catch e
        timesz = info.timePoints(seizureMarkStart, 2)/fs;
        post_index = find(info.timePoints(:, 2)/fs == timesz + 30);
    end
    post30cfvar_chan = computecoeffvar(fragilityMat, seizureMarkStart, post_index);
    
    % compute coefficient of var for ictal + 40 seconds
    try
        timesz = info.rawtimePoints(seizureMarkStart, 2)/fs;
        post_index = find(info.rawtimePoints(:, 2)/fs == timesz + 40);
    catch e
        timesz = info.timePoints(seizureMarkStart, 2)/fs;
        post_index = find(info.timePoints(:, 2)/fs == timesz + 40);
    end
    post40cfvar_chan = computecoeffvar(fragilityMat, seizureMarkStart, post_index);
    
    % compute coefficient of var for ictal + 50 seconds
    try
        timesz = info.rawtimePoints(seizureMarkStart, 2)/fs;
        post_index = find(info.rawtimePoints(:, 2)/fs == timesz + 50);
    catch e
        timesz = info.timePoints(seizureMarkStart, 2)/fs;
        post_index = find(info.timePoints(:, 2)/fs == timesz + 50);
    end
    post50cfvar_chan = computecoeffvar(fragilityMat, seizureMarkStart, post_index);
    
    % only analyze up to seizuremarkend for all following statistics
    fragilityMat = fragilityMat(:, 1:seizureMarkEnd);
    minNormPertMat = minNormPertMat(:, 1:seizureMarkEnd);
    
    % compute highest 10% fragile nodes
    max_frag = max(fragilityMat,[], 2); % compute highest fragility during entire dataset
    min_frag = min(fragilityMat,[], 2); % compute smallest fragility during entire dataset
    high_frag = prctile(fragilityMat, 90, 2);
    
    % set highest fragility sum
    fragility_sum = nansum(fragilityMat(:));
    
    % compute fragility assymmetry based on EZ electrodes
    ez_fragility_set = fragilityMat(ezone_indices, :);
    outez_fragility_set = fragilityMat(setdiff(all_indices, ezone_indices),:);
    ez_asymmetry = (sum(ez_fragility_set(:)) - sum(outez_fragility_set(:))) / ...
                        (sum(ez_fragility_set(:)) + sum(outez_fragility_set(:))) / fragility_sum;
    
    % compute fragility asymmetry based on resected electrodes                
    resected_fragility_set = fragilityMat(resection_indices, :);
    outresect_fragility_set = fragilityMat(setdiff(all_indices, resection_indices),:);
    resected_asymmetry = (sum(resected_fragility_set(:)) - sum(outez_fragility_set(:))) / ...
                        (sum(resected_fragility_set(:)) + sum(outez_fragility_set(:))) / fragility_sum;
    
    % compute a shuffled asymmetry based on randomized 'selected' EZ
    % electrodes
%     numShuffles = 1000;
%     shuffle_pdf_ez = zeros(numShuffles, 1);
%     for i=1:numShuffles
%         shuffle_ez_indices = randsample(length(all_indices), length(ezone_indices));
%         shuffle_ez_frag = fragilityMat(shuffle_ez_indices, :);
%         shuffle_outez_frag = fragilityMat(setdiff(all_indices, shuffle_ez_indices), :);
%         shuffle_pdf_ez(i) = (sum(shuffle_ez_frag(:)) - sum(shuffle_outez_frag(:))) / ...
%                         (sum(shuffle_ez_frag(:)) + sum(shuffle_outez_frag(:))) / fragility_sum;
%     end
%     
%     shuffle_pdf_resect = zeros(numShuffles, 1);
%     for i=1:numShuffles
%         shuffle_resect_indices = randsample(length(all_indices), length(resection_indices));
%         shuffle_resect_frag = fragilityMat(shuffle_resect_indices, :);
%         shuffle_outresect_frag = fragilityMat(setdiff(all_indices, shuffle_resect_indices), :);
%         shuffle_pdf_resect(i) = (sum(shuffle_resect_frag(:)) - sum(shuffle_outresect_frag(:))) / ...
%                         (sum(shuffle_resect_frag(:)) + sum(shuffle_outresect_frag(:))) / fragility_sum;
%     end
%     figure;
%     hist(shuffle_pdf_ez);
%     axes = gca;
%     hold on; plot([ez_asymmetry ez_asymmetry], axes.YLim, 'k-')
%     
%     hist(shuffle_pdf_resect); hold on;
%     axes = gca;
%     plot([resected_asymmetry resected_asymmetry], axes.YLim, 'k-')                
    
    % compute how fragile the network is over time
    network_fragility = sum(minNormPertMat, 1);
    
    % create feature vector struct
    features_struct.patient = patient;
    features_struct.cfvar_time = cfvar_time;
    features_struct.cfvar_chan = cfvar_chan;
    
    features_struct.precfvar_chan = precfvar_chan;
    features_struct.postcfvar_chan = postcfvar_chan;
    features_struct.post20cfvar_chan = post20cfvar_chan;
    features_struct.post30cfvar_chan = post30cfvar_chan;
    features_struct.post40cfvar_chan = post40cfvar_chan;
    features_struct.post50cfvar_chan = post50cfvar_chan;
        
    features_struct.ezone_labels = ezone_labels;
    features_struct.included_labels = included_labels;
    features_struct.max_frag = max_frag;
    features_struct.min_frag = min_frag;
    features_struct.high_frag = high_frag;
    features_struct.ez_asymmetry = ez_asymmetry;
    features_struct.resected_asymmetry = resected_asymmetry;
    features_struct.network_fragility = network_fragility;
    
    save(fullfile(figDir, strcat(patient, '_fragilitystats.mat')), 'features_struct');
end