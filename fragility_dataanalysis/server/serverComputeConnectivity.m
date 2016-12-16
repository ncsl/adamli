function serverComputeConnectivity(patient_id, seizure_id, currentWin, eeg, adj_args)
 
% add libraries of functions
addpath(genpath('/Users/adam2392/Dropbox/eeg_toolbox'));
addpath(genpath('/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/eeg_toolbox/'));

% extract arguments and clinical annotations
frequency_sampling = adj_args.frequency_sampling; % frequency that this eeg data was sampled at
winSize = adj_args.winSize;
stepSize = adj_args.stepSize;
toSaveAdjDir = adj_args.toSaveAdjDir;
seizureStart = adj_args.seizureStart; % time seizure starts
seizureEnd = adj_args.seizureEnd; % time seizure ends
included_channels = adj_args.included_channels;
labels = adj_args.labels;
l2regularization = adj_args.l2regularization;
num_channels = adj_args.num_channels;

TYPE_CONNECTIVITY = adj_args.TYPE_CONNECTIVITY;

% set options for connectivity measurements
OPTIONS.l2regularization = l2regularization;

% patient identification
patient = strcat(patient_id, seizure_id); 
% fileName = strcat(patient, '_adjmats_', lower(TYPE_CONNECTIVITY), '_', num2str(currentWin), '.mat');
fileName = strcat(patient, '_adjmats_', num2str(currentWin));
disp(fileName);

% step 2: compute some functional connectivity 
if strcmp(TYPE_CONNECTIVITY, 'LEASTSQUARES')
    % linear model: Ax = b; A\b -> x
    b = double(eeg(:)); % define b as vectorized by stacking columns on top of another
    b = b(num_channels+1:end); % only get the time points after the first one

    % - use least square computation
    theta = computeLeastSquares(eeg, b, OPTIONS);
    theta_adj = reshape(theta, num_channels, num_channels)';    % reshape fills in columns first, so must transpose
elseif strcmp(TYPE_CONNECTIVITY, 'SPEARMAN') || strcmp(TYPE_CONNECTIVITY, 'PEARSON')
    theta_adj = computePairwiseCorrelation(tmpdata, TYPE_CONNECTIVITY);
elseif PDC
    A = theta_adj; 
    p_opt = 1;
    Nf = 250;
    [~, PDC] = computeDTFandPDC(A, p_opt, frequency_sampling, Nf);
elseif DTF
    [DTF, ~] = computeDTFandPDC(A, p_opt, frequency_sampling, Nf);
end

% display a message for the user
disp(['Finished: ', num2str(currentWin)]);

% save the file in temporary dir
save(fullfile(toSaveAdjDir, fileName), 'theta_adj');
end