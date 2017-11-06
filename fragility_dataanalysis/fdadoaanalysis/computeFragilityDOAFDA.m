
patient = 'pt1';
dataDir = fullfile('/Users/adam2392/Documents/adamli/fragility_dataanalysis/',...
            'figures/fragilityStats/notchfilter/', ...
            'perturbationC_win250_step125_radius1.5/ictal_hardcoded/', patient);
        
        
% get all mat files in this directory
files = dir(fullfile(dataDir, '*.mat'));
filenames = {files.name};

thresholds = [0.7, 0.8, 0.9, 0.95];

row_D = zeros(length(thresholds), length(filenames));
post_D = zeros(length(thresholds), length(filenames));
ez_90_D = zeros(length(thresholds), length(filenames));
ez_95_D = zeros(length(thresholds), length(filenames));
for ifile=1:length(filenames)
    load(fullfile(dataDir, filenames{ifile}));
    
    % get metrics
    postcfvar_chan = features_struct.postcfvar_chan;
    rowsum = features_struct.rowsum;
    ez_90thresh_set = features_struct.ez_90thresh_set;
    ez_95thresh_set = features_struct.ez_95thresh_set;
    
    % get cez set
    cez = features_struct.ezone_labels;
    all_labels = features_struct.included_labels;
    
    % get ez set
    % for rowsum
    rowsum = rowsum ./ max(rowsum);
    
    % for postcfvarchan
    postcfvar_chan = postcfvar_chan ./ max(postcfvar_chan);
    
    % get corresponding doa for thresholds
    for ithresh=1:length(thresholds)
        threshold = thresholds(ithresh);
        
        row_inds = find(rowsum >= threshold);
        post_inds = find(postcfvar_chan >= threshold);
        
        row_ez = all_labels(row_inds)
        post_ez = all_labels(post_inds);
        
        % compute doa
        row_D(ithresh, ifile) = degreeOfAgreement(row_ez, ezone_labels, all_labels);
        post_D(ithresh, ifile) = degreeOfAgreement(post_ez, ezone_labels, all_labels);
        ez_90_D(ithresh, ifile) = degreeOfAgreement(ez_90thresh_set, ezone_labels, all_labels);
        ez_95_D(ithresh, ifile) = degreeOfAgreement(ez_95thresh_set, ezone_labels, all_labels);
    end
end

%% Plotting Box Plots
fig = figure;
subplot(221);
boxplot(row_D', 'Labels', thresholds);
title('Row sum after thresholding');

subplot(222);
boxplot(post_D', 'Labels', thresholds);
title('Coeff Var Thresholding');

subplot(223);
boxplot(ez_90_D', 'Labels', thresholds);
title('High Fragility 0.9 Thresholding');

subplot(224);
boxplot(ez_95_D', 'Labels', thresholds);
title('High Fragility 0.95 Thresholding');
