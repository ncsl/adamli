clear all
clc
close all
patients = {...,
    {'pt1sz2', 'pt1sz3', 'pt1sz4', 'pt1aw1','pt1aw2', 'pt1aslp1','pt1aslp2'}, ...},...
    {'pt2sz1' 'pt2sz3' , 'pt2sz4', 'pt2aw1', 'pt2aw2', 'pt2aslp1', 'pt2aslp2'}, ...}, ...
    {'pt3sz2' 'pt3sz4', 'pt3aw1', 'pt3aslp1', 'pt3aslp2'}, ...}, ...
    {'pt8sz1' 'pt8sz2' 'pt8sz3'},...
    {'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5'},...
    {'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4'},...
%     {'pt6sz3', 'pt6sz4', 'pt6sz5'},...
%     {'pt7sz19', 'pt7sz21', 'pt7sz22'},...
%     {'pt10sz1','pt10sz2' 'pt10sz3'}, ...
%     {'pt14sz1' 'pt14sz2' 'pt14sz3'}, ...
%     {'LA01_ICTAL', 'LA01_Inter'},...
%     {'LA02_ICTAL', 'LA02_Inter'}, ...
%       'LA09_ICTAL', 
%       'LA09_Inter',...
%     'LA10_ICTAL', ...'LA10_Inter', ...
%     {'LA04_ICTAL','LA04_Inter'}, ...
%     {'LA06_ICTAL', 'LA06_Inter'}, ...
%     {'LA08_ICTAL', 'LA08_Inter'}, ...
%     {'LA11_ICTAL', 'LA11_Inter'}, ...
%     {'LA15_ICTAL', 'LA15_Inter'}, ...
%     {'LA16_ICTAL', 'LA16_Inter'}, ...
};

times = {,...
%       [10, []],...
%       [16, []], ... % LA02
%     [10, []], ... % LA04
%     [10, []], ... % LA06
%     [15, []],... % LA08
%     [20, []], ... % LA11
%     [20, []], ... % LA15
%     [10, []], ... % LA16
%     [10, 10, 10],... % JH103
%     [13, 13, 13, 13, 13], ... % JH105
%     [15, 12, 10, [], [], [], []], ... % pt1
%     [60, 60, 75, [], [], [], []],... % pt2
%     [17, 17, [], [], []],... % pt3
%     [12 12 12],... % pt 8
%     [7 7 7 7],... % pt13
%     [20 30 10 30],... % pt 15
% 	[10, 10 10],... % pt 6
% 	[10 30 10],... % pt 7
% 	[50 50 50],... % pt 10
	[60 55 55],... % pt 14
};
%% Set Root Directories
% data directories to save data into - choose one
eegRootDirHD = '/Volumes/NIL Pass/';
eegRootDirHD = '/Volumes/ADAM LI/';
% eegRootDirHD = '~/Downloads/';
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

%% Parameters
winSize = 250;
stepSize = 125;
filterType = 'notchfilter';
% filterType = 'adaptivefilter';
radius = 1.5;
typeConnectivity = 'leastsquares';
typeTransform = 'fourier';
rejectThreshold = 0.3;
reference = '';
% set which pertrubation model to analyze
perturbationTypes = ['C', 'R'];
perturbationType = perturbationTypes(1);

FONTSIZE = 16;
metric = 'jaccard';

thresholds = [0.5, 0.6, 0.7, 0.8, 0.9, 0.95];

figDir = fullfile(rootDir, '/figures', 'fragilityStats', ...
    strcat(filterType), ...
    strcat('perturbation', perturbationType, '_win', num2str(winSize), '_step', num2str(stepSize), '_radius', num2str(radius)));

if ~exist(figDir, 'dir')
    mkdir(figDir);
end

% to keep track of the doa per patient per threshold
doa_group = zeros(length([patients{:}]), length(thresholds));

% to keep track of all fragile sets of each patient
fragilesets = cell(length([patients{:}]), 1);

% to see what the doa is of combined
combinedoa = zeros(length(patients), 1);

% 
max_doa = zeros(length(patients), 3);
group_ind = 1;



% loop through each separate cell array
for iGroup=1:length(patients)
    close all
    
    group = patients{iGroup};
    
    coded_times = times{iGroup};
    
%     preictal_doa = zeros(length(group), length(thresholds));
%     rowsum_doa = zeros(length(group), length(thresholds));
%     postcfvar_doa = zeros(length(group), length(thresholds));
%     weight50_doa = zeros(length(group), length(thresholds));
%     weight85_doa = zeros(length(group), length(thresholds));
    weightnew_doa = zeros(length(group), length(thresholds));
    
    for iPat=1:length(group)
        patient = group{iPat}

        if contains(lower(patient), 'inter')
            interictal = 1;
        else
            interictal = 0;
        end
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
%         pertDir = fullfile(dataDir, 'pertmats');
        % notch and updated spectral analysis directory
        spectDir = fullfile(dataDir, strcat('/serverdata/spectral_analysis/'), typeTransform, ...
            strcat(filterType, '_win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)), ...
            patient);

        % extract data - load computed results
%         try 
%             tempDir = fullfile('~/Downloads', 'pertmats');
%             
%             final_data = load(fullfile(tempDir, ...
%                 patient,...
%                 strcat(patient, '_pertmats', '.mat')));
%         catch e
%             final_data = load(fullfile(pertDir, ...
%                 patient,...
%                 strcat(patient, '_pertmats', '.mat')));
%         end
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
        included_labels = info.all_labels;
        seizure_estart_ms = info.seizure_estart_ms;
        seizure_estart_mark = info.seizure_estart_mark;
        seizure_eend_ms = info.seizure_eend_ms;
        seizure_eend_mark = info.seizure_eend_mark;
        num_channels = length(info.all_labels);

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
        try
            % broadband filter for this patient
            timeWinsToReject = broadbandfilter(patient, typeTransform, winSize, stepSize, filterType, spectDir);
            rejectThreshold = 0.3;
            timeWinsToReject(timeWinsToReject > rejectThreshold) = 1;
            timeWinsToReject(timeWinsToReject <= rejectThreshold) = 0;

            % OPTIONAL: apply broadband filter and get rid of time windows
            % set time windows to nan
            fragilityMat(logical(timeWinsToReject)) = nan;
        %     minmaxFragility(timeWinsToReject) = nan;
    
        catch e
            disp(e);
        end
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

        % vector of hard coded time windows to go to for each patient
        if ~interictal
            try
                time = coded_times(iPat);
            catch e
                disp('interictal probably... still need to fix this');
            end
            try
                timesz = info.rawtimePoints(seizureMarkStart, 2)/fs;
                post_index = find(info.rawtimePoints(:, 2)/fs == (timesz + time));
            catch e
                timesz = info.timePoints(seizureMarkStart, 2)/fs;
                post_index = find(info.timePoints(:, 2)/fs == (timesz + time));
            end
            seizureMarkStart
            post_index
            if isempty(post_index)
                patient
            end
        end
        
        %% Compute Fragility Statistics and Weighted Metrics
        NORMALIZE = 1;
        epsilon = 0.8;
        if interictal
            % compute on interictal
            [rowsum, excluded_indices, num_high_fragility] = computedoainterictal(fragilityMat, epsilon, NORMALIZE);
        else
            % compute on preictal
            [prerowsum, preexcluded_indices, prenum_high_fragility, precfvar_chan] = computedoaictal(fragilityMat, ...
                              seizureMarkStart - 80 - 80, seizureMarkStart-80, epsilon, NORMALIZE);

            % compute on ictal
            [rowsum, excluded_indices, num_high_fragility, postcfvar_chan] = computedoaictal(fragilityMat, ...
                            seizureMarkStart-80, post_index, epsilon, NORMALIZE);
        end
        % weighted sums
%         weight50_sum = 0.5*rowsum + 0.5*postcfvar_chan;
%         weight85_sum = 0.85*rowsum + 0.15*postcfvar_chan;
%         weight50_sum = weight50_sum ./ max(weight50_sum);
%         weight85_sum = weight85_sum ./ max(weight85_sum);
        if ~interictal
            weightnew_sum = 0.7*rowsum + 0.2*num_high_fragility  + 0.1*postcfvar_chan;
        else
            weightnew_sum = 0.8*rowsum + 0.2*num_high_fragility;
        end
        weightnew_sum = weightnew_sum ./ max(weightnew_sum); 
        %% compute Degree of agreements
%         ezone_labels = resection_labels;
%         rowsum_doa(iPat, :) = compute_doa_threshold(rowsum, ezone_labels, included_labels, thresholds, metric);
%         postcfvar_doa(iPat, :) = compute_doa_threshold(postcfvar_chan, ezone_labels, included_labels, thresholds, metric);
%         weight50_doa(iPat, :) = compute_doa_threshold(weight50_sum, ezone_labels, included_labels, thresholds, metric);
%         weight85_doa(iPat, :) = compute_doa_threshold(weight85_sum, ezone_labels, included_labels, thresholds, metric);
        [weightnew_doa(iPat, :), fragilesets{iPat}] = compute_doa_threshold(weightnew_sum, ezone_labels, included_labels, thresholds, metric);        
    end % loop through patient
    
    doa_group(group_ind:group_ind+iPat-1, :) = weightnew_doa;
    group_ind = group_ind + iPat;
    
    %% line PLOT
%     figure;
%     subplot(231);
%     hold on; axes = gca; currfig = gcf;
%     bh = plot(rowsum_doa, 'k-');
%     xlabel(patient_id);
%     ylabel(strcat('Rowsum Degree of Agreement (', metric, ')'));
% 
%     axes.FontSize = FONTSIZE-4;
%     if strcmp(metric, 'default')
%         axes.YLim = [-1, 1]; 
%         plot(axes.XLim, [0, 0], 'k--'); 
%     elseif strcmp(metric, 'jaccard')
%         axes.YLim = [0, 1];
%     end
%     
%     subplot(232);
%     hold on; axes = gca; currfig = gcf;
%     bh = plot(postcfvar_doa);
%     xlabel(patient_id);
%     ylabel(strcat('Post Coeffvar Degree of Agreement (', metric, ')'));
% 
%     axes.FontSize = FONTSIZE-4;
%     if strcmp(metric, 'default')
%         axes.YLim = [-1, 1]; 
%         plot(axes.XLim, [0, 0], 'k--'); 
%     elseif strcmp(metric, 'jaccard')
%         axes.YLim = [0, 1];
%     end
%     
%     subplot(233);
%     hold on; axes = gca; currfig = gcf;
%     bh = plot(weight50_doa);
%     xlabel(patient_id);
%     ylabel(strcat('50% weight Degree of Agreement (', metric, ')'));
% 
%     axes.FontSize = FONTSIZE-4;
%     if strcmp(metric, 'default')
%         axes.YLim = [-1, 1]; 
%         plot(axes.XLim, [0, 0], 'k--'); 
%     elseif strcmp(metric, 'jaccard')
%         axes.YLim = [0, 1];
%     end
%     
%     subplot(234);
%     hold on; axes = gca; currfig = gcf;
%     bh = plot(weight85_doa);
%     xlabel(patient_id);
%     ylabel(strcat('85% weight Degree of Agreement (', metric, ')'));
% 
%     axes.FontSize = FONTSIZE-4;
%     if strcmp(metric, 'default')
%         axes.YLim = [-1, 1]; 
%         plot(axes.XLim, [0, 0], 'k--'); 
%     elseif strcmp(metric, 'jaccard')
%         axes.YLim = [0, 1];
%     end
%     
%     subplot(235);
%     hold on; axes = gca; currfig = gcf;
%     bh = plot(weightnew_doa);
%     xlabel(patient_id);
%     ylabel(strcat('New weight Degree of Agreement (', metric, ')'));
% 
%     axes.FontSize = FONTSIZE-4;
%     if strcmp(metric, 'default')
%         axes.YLim = [-1, 1]; 
%         plot(axes.XLim, [0, 0], 'k--'); 
%     elseif strcmp(metric, 'jaccard')
%         axes.YLim = [0, 1];
%     end
%     currfig.Units = 'inches';
%     currfig.PaperPosition = [0    0.6389   20.0000   10.5417];
%     currfig.Position = [0    0.6389   20.0000   10.5417];
%     
%     pause(0.05);
%     % 3. save figure
%     toSaveFigFile = fullfile(figDir, strcat(patient, '_doa'));
%     print(toSaveFigFile, '-dpng', '-r0')
    
    %% Combine and Compute Sensitivity
    % compute doa 
    threshindtouse = 3;
    fragile_set = union(fragilesets{2}{end-1}, fragilesets{1}{end-1});
    combinedoa(iGroup) = degreeOfAgreement(fragile_set, ezone_labels, included_labels, metric)
    
%     max_doa{iGroup} = [1];
    if length(ezone_labels) > 1
        doasens_thresh = [0.9, 0.8, 0.7];
%         max_doa = zeros(length(doasens_thresh), 1);
        numez = length(ezone_labels);
        for i=1:length(doasens_thresh)
            toselect = floor(numez*doasens_thresh(i));
            fragile_set = ezone_labels(1:toselect);
            max_doa(iGroup, i) = degreeOfAgreement(fragile_set, ezone_labels, included_labels, metric);
        end
    end
end % loop through groups of patients

colors = {'k', 'b', 'r'};
figure;
subplot(121);
hold on; axes = gca; currfig = gcf;
bh = notBoxPlot(doa_group); hold on;

lines = {};
for i=1:size(max_doa,2)
%     avg = mean(max_doa(:, size(max_doa,2)));
%     std = var(max_doa(:, size(max_doa,2)));
%     lines{i} = shadedErrorBar(axes.XLim, [avg avg], [std std]);
    plot(axes.XLim, [max_doa(i) max_doa(i)], colors{i});
end

% plot combined doa
avgcombine = mean(combinedoa);
stdcombine = var(combinedoa);
% lines{end+1} = shadedErrorBar(axes.XLim, [avgcombine avgcombine], [stdcombine stdcombine], '', 1);
lines{end+1} = plot(axes.XLim, [combinedoa, combinedoa], 'k--');

% bh = boxplot(doa_group, 'Labels', thresholds);
xlabel('Thresholds On Weighted Sum');
ylabel(strcat('Degree of Agreement (', metric, ')'));
title(strcat(outcome, ' for NIH ', patient_id));
legend([lines{:}], {strcat('90% of ', num2str(length(ezone_labels)), ' ez'), '80%', '70%', 'ii+ictal doa'}, 'Location', 'southeast');

axes.FontSize = FONTSIZE-4;
hold on;
if strcmp(metric, 'default')
    axes.YLim = [-1, 1];
    plot(axes.XLim, [0, 0], 'k--');
elseif strcmp(metric, 'jaccard')
    axes.YLim = [0, 1];
end

subplot(122);
% plot(axes.XLim, [avgcombine/avg, avgcombine/avg], 'k');
plot(axes.XLim, [combinedoa/max_doa(end), combinedoa/max_doa(end)], 'k');
hold on; axes = gca; currfig = gcf;
axes.FontSize = FONTSIZE-4;
hold on;
if strcmp(metric, 'default')
    axes.YLim = [-1, 1];
    plot(axes.XLim, [0, 0], 'k--');
elseif strcmp(metric, 'jaccard')
    axes.YLim = [0, 1];
end

currfig.Units = 'inches';
currfig.PaperPosition = [0    0.6389   20.0000   10.5417];
currfig.Position = [0    0.6389   20.0000   10.5417];
pause(0.05);
% 3. save figure
toSaveFigFile = fullfile(figDir, strcat(outcome, ' for NIH ', patient_id, metric));
% toSaveFigFile = fullfile(figDir, strcat(outcome, ' for CC ', metric));
print(toSaveFigFile, '-dpng', '-r0')