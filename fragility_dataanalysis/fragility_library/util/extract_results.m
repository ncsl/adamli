function [final_data, info] = extract_results(patient, resultsDir, reference)
if nargin == 0
    % data parameters to find correct directory
    patient = 'pt1sz2';
%     patient='JH103aw1';
%     patient = 'pt1aw1';
    radius = 1.5;             % spectral radius
    winSize = 250;            % 500 milliseconds
    stepSize = 125; 
    filterType = 'adaptivefilter';
    filterType = 'notchfilter';
    fs = 1000; % in Hz
    typeConnectivity = 'leastsquares';
    typeTransform = 'fourier';
    rejectThreshold = 0.3;
    reference = 'avgref';
    
    dataDir = '/Volumes/ADAM LI/';
    resultsDir = fullfile(dataDir, strcat('/serverdata/pertmats/', filterType, '/win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(fs), '_radius', num2str(radius)), patient, reference); % at lab
end
    
% extract data
try
    final_data = load(fullfile(resultsDir, ...
        strcat(patient, '_pertmats', reference, '.mat')));
catch e
    final_data = load(fullfile(resultsDir, ...
        strcat(patient, '_pertmats_leastsquares_radius', num2str(radius), '.mat')));
end
final_data = final_data.perturbation_struct;

%% Extract metadata info
info = final_data.info;
end