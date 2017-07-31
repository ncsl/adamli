% patients = {...,
%      'pt1aw1','pt1aw2', ...
% %     'pt2aw2', 'pt2aslp2',...
% %     'pt1aslp1','pt1aslp2', ...
% %     'pt2aw1', 'pt2aw2', ...
% %     'pt2aslp1', 'pt2aslp2', ...
% %     'pt3aw1', ...
% %     'pt3aslp1', 'pt3aslp2', ...
% %     'pt1sz2', 'pt1sz3', 'pt1sz4',...
% %     'pt2sz1' 'pt2sz3' , 'pt2sz4', ...
% %     'pt3sz2' 'pt3sz4', ...
% %     'pt6sz3', 'pt6sz4', 'pt6sz5',...
% %     'pt7sz19', 'pt7sz21', 'pt7sz22',...
% %     'pt8sz1' 'pt8sz2' 'pt8sz3',...
% %     'pt10sz1','pt10sz2' 'pt10sz3', ...
% %     'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
% %     'pt12sz1', 'pt12sz2', ...
% %     'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5',...
% %     'pt14sz1' 'pt14sz2' 'pt14sz3'  'pt16sz1' 'pt16sz2' 'pt16sz3',...
% %     'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
% %     'pt16sz1' 'pt16sz2' 'pt16sz3',...
% %     'pt17sz1' 'pt17sz2', 'pt17sz3', ...
% };

close all;

%% Set Root Directories
% data directories to save data into - choose one
eegRootDirHD = '/Volumes/NIL Pass/';
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                 % at ICM server 
eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';   % at home macbook
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';    % at JHU workstation
eegRootDirMarcctest = '/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/'; % at MARCC server
eegRootDirMarcc = '/scratch/groups/ssarma2/adamli/fragility_dataanalysis/';

% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
elseif ~isempty(dir(eegRootDirMarcc)), rootDir = eegRootDirMarcc;
elseif ~isempty(dir(eegRootDirHD)), rootDir = eegRootDirHD;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

addpath(genpath(fullfile(rootDir, '/fragility_library/')));
addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
addpath(rootDir);

% load the organized patients struct
load(fullfile(rootDir, 'serverdata/organized_patients/nih_patients.mat'));

patients = fieldnames(organized_patients);

%% Set Parameters
% set perturbation type to plot
perturbationTypes = ['C', 'R'];
perturbationType = perturbationTypes(1);

% plotting parameters
FONTSIZE = 20;

% data parameters to find correct directory
radius = 1.25;             % spectral radius of perturbation
winSize = 250;            % window size in milliseconds
stepSize = 125; 
filterType = 'adaptivefilter';  % adaptive, notch, or no
typeConnectivity = 'leastsquares'; 

% broadband filter parameters
typeTransform = 'fourier'; % morlet, or fourier

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

for iPat=1:length(patients)
    patient = patients{iPat};
    
    % extract the events to analyze for this patient
    data_events = organized_patients.(patient);
    
    for iEv=1:length(data_events)
        ev = data_events{iEv};
        pat = ev;
        
        % set patientID and seizureID
        patient_id = pat(1:strfind(pat, 'seiz')-1);
        seizure_id = strcat('_', pat(strfind(pat, 'seiz'):end));
        seeg = 1;
        INTERICTAL = 0;
        if isempty(patient_id)
            patient_id = pat(1:strfind(pat, 'sz')-1);
            seizure_id = pat(strfind(pat, 'sz'):end);
            seeg = 0;
        end
        if isempty(patient_id)
            patient_id = pat(1:strfind(pat, 'aslp')-1);
            seizure_id = pat(strfind(pat, 'aslp'):end);
            seeg = 0;
            INTERICTAL = 1;
        end
        if isempty(patient_id)
            patient_id = pat(1:strfind(pat, 'aw')-1);
            seizure_id = pat(strfind(pat, 'aw'):end);
            seeg = 0;
            INTERICTAL = 1;
        end

        buffpatid = patient_id;
        if strcmp(patient_id(end), '_')
            patient_id = patient_id(1:end-1);
        end

        [included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
            resection_labels, fs, center, success_or_failure] ...
                = determineClinicalAnnotations(patient_id, seizure_id);
        
        %- get perturbation directory for this patient
        pertDir = fullfile(rootDir, 'serverdata', 'pertmats', ...
            strcat(filterType), ...
            strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)));

%         spectDir = fullfile(rootDir, strcat('/serverdata/spectral_analysis/'), typeTransform, ...
%             strcat(filterType, 'filter'), strcat('win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)), ...
%             patient);
    
        % notch and updated directory
        spectDir = fullfile(rootDir, strcat('/serverdata/spectral_analysis/'), typeTransform, ...
            strcat(filterType, '_win', num2str(winSize), '_step', num2str(stepSize), '_freq', num2str(fs)), ...
            pat);
        
        % extract data
        % load computed results
        final_data = load(fullfile(pertDir, ...
            pat,...
            strcat(pat, '_pertmats', '.mat')));
        final_data = final_data.perturbation_struct;

        
        % load meta data
        info = final_data.info;

        % load perturbation data
        pertDataStruct = final_data.(perturbationType);

        %- extract clinical data
        ezone_labels = info.ezone_labels;
        earlyspread_labels = info.earlyspread_labels;
        latespread_labels = info.latespread_labels;
        resection_labels = info.resection_labels;
        included_labels = info.all_labels;
        seizure_estart_ms = info.seizure_estart_ms;
        seizure_estart_mark = info.seizure_estart_mark;
        seizure_eend_ms = info.seizure_eend_ms;
        seizure_eend_mark = info.seizure_eend_mark;
        num_channels = length(info.all_labels);
        engelscore = info.engelscore;

        %- set global variable for plotting
        seizureStart = seizure_estart_ms;
        seizureEnd = seizure_eend_ms;
        seizureMarkStart = seizure_estart_mark;

        clinicalIndices = getClinicalIndices(included_labels, ezone_labels,...
                        earlyspread_labels, latespread_labels, resection_labels);

        % min norm perturbation, fragility matrix, minmax fragility matrix
        minNormPertMat = pertDataStruct.minNormPertMat;
        fragilityMat = pertDataStruct.fragilityMat;
        minmaxFragility = min_max_scale(minNormPertMat); % perform min max scaling

        % broadband filter for this patient
        timeWinsToReject = broadbandfilter(pat, typeTransform, winSize, stepSize, filterType, spectDir);

        % OPTIONAL: apply broadband filter and get rid of time windows
        % set time windows to nan
    %     fragilityMat(timeWinsToReject) = nan;
    %     minmaxFragility(timeWinsToReject) = nan;

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
%             figure;
%             plot(thresholds, doa_buff, 'k-'); hold on; axes = gca; currfig = gcf;
%             xlabel('Thresholds'); ylabel(strcat({'DOA using', metric}));
%             title(['DOA for ', pat]);
%             if strcmp(metric, 'default')
%                 axes.YLim = [-1, 1]; 
%                 plot(axes.XLim, [0, 0], 'k--'); 
%             elseif strcmp(metric, 'jaccard')
%                 axes.YLim = [0, 1];
%             end
%             axes.FontSize = FONTSIZE;
% 
%             set(currfig, 'Units', 'inches');
% 
%         %     currfig.Position = [1986           1        1535        1121];
%             currfig.Position = [17.3438         0   15.9896   11.6771];
% 
%             toSaveFigFile = fullfile(figDir, strcat(pat, '_doavsthreshold'));
%             print(toSaveFigFile, '-dpng', '-r0')
        end
        
        % store results into success/failure data struct
        if strcmp(upper(outcome), 'SUCCESS')
            if isempty(success_d)
                success_d = doa_buff;
            else
                success_d = [success_d, doa_buff];
            end

            success_pats{end+1} = pat;
        elseif strcmp(upper(outcome), 'FAILURE')
            if isempty(failure_d) 
                failure_d = doa_buff;
            else
                failure_d = [failure_d, doa_buff];
            end

            failure_pats{end+1} = pat;
        end

        if isempty(pat_d)
            pat_d = doa_buff;
        else
            pat_d = [pat_d, doa_buff];
        end
        
    end % loop through data events
    
    % plot box plot for this one patient depending on threshold
    figure;
    for i=1:length(thresholds)
        subplot(1, length(thresholds), i);
        hold on; axes = gca; currfig = gcf;
        bh = boxplot(pat_d);
        xlabel(pat);
        ylabel(strcat('Degree of Agreement (', metric, ')'));
        titleStr = strcat('Threshold =', {' '}, num2str(thresholds(i)));
        title(titleStr);

        axes.FontSize = FONTSIZE;
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
    
    toSaveFigFile = fullfile(figDir, strcat(patient, '_doavsthreshold'));
    print(toSaveFigFile, '-dpng', '-r0') 
end % loop through patients in NIH

figure;
for i=1:length(thresholds)
    subplot(1,length(thresholds),i);
    hold on;
    axes = gca;
    currfig = gcf;
    toPlot = [success_d(:,i), failure_d(:,i)];
    grp = [zeros(1, length(success_d(i,:))), ones(1, length(failure_d(i,:)))];
    bh = boxplot(toPlot, grp, 'Labels', {'S', 'F'});
    xlabel('Success or Failed Surgery');
    ylabel(strcat('Degree of Agreement (', metric, ')'));
    titleStr = strcat('Threshold =', {' '}, num2str(thresholds(i)));
    title(titleStr);

    axes.FontSize = FONTSIZE;
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

titleStr = strcat(center, ' - ', patient, ' Agreement With Clinical For Surgical Outcomes');
h = suptitle(titleStr);
set(h, 'FontSize', FONTSIZE); 



figure;
for i=1:length(thresholds)
    doa_score = doa_scores(:, i);
    
    subplot(1,length(thresholds),i);
    hold on; axes = gca; currfig = gcf;
    bh = boxplot(doa_score, 'Labels', {'S', 'F'});
    set(bh, 'linewidth', 3);
    axes.Box = 'off'; axes.LineWidth = 3;
    xlabel('Engel Score'); ylabel(strcat('Degree of Agreement (', metric, ')'));
    titleStr = strcat('Threshold =', {' '}, num2str(thresholds(i))); title(titleStr);
    
    axes.FontSize = FONTSIZE;
    if strcmp(metric, 'default')
        axes.YLim = [-1, 1]; 
        plot(axes.XLim, [0, 0], 'k--', 'LineWidth', 1.5); 
    elseif strcmp(metric, 'jaccard')
        axes.YLim = [0, 1];
    end

    currfig.Units = 'inches';
    currfig.PaperPosition = [0    0.6389   20.0000   10.5417];
    currfig.Position = [0    0.6389   20.0000   10.5417];
end

% print our results for threshold = 0.9
avg_doa = mean(doa_score(length(thresholds),:)); 
sd_doa = std(doa_score(length(thresholds),:));

fprintf('Success doa: %.02f +/- %.02f\n', avg_doa, sd_doa);
