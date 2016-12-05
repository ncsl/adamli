% settings to run
patients = {,...,
     'pt1aw1', 'pt1aw2', ...
    'pt1aslp1', 'pt1aslp2', ...
    'pt2aw1', 'pt2aw2', ...
    'pt2aslp1', ...
    'pt2aslp2', ...
    'pt3aw1', ...
    'pt3aslp1', 'pt3aslp2', ...
    'pt1sz2', 'pt1sz3', 'pt1sz4',...
    'pt2sz1' 'pt2sz3' 'pt2sz4', ...
    'pt3sz2' 'pt3sz4', ...
%       'pt6sz3', 'pt6sz4', 'pt6sz5','JH108sz1', 'JH108sz2', 'JH108sz3', 'JH108sz4', 'JH108sz5', 'JH108sz6', 'JH108sz7',...
%     'pt8sz1' 'pt8sz2' 'pt8sz3',...
%     'pt10sz1' 'pt10sz2' 'pt10sz3', ...
%     'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
%     'pt14sz1' 'pt14sz2' 'pt14sz3' 'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
%     'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt17sz1' 'pt17sz2',...
%     'JH101sz1' 'JH101sz2' 'JH102sz3' 'JH102sz4',...
% 	'JH102sz1' 'JH102sz2' 'JH102sz3' 'JH102sz4' 'JH102sz5' 'JH102sz6',...
% 	'JH103sz1' 'JH102sz2' 'JH102sz3',...
% 	'JH104sz1' 'JH104sz2' 'JH104sz3',...
% 	'JH105sz1' 'JH105sz2' 'JH105sz3' 'JH105sz4' 'JH105sz5',...
% 	'JH106sz1' 'JH106sz2' 'JH106sz3' 'JH106sz4' 'JH106sz5' 'JH106sz6',...
% 	'JH107sz1' 'JH107sz2' 'JH107sz3' 'JH107sz4' 'JH107sz5' 'JH107sz6' 'JH107sz7' 'JH107sz8' 'JH107sz8',...
%    'JH108sz1', 'JH108sz2', 'JH108sz3', 'JH108sz4', 'JH108sz5', 'JH108sz6', 'JH108sz7',...
%     'EZT030seiz001', 'EZT030seiz002', 
%       'EZT037seiz001', 'EZT037seiz002',...
%     'EZT045seiz001', 'EZT045seiz002',...
% 	'EZT070seiz001', 'EZT070seiz002', 'EZT005seiz001', 'EZT005seiz002', 'EZT007seiz001', 'EZT007seiz002', ...
%     'EZT019seiz001', 'EZT019seiz002',
% 'EZT090seiz002', 'EZT090seiz003' ...
    };
% patients = { 'EZT108_seiz002', 'EZT120_seiz001', 'EZT120_seiz002'}; %,
% patients = {'Pat2sz1p', 'Pat2sz2p', 'Pat2sz3p'};%, 'Pat16sz1p', 'Pat16sz2p', 'Pat16sz3p'};
perturbationTypes = ['R', 'C'];
w_space = linspace(-1, 1, 101);
threshold = 0.8;          % threshold on fragility metric

radius = 1.5;             % spectral radius
winSize = 500;            % 500 milliseconds
stepSize = 500; 
frequency_sampling = 1000; % in Hz
IS_SERVER = 0;
timeRange = [60 0];

% add libraries of functions
addpath(genpath('./fragility_library/'));
addpath(genpath('/Users/adam2392/Dropbox/eeg_toolbox'));
addpath(genpath('/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/eeg_toolbox/'));

for p=1:length(patients)
    patient = patients{p};
    serverPerturbationScript(patient, radius, winSize, stepSize, frequency_sampling)
end

% function numtimes = serverSetupComputePert(patient_id, seizure_id, perturb_args)%, clinicalLabels)
% if nargin == 0
%     patient_id = 'pt1';
%     seizure_id = 'sz2';
%     radius = 1.1;
%     w_space = linspace(-1, 1, 101);
%     perturbationType = 'R';
%     winSize = 500;
%     stepSize = 500;
%     included_channels = 0;
% end
% frequency_sampling = 1000;
% patient = strcat(patient_id, seizure_id);
% %% 0: Extract Vars and Initialize Parameters
% perturbationType = perturb_args.perturbationType;
% w_space = perturb_args.w_space;
% radius = perturb_args.radius;
% adjDir = perturb_args.adjDir;
% toSaveFinalDataDir = perturb_args.toSaveFinalDataDir;
% TYPE_CONNECTIVITY = perturb_args.TYPE_CONNECTIVITY;
% 
% sigma = sqrt(radius^2 - w_space.^2); % move to the unit circle 1, for a plethora of different radial frequencies
% b = [0; 1];                          % initialize for perturbation computation later
% 
% % get list of mat files
% matFile = fullfile(adjDir, strcat(patient, '_adjmats_', lower(TYPE_CONNECTIVITY), '.mat'));
% matFiles = [matFile];
% 
% data = load(matFile);
% adjmat_struct = data.adjmat_struct;
% numtimes = size(adjmat_struct.adjMats,1);
% end