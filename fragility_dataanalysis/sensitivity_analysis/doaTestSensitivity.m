% #########################################################################
% Script for showing DOA for sensitivity analysis on 'missing electrodes'
% outside the EZ
%
% Script Summary: Computes statistic (DOA = Degree of Agreement) indicat-
% ing how well EEZ (from EpiMap) and CEZ (clinical ezone) agree for varying
% amounts of missing electrodes
% 
% 
% Author: Adam Li, NCSL 
% Last Updated: 02.10.17
%   
% #########################################################################
patients = {...,
%     'pt1aw1','pt1aw2', ...
%     'pt1aslp1', 'pt1aslp2', ...
%     'pt2aw1', 'pt2aw2', ...
%     'pt2aslp1', 'pt2aslp2', ...
%     'pt3aslp1', 'pt3aslp2', ...
%     'pt3aw1', ...
    'pt1sz2',...
%     'pt1sz3', 'pt1sz4',...
%     'pt2sz1', 'pt2sz3', 'pt2sz4', ...
%     'pt3sz2', 'pt3sz4', ...
%     'pt6sz3', 'pt6sz4', 'pt6sz5',...
%     'pt8sz1' 'pt8sz2' 'pt8sz3',...
%     'pt10sz1' 'pt10sz2' 'pt10sz3', ...
%     'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
%     'pt14sz1' 'pt14sz2' 'pt14sz3', ...
%      'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
%     'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt17sz1' 'pt17sz2',...
%     'JH101sz1' 'JH101sz2' 'JH101sz3' 'JH101sz4',...
% 	'JH102sz1' 'JH102sz2' 'JH102sz3' 'JH102sz4' 'JH102sz5' 'JH102sz6',...
% 	'JH103sz1' 'JH103sz2' 'JH103sz3',...
% 	'JH104sz1' 'JH104sz2' 'JH104sz3',...
% 	'JH105sz1' 'JH105sz2' 'JH105sz3' 'JH105sz4' 'JH105sz5',...
% 	'JH106sz1' 'JH106sz2' 'JH106sz3' 'JH106sz4' 'JH106sz5' 'JH106sz6',...
% 	'JH107sz1' 'JH107sz2' 'JH107sz3' 'JH107sz4' 'JH107sz5' 
%     'JH107sz6' 'JH107sz7' 'JH107sz8' 'JH107sz9',...
%    'JH108sz1', 'JH108sz2', 'JH108sz3', 'JH108sz4', 'JH108sz5', 'JH108sz6', 'JH108sz7',...
%     'EZT004seiz001', 'EZT004seiz002', ...
%     'EZT006seiz001', 'EZT006seiz002', ...
%     'EZT008seiz001', 'EZT008seiz002', ...
%     'EZT009seiz001', 'EZT009seiz002', ...    
%     'EZT011seiz001', 'EZT011seiz002', ...
%     'EZT013seiz001', 'EZT013seiz002', ...
%     'EZT020seiz001', 'EZT020seiz002', ...
%     'EZT025seiz001', 'EZT025seiz002', ...
%     'EZT026seiz001', 'EZT026seiz002', ...
%     'EZT028seiz001', 'EZT028seiz002', ...
%    'EZT037seiz001', 'EZT037seiz002',...
%    'EZT019seiz001', 'EZT019seiz002',...
%    'EZT005seiz001', 'EZT005seiz002',...
%     'EZT007seiz001', 'EZT007seiz002', ...
%    	'EZT070seiz001', 'EZT070seiz002', ...
};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parameters for Analysis
winSize = 500;
stepSize = 500;
frequency_sampling = 1000;
radius = 1.5;

numElecsToRemove = 1:25;

TYPE_CONNECTIVITY = 'leastsquares';
perturbationType = 'C';
TEST_DESCRIP = 'after_first_removal';
TEST_DESCRIP = [];

% similarity metrics to test
metrics = {'Default', 'jaccard', 'sorensen', 'tversky'};

% threshold on fragility map
thresholds = [0.6, 0.65, 0.7, 0.75, 0.8, 0.85];

% tversky index parameters
alpha = 1;
beta = 1;
args.alpha = alpha;
args.beta = beta;
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

% set the weights dir and params
weightsDir = fullfile(rootDir, '/figures/electrodeWeights/');
% perturbation directory to compute a weight
serverDir = fullfile(rootDir, '/serverdata/'); 

summaryFile = 'summarydoafile.csv';
fid = fopen(summaryFile, 'w');

doa = struct();

%% Analyze each patient
for iPat=1:length(patients)
    tic;
    patient = patients{iPat};
    
%     doa.(patient) = struct([]);
    
    % set patientID and seizureID
    patient_id = patient(1:strfind(patient, 'seiz')-1);
    seizure_id = strcat('_', patient(strfind(patient, 'seiz'):end));
    seeg = 1;
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'sz')-1);
        seizure_id = patient(strfind(patient, 'sz'):end);
        seeg = 0;
    end
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'aslp')-1);
        seizure_id = patient(strfind(patient, 'aslp'):end);
        seeg = 0;
    end
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'aw')-1);
        seizure_id = patient(strfind(patient, 'aw'):end);
        seeg = 0;
    end

    % determine clinical annotations
    [included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
        resection_labels, frequency_sampling, center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);
        
    % directory that computed perturbation structs are saved
    finalDataDir = fullfile(serverDir, strcat(perturbationType, '_perturbations', ...
            '_radius', num2str(radius)), strcat('win', num2str(winSize), '_step', num2str(stepSize), ...
            '_freq', num2str(frequency_sampling)), patient);
        
    finalDataDir = fullfile(serverDir, 'adjmats', patient);
    
    for iElec=1:length(numElecsToRemove)
        dataDir = fullfile(finalDataDir, strcat(patient, '_numelecs', num2str(iElec)));
        
        key = strcat(patient, '_', num2str(iElec));
        % load in the column perturbation
        final_data = load(fullfile(dataDir, strcat(patient, '_Cperturbation_', TYPE_CONNECTIVITY, '_radius', num2str(radius), '.mat')));
        final_data = final_data.perturbation_struct;

        % set data to local variables
        minPerturb_time_chan = final_data.minNormPertMat;
        fragility_rankings = final_data.fragilityMat;
        timePoints = final_data.timePoints;
        info = final_data.info;
        num_channels = size(minPerturb_time_chan,1);
        seizureStart = info.seizure_start;
        seizureEnd = info.seizure_end;
        included_labels = info.all_labels;

        % set the seizure start time window and only analyze up to that point
        seizureMarkStart = seizureStart/winSize;
        if seeg
            seizureMarkStart = (seizureStart-1) / winSize;
        end
        minPerturb_time_chan = minPerturb_time_chan(:, 1:seizureMarkStart);
        fragility_rankings = fragility_rankings(:, 1:seizureMarkStart);
        timePoints = timePoints(1:seizureMarkStart,:);  

        ALL = included_labels;
        CEZ = ezone_labels;

        %% Perform test on all thresholds to test sensitivity to fragility thresholding
        for iThresh=1:length(thresholds)
            threshold = thresholds(iThresh);
            fieldname = strcat('threshold_', num2str(threshold*100));

            if ~isfield(doa, fieldname)
                doa.(fieldname) = struct();
            end

            % threshold the fragility map and rowsum
            thresh_map = fragility_rankings;
            thresh_map(thresh_map < threshold) = 0;
            rowsum = sum(thresh_map, 2);

            % get the electrode indices that pass
            EEZ_indices = find(rowsum > 0);
            [sorted_rowsum, sorted_indices] = sort(rowsum, 'descend');
    %         indices = 1:length(rowsum);
    %         EEZ_indices = indices(EEZ_indices);
            EEZ = included_labels(EEZ_indices);

            %% Perform Analysis on All Metrics of Similarity
            for iMetric=1:length(metrics)
                metric = metrics{iMetric};

                % initialize as a container map
                if ~isfield(doa.(fieldname), metric)
                    doa.(fieldname).(metric) = containers.Map;
                end

                if strcmp(metric, 'tversky')
                    D = DOA(EEZ, CEZ, ALL, metric, args);
                else
                    D = DOA(EEZ, CEZ, ALL, metric);
                end

                % append the results to a container map
                newmap = containers.Map(key, D);
                map = doa.(fieldname).(metric);

                doa.(fieldname).(metric) = [map; newmap];  
            end
        end 
    end
%     toc;
end

%% PLOTTING
FONTSIZE = 20;

metrics = {'Default'};
for iPat=1:length(patients)
    patient = patients{iPat};
    
    figure;
    numSubPlots = ceil(length(numElecsToRemove)/5) * 5;
    for iElec=1:length(numElecsToRemove)
        key = strcat(patient, '_', num2str(iElec));
        
        subplot(5, numSubPlots/5, iElec);

        dataToPlot = containers.Map();
        for iThresh=1:length(thresholds)
            threshold = thresholds(iThresh);
            fieldname = strcat('threshold_', num2str(threshold*100));

            for iMetric=1:length(metrics)
                metric = metrics{iMetric};

                data = doa.(fieldname).(metric);
                val = values(data, {key});
                if ~isKey(dataToPlot, metric)
                    dataToPlot(metric) = [val{1}];
                else
                    dataToPlot(metric) = [dataToPlot(metric) val{1}];
                end
            end
        end

        hold on;
        plotSyms = {'ko', 'b*', 'r-', 'p-'};
        for iMetric=1:length(metrics)
            metric = metrics{iMetric};
            plot(thresholds, dataToPlot(metric), plotSyms{iMetric}); hold on;
        end
        titleStr = strcat(patient, '-', num2str(iElec));
        title([titleStr]);
        
        if iElec > 20
            xlabel('Thresholds');
        end    
        if mod(iElec, 5) == 1 || iElec == 1
            ylabel({'Degree of', 'Agreement'});
        end
        axis tight
        axes = gca;
        axes.FontSize = FONTSIZE;
        xlim([min(thresholds), max(thresholds)]);
        ylim([0.4 0.8]);
    end
end
metrics = {'Default'};
legend(metrics)


figDir = fullfile(rootDir, 'figures/degree of agreement/');
if ~exist(figDir, 'dir')
    mkdir(figDir);
end
toSaveFigFile = fullfile(figDir, strcat(patient, '_allmetrics_sensitivity'));
print(toSaveFigFile, '-dpng', '-r0')