clear all
clc
close all
%% Success Ictal
patients = {...,
    {'pt1sz2', 'pt1sz3', 'pt1sz4'}, ...},...
    {'pt2sz1' 'pt2sz3' , 'pt2sz4'}, ...}, ...
    {'pt3sz2' 'pt3sz4'}, ...}, ...
    {'pt8sz1' 'pt8sz2' 'pt8sz3'},...
    {'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5'},...
    {'pt15sz1' 'pt15sz4'},...
};
times = {,...
    [15, 12, 9], ... % pt1
    [40, 40, 55],... % pt2
    [15, 15],... % pt3
    [8 8 8],... % pt 8
    [7 7 7 7],... % pt13
    [20 25],... % pt 15
};

%% Interictal
% patients={, ...
% {'pt1aw1','pt1aw2', 'pt1aslp1','pt1aslp2'}, ...
% {'pt2aw1', 'pt2aw2', 'pt2aslp1', 'pt2aslp2'},...
% {'pt3aw1', 'pt3aslp1', 'pt3aslp2'}, ...
% };
% times = {,...
%     [15, 12, 10, [], [], [], []], ... % pt1
%     [60, 60, 75, [], [], [], []],... % pt2
%     [17, 17, [], [], []],... % pt3
%     [12 12 12],... % pt 8
%     [7 7 7 7],... % pt13
%     [20 30 10 30],... % pt 15
% };

%% Failures
% patients = {,...
%     {'pt6sz3', 'pt6sz4', 'pt6sz5'},...
%     {'pt7sz19', 'pt7sz21', 'pt7sz22'},...
%     {'pt10sz1','pt10sz2' 'pt10sz3'}, ...
%     {'pt12sz1', 'pt12sz2'},...
%     {'pt14sz1' 'pt14sz2' 'pt14sz3'}, ...
% };
% times = {,...
%     [10, 10 10],... % pt 6
% 	[10 30 10],... % pt 7
% 	[50 50 50],... % pt 10
%     [170, 170], ...
% 	[60 55 55],... % pt 14
% };
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

figDir = fullfile(rootDir, '/figures', 'fragilityStats', ...
    strcat(filterType), ...
    strcat('perturbation', perturbationType, '_win', num2str(winSize), '_step', num2str(stepSize), '_radius', num2str(radius)));

if ~exist(figDir, 'dir')
    mkdir(figDir);
end

% to keep track of max_avg_doa 
maxavgdoa = zeros(length([patients{:}]), 3);

% store frag mats
allfragmats = cell(length([patients{:}]), 1);
allezlabels = cell(length([patients{:}]), 1);
allincludedlabels = cell(length([patients{:}]), 1);
allresectionlabels = cell(length([patients{:}]), 1);
allspreadlabels = cell(length([patients{:}]), 1);

% params to include the plot for doa also
epsilon = 0.8;
a1 = 0.8;
a2 = 0.2;
a3=0;
threshold=0.2;
NORMALIZE=1;
doas = zeros(length([patients{:}]), 1);

%% Perform Gridsearch on DOA stat
% save('gridsearchmats.mat', 'allfragmats');
alpha1 = linspace(0.5, 1, 5);
alpha2 = linspace(0.4, 1, 5);
alpha3 = linspace(0, 0.5, 5);
thresholds = [0.6, 0.7, 0.8, 0.9, 0.95];
epsilons = linspace(0.65, 0.85, 5);

NORMALIZE = 1;

% patients = {...,
%     'pt1sz2', 'pt1sz3', 'pt1sz4', 'pt1aw1','pt1aw2', 'pt1aslp1','pt1aslp2', ...},...
%     'pt2sz1' 'pt2sz3' , 'pt2sz4', 'pt2aw1', 'pt2aw2', 'pt2aslp1', 'pt2aslp2', ...}, ...
%     'pt3sz2' 'pt3sz4', 'pt3aw1', 'pt3aslp1', 'pt3aslp2', ...}, ...
%     'pt8sz1' 'pt8sz2' 'pt8sz3',...
%     'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5',...
%     'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
% };
patients = {...,
    'pt1sz2', 'pt1sz3', 'pt1sz4', ...},...
    'pt2sz1' 'pt2sz3' , 'pt2sz4', ...}, ...
    'pt3sz2' 'pt3sz4', ...}, ...
    'pt8sz1' 'pt8sz2' 'pt8sz3',...
    'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5',...
    'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
};

patinds = [1, 2, 3, 4, 5, 6]; % pt1, pt2, pt3, pt8, pt13, pt15

% to see what the doa is of combined
combinedoa = zeros(length(patients), 1);
% to keep track of regular doa
doa = zeros(length(patients), 3);
group_ind = 1;

% get distribution of DOAs per patient -> grid search to maximize metrics
% track min doa for succes, avg doa, median doa
min_doa = 0;
min_doa_params = [];
avg_doa = 0;
avg_doa_params = [];
med_doa = 0;
med_doa_params = [];

% perform grid search on the parameter weights
for i=1:length(alpha1)
    for j=1:length(alpha2)
        for k=1:length(alpha3)
            for l=1:length(epsilons)
                tic;
                for m=1:length(thresholds)
                    epsilon = epsilons(l);
                    a1 = alpha1(i);
                    a2 = alpha2(j);
                    a3 = alpha3(k);
                    threshold = thresholds(m);

                    doas = zeros(length(patients), 1);
                    %% Compute DOA For Success Patients 
                    for pid=1:length(patients) % loop through each patient
                        patient_group = patients{pid};
                        patient = patients{pid};
    %                     for p=1:length(patient_group)

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
                            
                            if interictal
                                % compute on interictal
                                [rowsum, excluded_indices, num_high_fragility] = computedoainterictal(fragilityMat, epsilon, NORMALIZE);
                            else
                                % compute on preictal
                                [prerowsum, preexcluded_indices, prenum_high_fragility, precfvar_chan] = computedoaictal(fragilityMat, ...
                                                  1, size(fragilityMat, 2), epsilon, NORMALIZE);

                                % compute on ictal
                                [rowsum, excluded_indices, num_high_fragility, postcfvar_chan] = computedoaictal(fragilityMat, ...
                                                1, size(fragilityMat, 2), epsilon, NORMALIZE);
                            end
                            % don't need to normalize post cfvar 

                            % normalize rowsum, high fragility
%                             rowsum = rowsum ./ max(rowsum);
%                             num_high_fragility = num_high_fragility ./ max(num_high_fragility);

                            % compute weighted sum
                            if ~interictal
                                weightnew_sum = a1*rowsum + a2*num_high_fragility  + a3*postcfvar_chan;
                            else
                                weightnew_sum = a1*rowsum + a2*num_high_fragility;
                            end
                            weightnew_sum = weightnew_sum ./ max(weightnew_sum); 
                            % compute DOA
                            [doas(pid), fragilesets] = compute_doa_threshold(weightnew_sum, ezone_labels, included_labels, threshold, metric);        
                    end % end of loop through all patients
                    
                    % keep track of minimum doa among all success patients
                    if min(doas) > min_doa
                        min_doa = min(doas);
                        min_doa_params = [epsilon, a1, a2, a3, threshold];
                    end
                    if mean(doas) > avg_doa
                        avg_doa = mean(doas);
                        avg_doa_params = [epsilon, a1, a2, a3, threshold];
                    end
                    if median(doas) > med_doa
                        med_doa = median(doas);
                        med_doa_params = [epsilon, a1, a2, a3, threshold];
                    end
                end
                toc
            end
        end
    end
end
        
save('gridsearchictalresultsv2.mat', 'min_doa', 'min_doa_params', 'avg_doa', ...
    'avg_doa_params', 'med_doa', 'med_doa_params');
