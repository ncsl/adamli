function serverPerturbationScript(patient, radius, winSize, stepSize, frequency_sampling)
addpath('../fragility_library/');
addpath(genpath('../eeg_toolbox/'));
addpath('../');
perturbationTypes = ['R', 'C'];
w_space = linspace(-1, 1, 101);

if nargin == 0 % testing purposes
    patient='EZT007seiz001';
    patient ='pt7sz19';
    patient = 'JH102sz1';
    % window paramters
    radius = 1.5;
    winSize = 500; % 500 milliseconds
    stepSize = 500; 
    frequency_sampling = 1000; % in Hz
end

setupScripts;

for j=1:length(perturbationTypes)
    perturbationType = perturbationTypes(j);

    toSaveFinalDataDir = fullfile(strcat(adjMat, num2str(winSize), ...
    '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), strcat(perturbationType, '_finaldata', ...
        '_radius', num2str(radius)));
    if ~exist(toSaveFinalDataDir, 'dir')
        mkdir(toSaveFinalDataDir);
    end

    perturb_args = struct();
    perturb_args.perturbationType = perturbationType;
    perturb_args.w_space = w_space;
    perturb_args.radius = radius;
    perturb_args.adjDir = toSaveAdjDir;
    perturb_args.toSaveFinalDataDir = toSaveFinalDataDir;
    perturb_args.labels = labels;
    perturb_args.included_channels = included_channels;
    perturb_args.num_channels = num_channels;
    perturb_args.frequency_sampling = frequency_sampling;

    computePerturbations(patient_id, seizure_id, perturb_args);
end
end