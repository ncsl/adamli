patients = {...,
%      'pt1aw1','pt1aw2', ...
%     'pt1aslp1','pt1aslp2', ...
%     'pt2aw1', 'pt2aw2', ...
%     'pt2aslp1', 'pt2aslp2', ...
%     'pt3aw1', ...
%     'pt3aslp1', 'pt3aslp2', ...
%     {'pt1sz2', 'pt1sz3', 'pt1sz4'},...
%     {'pt2sz1' 'pt2sz3' , 'pt2sz4'}, ...
    {'pt3sz2' 'pt3sz4'}, ...
%     {'pt6sz3', 'pt6sz4', 'pt6sz5'},...
%     {'pt7sz19', 'pt7sz21', 'pt7sz22'},...
%     {'pt8sz1' 'pt8sz2' 'pt8sz3'},...
%     {'pt10sz1','pt10sz2' 'pt10sz3'}, ...
%     {'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5'},...
%     {'pt14sz1' 'pt14sz2' 'pt14sz3'}, ...
%     {'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4'},...
%     {'pt16sz1' 'pt16sz2' 'pt16sz3'},...
%     'pt17sz1' 'pt17sz2', 'pt17sz3', ...

%     'Pat2sz1p', 'Pat2sz2p', 'Pat2sz3p', ...
%     'Pat16sz1p', 'Pat16sz2p', 'Pat16sz3p', ...
%     'LA01_ICTAL', 'LA01_Inter', ...
%     'LA02_ICTAL', 'LA02_Inter', ...
%     'LA03_ICTAL', 'LA03_Inter', ...
%     'LA04_ICTAL', 'LA04_Inter', ...
%     'LA05_ICTAL', 'LA05_Inter', ...
%     'LA06_ICTAL', 'LA06_Inter', ...
%     'LA08_ICTAL', 'LA08_Inter', ...
%     'LA09_ICTAL', 'LA09_Inter', ...
%     'LA10_ICTAL', 'LA10_Inter', ...
%     'LA11_ICTAL', 'LA11_Inter', ...
%     'LA15_ICTAL', 'LA15_Inter', ...
%     'LA16_ICTAL', 'LA16_Inter', ...
};

times = {,...
%     [15, 12, 10], ... % pt1
%     [60, 60, 75],... % pt2
    [17, 17],... % pt3
% 	[20, 20 20],... % pt 6
% 	[30 30 65],... % pt 7
% 	[10 10 10],... % pt 8
% 	[150 130 150],... % pt 10
% 	[10 10 10 10],... % pt13
% 	[60 55 55],... % pt 14
% 	[30 40 15 25],...
    }; % pt 15
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

thresholds = [0.5, 0.6, 0.7, 0.8, 0.9, 0.95];

figDir = fullfile(rootDir, '/figures', 'fragilityStats', ...
    strcat(filterType), ...
    strcat('perturbation', perturbationType, '_win', num2str(winSize), '_step', num2str(stepSize), '_radius', num2str(radius)));

if ~exist(figDir, 'dir')
    mkdir(figDir);
end



for iGroup=1:length(patients)
    close all
    
    group = patients{iGroup};
    
    coded_times = times{iGroup};
    
    rowsum_doa = zeros(length(group), length(thresholds));
    postcfvar_doa = zeros(length(group), length(thresholds));
    weight50_doa = zeros(length(group), length(thresholds));
    weight85_doa = zeros(length(group), length(thresholds));
    weightnew_doa = zeros(length(group), length(thresholds));
    
    for iPat=1:length(group)
        patient = group{iPat}

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
        % broadband filter for this patient
        timeWinsToReject = broadbandfilter(patient, typeTransform, winSize, stepSize, filterType, spectDir);
        rejectThreshold = 0.3;
        timeWinsToReject(timeWinsToReject > rejectThreshold) = 1;
        timeWinsToReject(timeWinsToReject <= rejectThreshold) = 0;

        % OPTIONAL: apply broadband filter and get rid of time windows
        % set time windows to nan
        fragilityMat(logical(timeWinsToReject)) = nan;
    %     minmaxFragility(timeWinsToReject) = nan;
    
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
        cfvar_chan = computecoeffvar(fragilityMat);

        % compute coefficient of var for preictal
        precfvar_chan = computecoeffvar(fragilityMat, 1, seizureMarkStart);

        % vector of hard coded time windows to go to for each patient
        time = coded_times(iPat);
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

        % compute coefficient of var for ictal 
        postcfvar_chan = computecoeffvar(fragilityMat, seizureMarkStart, post_index);

        % compute rowsum for ictal 
        high_mask = fragilityMat;
        for ichan=1:num_channels
            indices = high_mask(ichan,:) < 0.85;
            high_mask(ichan,indices) = 0; 
        end
        rowsum = computerowsum(high_mask, seizureMarkStart, post_index);

        % get instances of high fragility
        num_high_fragility = computenumberfragility(fragilityMat, seizureMarkStart, post_index);
        
        % normalize rowsum and coeff var
        num_high_fragility = num_high_fragility ./ max(num_high_fragility);
        rowsum = rowsum ./ max(rowsum);
        postcfvar_chan = postcfvar_chan ./ max(postcfvar_chan);
        
        % weighted sums
        weight50_sum = 0.5*rowsum + 0.5*postcfvar_chan;
        weight85_sum = 0.85*rowsum + 0.15*postcfvar_chan;
        weightnew_sum = 0.7*rowsum + 0.1*postcfvar_chan + 0.2*num_high_fragility;
        
        weight50_sum = weight50_sum ./ max(weight50_sum);
        weight85_sum = weight85_sum ./ max(weight85_sum);
        weightnew_sum = weightnew_sum ./ max(weightnew_sum);

        %% only analyze up to seizuremarkend for all following statistics
%         fragilityMat = fragilityMat(:, 1:seizureMarkEnd);
%         minNormPertMat = minNormPertMat(:, 1:seizureMarkEnd);
% 
%         % compute highest 10% fragile nodes then compute normalized rowsum
%         max_frag = max(fragilityMat,[], 2); % compute highest fragility during entire dataset
%         min_frag = min(fragilityMat,[], 2); % compute smallest fragility during entire dataset
%         high_frag = prctile(fragilityMat, 95, 2);
% 
%         high_mask = fragilityMat;
%         for ichan=1:num_channels
%             indices = high_mask(ichan,:) < high_frag(ichan);
%             high_mask(ichan,indices) = 0; 
%         end
%         
%         % compute row sum of electrodes with only the highest 10% fragility
%         rowsum = nansum(high_mask, 2);
%         
%         % threshold at top 10% and include electrodes
%         [r, ~] = find(fragilityMat > 0.9)
%         ez_90thresh_set = included_labels(unique(r));
%         
%         % threshold at top 5% and include electrodes
%         [r, ~] = find(fragilityMat > 0.95)
%         ez_95thresh_set = included_labels(unique(r));
%         
%         % create feature vector struct
%         features_struct.patient = patient;
%         features_struct.cfvar_time = cfvar_time;
%         features_struct.cfvar_chan = cfvar_chan;
% 
%         features_struct.precfvar_chan = precfvar_chan;
%         features_struct.postcfvar_chan = postcfvar_chan;
%         features_struct.rowsum = rowsum;
%         features_struct.ez_90thresh_set = ez_90thresh_set;
%         features_struct.ez_95thresh_set = ez_95thresh_set;
%         
%         features_struct.ezone_labels = ezone_labels;
%         features_struct.included_labels = included_labels;
% 
%         save(fullfile(figDir, strcat(patient, '_fragilitystats.mat')), 'features_struct');

        %% compute Degree of agreements
        rowsum_doa(iPat, :) = compute_doa_threshold(rowsum, ezone_labels, included_labels, thresholds);
        postcfvar_doa(iPat, :) = compute_doa_threshold(postcfvar_chan, ezone_labels, included_labels, thresholds);
        weight50_doa(iPat, :) = compute_doa_threshold(weight50_sum, ezone_labels, included_labels, thresholds);
        weight85_doa(iPat, :) = compute_doa_threshold(weight85_sum, ezone_labels, included_labels, thresholds);
        weightnew_doa(iPat, :) = compute_doa_threshold(weightnew_sum, ezone_labels, included_labels, thresholds);
    end % loop through patient
    
    metric = 'default';
    FONTSIZE = 16;
    
    figure;
    subplot(231);
    hold on; axes = gca; currfig = gcf;
    bh = boxplot(rowsum_doa, 'Labels', thresholds);
    xlabel(patient_id);
    ylabel(strcat('Rowsum Degree of Agreement (', metric, ')'));

    axes.FontSize = FONTSIZE-4;
    if strcmp(metric, 'default')
        axes.YLim = [-1, 1]; 
        plot(axes.XLim, [0, 0], 'k--'); 
    elseif strcmp(metric, 'jaccard')
        axes.YLim = [0, 1];
    end
    
    subplot(232);
    hold on; axes = gca; currfig = gcf;
    bh = boxplot(postcfvar_doa, 'Labels', thresholds);
    xlabel(patient_id);
    ylabel(strcat('Post Coeffvar Degree of Agreement (', metric, ')'));

    axes.FontSize = FONTSIZE-4;
    if strcmp(metric, 'default')
        axes.YLim = [-1, 1]; 
        plot(axes.XLim, [0, 0], 'k--'); 
    elseif strcmp(metric, 'jaccard')
        axes.YLim = [0, 1];
    end
    
    subplot(233);
    hold on; axes = gca; currfig = gcf;
    bh = boxplot(weight50_doa, 'Labels', thresholds);
    xlabel(patient_id);
    ylabel(strcat('50% weight Degree of Agreement (', metric, ')'));

    axes.FontSize = FONTSIZE-4;
    if strcmp(metric, 'default')
        axes.YLim = [-1, 1]; 
        plot(axes.XLim, [0, 0], 'k--'); 
    elseif strcmp(metric, 'jaccard')
        axes.YLim = [0, 1];
    end
    
    subplot(234);
    hold on; axes = gca; currfig = gcf;
    bh = boxplot(weight85_doa, 'Labels', thresholds);
    xlabel(patient_id);
    ylabel(strcat('85% weight Degree of Agreement (', metric, ')'));

    axes.FontSize = FONTSIZE-4;
    if strcmp(metric, 'default')
        axes.YLim = [-1, 1]; 
        plot(axes.XLim, [0, 0], 'k--'); 
    elseif strcmp(metric, 'jaccard')
        axes.YLim = [0, 1];
    end
    
     subplot(235);
    hold on; axes = gca; currfig = gcf;
    bh = boxplot(weightnew_doa, 'Labels', thresholds);
    xlabel(patient_id);
    ylabel(strcat('New weight Degree of Agreement (', metric, ')'));

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
    
    pause(0.05);
    % 3. save figure
    toSaveFigFile = fullfile(figDir, strcat(patient, '_doa'));
    print(toSaveFigFile, '-dpng', '-r0')
end % loop through groups of patients
