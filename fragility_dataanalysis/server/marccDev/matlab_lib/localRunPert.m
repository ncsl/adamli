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

% parameters
% data parameters to find correct directory
radius = 1.5;             % spectral radius of perturbation
winSize = 250;            % window size in milliseconds
stepSize = 125; 
filterType = 'notchfilter';  % adaptive, notch, or no
typeConnectivity = 'leastsquares'; 
reference = '';
perturbationTypes = ['C', 'R'];
w_space = linspace(-radius, radius, 51);
sigma = sqrt(radius^2 - w_space.^2); % move to the unit circle 1, for a plethora of different radial frequencies
b = [0; 1];                          % initialize for perturbation computation later

% add to sigma and w to create a whole circle search
w_space = [w_space, w_space];
sigma = [-sigma, sigma];

% broadband filter parameters
typeTransform = 'fourier'; % morlet, or fourier
JOBTYPE = 1;
fs = 1000;


tempDir = fullfile(dataDir, 'temp_trev_pert');
if ~exist(tempDir, 'dir')
    mkdir(tempDir);
end
   
%% Read in LTV Model Data
fprintf('Loading connectivity data...');
%- load the adjacency computed data
connDir = fullfile(dataDir, 'trev_adj');
            
ltvmodel_filename = 'trev_adjmats.mat';       
data = load(fullfile(connDir, ltvmodel_filename));
adjMats = data.adjMats;

% left off on: 340
for iTask=1:size(adjMats,1)
    %- extract adjMat at this window
    adjMat = squeeze(adjMats(iTask,:,:));
    [N, ~] = size(adjMat);

    % initialize the perturbation struct to save for this window
    perturbation_struct = struct();

    %%- Perform both perturbations
    for iPert=1:length(perturbationTypes)
        perturbationType = perturbationTypes(iPert);

        % initialize vectors to store
    %     minNormPerturbMat = zeros(N,1);
        fragilityMat = zeros(N,1);
    %     del_table = cell(N,1);

        perturb_args = struct();
        perturb_args.perturbationType = perturbationType;
        perturb_args.w_space = w_space;
        perturb_args.radius = radius;

        [minNormPert, del_vecs, ERRORS] = minNormPerturbation(adjMat, perturb_args);

        % store results
        minNormPerturbMat = minNormPert;
        del_table = del_vecs;

        %% 3. Compute fragility rankings per column by normalization
        % Compute fragility rankings per column by normalization
        for i=1:N      % loop through each channel
            fragilityMat(i) = (max(minNormPerturbMat(:)) - minNormPerturbMat(i)) ...
                                        / max(minNormPerturbMat(:));
        end

        % initialize struct to save
        perturbation_struct.(perturbationType) = struct();
        perturbation_struct.(perturbationType).del_table = del_table;
        perturbation_struct.(perturbationType).minNormPertMat = minNormPerturbMat;
        perturbation_struct.(perturbationType).fragilityMat = fragilityMat;
    end

    % display a message for the user
    fprintf(['Finished: ', num2str(iTask), '\n']);

         
    filename_tosave = strcat('trev_pert_', num2str(iTask));
    % save the file in temporary dir
    save(fullfile(tempDir, filename_tosave), 'perturbation_struct');
end
