%% Set Root Directories
% data directories to save data into - choose one
eegRootDirHD = '/Volumes/NIL Pass/';
eegRootDirHD = '/Volumes/ADAM LI/';
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                 % at ICM server
eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';   % at home macbook
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
thresholds = [0.6, 0.7, 0.8, 0.9, 0.95];
figDir = fullfile(rootDir, '/figures', 'fragilityStats', ...
strcat(filterType), ...
strcat('perturbation', perturbationType, '_win', num2str(winSize), '_step', num2str(stepSize), '_radius', num2str(radius)));
if ~exist(figDir, 'dir')
mkdir(figDir);
end
%% load the fragility mats and grid search results
% addpath('../');
load('../gridsearchictalsuccessmats.mat');
load('../gridsearchictalresults.mat');
% load('gridsearchmats.mat');
% load('gridsearchresults.mat');
% med_doa_params = [epsilon, a1, a2, a3, threshold];
patients = {...,
'pt1sz2','pt1sz3', 'pt1sz4', ...},...
'pt2sz1' 'pt2sz3' , 'pt2sz4', ...}, ...
'pt3sz2' 'pt3sz4', ...}, ...
'pt8sz1' 'pt8sz2' 'pt8sz3',...
'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5',...
'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
};
% excluded 'pt15sz2' because of an extremely noisy channel
% extract parameters chosen from grid search
doa_params = avg_doa_params
% doa_params = med_doa_params
% doa_params = min_doa_params
epsilon = doa_params(1); % epsilon on high_mask
a1 = doa_params(2); % weight on rowsum
a2 = doa_params(3); % weight on number of high fragility
a3 = doa_params(4); % weight on post_cfvarchan
threshold = doa_params(5); % threshold on final weighted sum
epsilon = 0.75;
a1 = 0.8;
a2 = 0.8;
a3 = 0.0;
%% Create result matrices to store doa
% to see what the doa is of combined
combinedoa = zeros(length(patients), 1);
% to keep track of regular doa
doa = zeros(length(patients), 3);
group_ind = 1;
NORMALIZE = 1;
%% Compute DOA For All Patients
skip = 0;
doas = zeros(length(patients), 1);
for pid=skip+1:length(patients) % loop through each patient
    patient_group = patients{pid};
    patient = patients{pid}
    if contains(lower(patient), 'aw') || contains(lower(patient), 'aslp')
        interictal = 1;
    else
        interictal = 0;
    end
    fragilityMat = allfragmats{pid};
    ezone_labels = allezlabels{pid};
    included_labels = allincludedlabels{pid};
    % remove POL from labels
    included_labels = upper(included_labels);
    included_labels = strrep(included_labels, 'POL', '');
    included_labels = strtrim(included_labels);
    ezone_labels = strrep(ezone_labels, 'POL', '');
    ezone_labels = strtrim(ezone_labels);

    % for pt8
%     if contains(patient, 'pt8')
%         fragilityMat = fragilityMat(:, 180:end);
%     end
%     % for pt13
%     if contains(patient, 'pt13')
%         fragilityMat = fragilityMat(:, 150:end);
%     end
    allfragmats{pid} = fragilityMat;
    if strcmp(patient, 'pt15sz2')
        allfragmats(pid) = [];
        allezlabels(pid) = [];
        allincludedlabels(pid) = [];
        break
    end
    if strcmp(patient, 'pt15sz3')
        allfragmats(pid) = [];
        allezlabels(pid) = [];
        allincludedlabels(pid) = [];
        break
    end
end
save('gridsearchictalsuccessmatsfinal.mat', 'allfragmats', 'allezlabels', 'allincludedlabels');