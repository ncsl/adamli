function serverAdjMainScript(patient, winSize, stepSize, frequency_sampling)
addpath(genpath('../fragility_library/'));
addpath(genpath('../eeg_toolbox/'));
addpath('../');
IS_SERVER = 1;
if nargin == 0 % testing purposes
    patient='EZT005seiz001';
    patient='JH102sz6';
    patient='pt1sz4';
    % window paramters
    winSize = 500; % 500 milliseconds
    stepSize = 500; 
    frequency_sampling = 1000; % in Hz
end

setupScripts;

% apply included channels to eeg and labels
if ~isempty(included_channels)
    eeg = eeg(included_channels, :);
    labels = labels(included_channels);
end

% define args for computing the functional connectivity
adj_args = struct();
adj_args.BP_FILTER_RAW = 1; % apply notch filter or not?
adj_args.frequency_sampling = frequency_sampling; % frequency that this eeg data was sampled at
adj_args.winSize = winSize;
adj_args.stepSize = stepSize;
adj_args.timeRange = timeRange;
adj_args.toSaveAdjDir = toSaveAdjDir;
adj_args.included_channels = included_channels;
adj_args.seizureStart = seizureStart;
adj_args.seizureEnd = seizureEnd;
adj_args.labels = labels;
adj_args.l2regularization = l2regularization;
adj_args.TYPE_CONNECTIVITY = TYPE_CONNECTIVITY;
adj_args.num_channels = size(eeg,1);    

if size(eeg, 1) < winSize
    % compute connectivity
    computeConnectivity(patient_id, seizure_id, eeg, clinicalLabels, adj_args);
else
    disp([patient, ' is underdetermined, must use optimization techniques']);
end
end