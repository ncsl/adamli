%% Initialization
% initialize variables
patients = {,...
    'pt1sz2', 'pt1sz3', 'pt1sz4',...
    'pt2sz1' 'pt2sz3' 'pt2sz4', ...
    'pt3sz2' 'pt3sz4', ...
};

IS_SERVER = 0;
% data parameters to find correct directory
radius = 1.5;             % spectral radius
winSize = 500;            % 500 milliseconds
stepSize = 500; 
frequency_sampling = 1000; % in Hz

FONTSIZE = 20;
YAXFontSize = 10;

figDir = fullfile('./figures/testingElectrodes//');
if ~exist(figDir, 'dir')
    mkdir(figDir);
end

for iPat=1:length(patients)
    patient = patients{iPat};
    
    if ~exist(fullfile(figDir, patient), 'dir')
        mkdir(fullfile(figDir, patient));
    end
    
    setupScripts;
    
    dataDir = './serverdata/testing_adj_mats_win500_step500_freq1000/';
    %- load in the min perturbation / fragility data
    rowPertFile = fullfile(dataDir, 'R_perturbations_radius1.5', ...
        strcat(patient, '_Rperturbation_leastsquares_radius1.5.mat'));
    colPertFile = fullfile(dataDir, 'C_perturbations_radius1.5', ...
        strcat(patient, '_Cperturbation_leastsquares_radius1.5.mat'));
    
    rowPert = load(rowPertFile);
    rowPert = rowPert.perturbation_struct;
    
    %- examine min perturbation / fragility ranking
    minPerturbMat = rowPert.minNormPertMat;
    fragilityMat = rowPert.fragility_rankings;
    
    %- compute variance for each channel across time
    minPerturbVar = var(minPerturbMat, 0, 2);
    fragilityVar = var(fragilityMat, 0, 2);
    
    %- setup vars for plotting
    %%- Get Indices for All Clinical Annotations
    if ~isempty(included_channels)
        included_labels = labels(included_channels);
    else
        included_labels = labels;
    end
    num_channels = length(included_labels);
    
    ezone_indices = findElectrodeIndices(ezone_labels, included_labels);
    earlyspread_indices = findElectrodeIndices(earlyspread_labels, included_labels);
    latespread_indices = findElectrodeIndices(latespread_labels, included_labels);

    allYTicks = 1:num_channels; 
    y_indices = setdiff(allYTicks, [ezone_indices; earlyspread_indices]);
    if sum(latespread_indices > 0)
        latespread_indices(latespread_indices ==0) = [];
        y_indices = setdiff(allYTicks, [ezone_indices; earlyspread_indices; latespread_indices]);
    end
    y_ezoneindices = sort(ezone_indices);
    y_earlyspreadindices = sort(earlyspread_indices);
    y_latespreadindices = sort(latespread_indices);
    
    % find resection indices
    y_resectionindices = [];

    % create struct for clinical indices
    all_indices = y_indices;
    ezone_indices = y_ezoneindices;
    earlyspread_indices = y_earlyspreadindices;
    latespread_indices = y_latespreadindices;
    resection_indices = y_resectionindices;
    included_labels = included_labels;
    
    %% PLOTTING
    %- plot the first figure
    figure;
    firstplot = 1:24;
    firstplot([6,12,18,24]) = [];
    firstfig = subplot(4,6, firstplot);
%     imagesc(minPerturbMat); 
    imagesc(fragilityMat)
    axes = gca; currfig = gcf;
    hold on; colormap('jet'); colorbar();
    set(axes, 'box', 'off'); set(axes, 'YDir', 'normal');

    title('Row Perturbation');
    
    XLim = get(gca, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);
    xlim([XLowerLim, XUpperLim+1]);

    % plot start star's for the different clinical annotations
    figIndices = {ezone_indices, earlyspread_indices, latespread_indices};
    colors = {[1 0 0], [1 .5 0], [0 0 1]};
    for i=1:length(figIndices)
        if sum(figIndices{i})>0
            xLocations = repmat(XUpperLim+1, length(figIndices{i}), 1);
            plotAnnotatedStars(firstfig, xLocations, figIndices{i}, colors{i});
        end
    end
    
    currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
    currfig.Position = [1986           1        1535        1121];
    
    % plot the different labels on different axes to give different colors
    plotOptions = struct();
    plotOptions.YAXFontSize = YAXFontSize;
    plotOptions.FONTSIZE = FONTSIZE;
    plotIndices(currfig, plotOptions, all_indices, included_labels, ...
                                ezone_indices, ...
                                earlyspread_indices, ...
                                latespread_indices)
    
    %- plot the second figure
    secfig = subplot(4,6, [6,12,18,24]);
    plot(minPerturbVar, 1:size(minPerturbMat, 1), 'ko'); hold on;
    plot(fragilityVar, 1:size(minPerturbMat, 1), 'go');
    plot([mean(minPerturbVar) mean(minPerturbVar)], [1 size(minPerturbMat,1)], 'k');
    plot([mean(fragilityVar) mean(fragilityVar)], [1 size(minPerturbMat,1)], 'g');
    pos = get(gca, 'Position');
    set(gca, 'YTick', []); set(gca, 'YTickLabel', []);
    set(gca, 'yaxislocation', 'right');
    title('Variance');
    leg = legend('Min Perturbation', 'Fragility');
    leg.Position = [0.8083    0.9582    0.0919    0.0308];
    
    maxIndice = find(fragilityVar == max(fragilityVar))
    find(fragilityVar == min(fragilityVar))
    included_labels(maxIndice)
    
    print(fullfile(figDir, patient, strcat(patient, '_rowPertcheck')), '-dpng', '-r0')
    
    %% PLOTTING
    
    colPert = load(colPertFile);
    colPert = colPert.perturbation_struct;
    
    %- examine min perturbation / fragility ranking
    minPerturbMat = colPert.minNormPertMat;
    fragilityMat = colPert.fragility_rankings;
    
    %- compute variance for each channel across time
    minPerturbVar = var(minPerturbMat, 0, 2);
    fragilityVar = var(fragilityMat, 0, 2);
    
    %- plot the first figure
    figure;
    firstplot = 1:24;
    firstplot([6,12,18,24]) = [];
    firstfig = subplot(4,6, firstplot);
%     imagesc(minPerturbMat); 
    imagesc(fragilityMat)
    axes = gca; currfig = gcf;
    hold on; colormap('jet'); colorbar();
    set(axes, 'box', 'off'); set(axes, 'YDir', 'normal');

    title('Column Perturbation');
    
    XLim = get(gca, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);
    xlim([XLowerLim, XUpperLim+1]);

    % plot start star's for the different clinical annotations
    figIndices = {ezone_indices, earlyspread_indices, latespread_indices};
    colors = {[1 0 0], [1 .5 0], [0 0 1]};
    for i=1:length(figIndices)
        if sum(figIndices{i})>0
            xLocations = repmat(XUpperLim+1, length(figIndices{i}), 1);
            plotAnnotatedStars(firstfig, xLocations, figIndices{i}, colors{i});
        end
    end
    
    currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
    currfig.Position = [1986           1        1535        1121];
    
    % plot the different labels on different axes to give different colors
    plotOptions = struct();
    plotOptions.YAXFontSize = YAXFontSize;
    plotOptions.FONTSIZE = FONTSIZE;
    plotIndices(currfig, plotOptions, all_indices, included_labels, ...
                                ezone_indices, ...
                                earlyspread_indices, ...
                                latespread_indices)
    
    %- plot the second figure
    secfig = subplot(4,6, [6,12,18,24]);
    plot(minPerturbVar, 1:size(minPerturbMat, 1), 'ko'); hold on;
    plot(fragilityVar, 1:size(minPerturbMat, 1), 'go');
    plot([mean(minPerturbVar) mean(minPerturbVar)], [1 size(minPerturbMat,1)], 'k');
    plot([mean(fragilityVar) mean(fragilityVar)], [1 size(minPerturbMat,1)], 'g');
    pos = get(gca, 'Position');
    set(gca, 'YTick', []); set(gca, 'YTickLabel', []);
    set(gca, 'yaxislocation', 'right');
    title('Variance');
    leg = legend('Min Perturbation', 'Fragility');
    leg.Position = [0.8083    0.9582    0.0919    0.0308];
    
    maxIndice = find(fragilityVar == max(fragilityVar))
    find(fragilityVar == min(fragilityVar))
    included_labels(maxIndice)
    
    print(fullfile(figDir, patient, strcat(patient, '_colPertcheck')), '-dpng', '-r0')
    
    close all
end