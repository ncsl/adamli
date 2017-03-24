patients = {,...,
%      'pt1aw1','pt1aw2', ...
%     'pt1aslp1', 'pt1aslp2', ...
%     'pt2aw1', 'pt2aw2', ...
%     'pt2aslp1', 'pt2aslp2', ...
%     'pt3aw1', ...
%     'pt3aslp1', 'pt3aslp2', ...
%     'pt1sz2', 'pt1sz3', 'pt1sz4',...
%     'pt2sz1' 'pt2sz3' ,'pt2sz4', ...
%     'pt3sz2' 'pt3sz4', ...
%     'pt6sz3', 'pt6sz4', 'pt6sz5',...
%     'pt7sz19', 'pt7sz22',...'pt7sz21', 
%     'pt8sz1' 'pt8sz2' 'pt8sz3',...
%     'pt10sz1', 'pt10sz2' 'pt10sz3', ...
%     'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
%     'pt12sz1', 'pt12sz2', ...
%     'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5',...
%     'pt14sz1' 'pt14sz2' 'pt14sz3'  'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
%     'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt17sz1' 'pt17sz2',...
%     'JH101sz1' 'JH101sz2' 'JH101sz3' 'JH101sz4',...
% 	'JH102sz1' 'JH102sz2' 'JH102sz3' 'JH102sz4' 'JH102sz5' 'JH102sz6',...
% 	'JH103sz1' 'JH103sz2' 'JH103sz3',...
% 	'JH104sz1' 'JH104sz2' 'JH104sz3',...
% 	'JH105sz1' 'JH105sz2' 'JH105sz3' 'JH105sz4' 'JH105sz5',...
% 	'JH106sz1' 'JH106sz2' 'JH106sz3' 'JH106sz4' 'JH106sz5' 'JH106sz6',...
% 	'JH107sz1' 'JH107sz2' 'JH107sz3' 'JH107sz4' 'JH107sz5' 
%     'JH107sz6' 'JH107sz7' 'JH107sz8' 'JH107sz9',...
%    'JH108sz1', 'JH108sz2', 'JH108sz3', 'JH108sz4', 'JH108sz5', 'JH108sz6', 'JH108sz7',...
%     'EZT004seiz001', 'EZT004seiz002', ...
%     'EZT006seiz001', 'EZT006seiz002', ...
%     'EZT008seiz001', 'EZT008seiz002', ...
%     'EZT009seiz001', 'EZT009seiz002', ...    
%     'EZT011seiz001', 'EZT011seiz002', ...
%     'EZT013seiz001', 'EZT013seiz002', ...
%     'EZT020seiz001', 'EZT020seiz002', ...
%     'EZT025seiz001', 'EZT025seiz002', ...
%     'EZT026seiz001', 'EZT026seiz002', ...
%     'EZT028seiz001', 'EZT028seiz002', ...
%    'EZT037seiz001', 'EZT037seiz002',...
%    'EZT019seiz001', 'EZT019seiz002',...
%    'EZT005seiz001', 'EZT005seiz002',...
%     'EZT007seiz001', 'EZT007seiz002', ...
%    	'EZT070seiz001', 'EZT070seiz002', ...
%     'Pat2sz1p', 'Pat2sz2p', 'Pat2sz3p', ...
%     'Pat16sz1p', 'Pat16sz2p', 'Pat16sz3p',...
    'UMMC001_sz1', 'UMMC001_sz2', 'UMMC001_sz3', ...
    'UMMC002_sz1', 'UMMC002_sz2','UMMC002_sz3', ...
    'UMMC003_sz1', 'UMMC003_sz2', 'UMMC003_sz3', ...
    'UMMC004_sz1', 'UMMC004_sz2', 'UMMC004_sz3', ...
    'UMMC005_sz1', 'UMMC005_sz2', 'UMMC005_sz3', ...
    'UMMC006_sz1', 'UMMC006_sz2', 'UMMC006_sz3', ...
    'UMMC007_sz1', 'UMMC007_sz2','UMMC007_sz3', ...
    'UMMC008_sz1', 'UMMC008_sz2', 'UMMC008_sz3', ...
    'UMMC009_sz1', 'UMMC009_sz2', 'UMMC009_sz3', ...
    };
close all;
%% Parameters for Analysis
winSize = 500;
stepSize = 500;
frequency_sampling = 1000;
radius = 1.5;

TYPE_CONNECTIVITY = 'leastsquares';
perturbationType = 'C';
TEST_DESCRIP = 'after_first_removal';
TEST_DESCRIP = [];

FONTSIZE = 18;
YAXFONTSIZE = 8;
%% Set Working Directories
% set working directory
% data directories to save data into - choose one
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                      % ICM SERVER
% eegRootDirHome = '/Users/adam2392/Documents/MATLAB/Johns Hopkins/NINDS_Rotation'; % home
eegRootDirHome = '/Volumes/NIL_PASS/';                                              % external HD
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';         % at work - JHU

% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
else   error('Neither Work nor Home EEG directories exist! Exiting.'); end

addpath(genpath(fullfile(rootDir, '/fragility_library/')));
addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
addpath(rootDir);

figDir = fullfile(rootDir, '/figures/patientFigs/', strcat('win', num2str(winSize),...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling), '_radius', num2str(radius)));
if ~exist(figDir, 'dir')
    mkdir(figDir);
end

%%- Begin Loop Through Different Patients Here
for p=1:length(patients)
    patient = patients{p};

    % set patientID and seizureID
    patient_id = patient(1:strfind(patient, 'seiz')-1);
    seizure_id = strcat('_', patient(strfind(patient, 'seiz'):end));
    seeg = 1;
    INTERICTAL = 0;
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'sz')-1);
        seizure_id = patient(strfind(patient, 'sz'):end);
        seeg = 0;
    end
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'aslp')-1);
        seizure_id = patient(strfind(patient, 'aslp'):end);
        seeg = 0;
        INTERICTAL = 1;
    end
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'aw')-1);
        seizure_id = patient(strfind(patient, 'aw'):end);
        seeg = 0;
        INTERICTAL = 1;
    end
    buffpatid = patient_id;
    if strcmp(patient_id(end), '_')
        patient_id = patient_id(1:end-1);
    end
    [included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
        resection_labels, frequency_sampling, center, success_or_failure] ...
            = determineClinicalAnnotations(patient_id, seizure_id);

     serverDir = fullfile(rootDir, '/serverdata/');
    %%- Extract an example
    adjMatDir = fullfile(serverDir, 'adjmats/adaptivefilter_adjmats/', strcat('win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), patient);
    % directory that computed perturbation structs are saved
    finalDataDir = fullfile(serverDir, 'perturbationmats/adaptivefilter/', strcat(perturbationType, '_perturbations', ...
            '_radius', num2str(radius)), strcat('win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), patient);

            
    if ~isempty(TEST_DESCRIP)
        adjMatDir = fullfile(adjMatDir, TEST_DESCRIP);
    end
    if ~isempty(TEST_DESCRIP)
        finalDataDir = fullfile(finalDataDir, TEST_DESCRIP);
    end
    adj_data = load(fullfile(adjMatDir, strcat(patient, '_adjmats_', lower(TYPE_CONNECTIVITY), '.mat')));
    final_data = load(fullfile(finalDataDir, strcat(patient, ...
            '_', perturbationType, 'perturbation_', lower(TYPE_CONNECTIVITY), ...
            '_radius', num2str(radius), '.mat')));
    adjmat_struct = adj_data.adjmat_struct;
    final_data = final_data.perturbation_struct;
    
    % set adjacency data to local vars
    adjMats = adjmat_struct.adjMats;
    
    % set perturbation data to local variables
    minPerturb_time_chan = final_data.minNormPertMat;
    fragility_rankings = final_data.fragilityMat;
    timePoints = final_data.timePoints;
    info = final_data.info;
    num_channels = size(minPerturb_time_chan,1);
    seizureStart = info.seizure_start;
    seizureEnd = info.seizure_end;
    included_labels = info.all_labels;
%     winSize = info.winSize;
%     stepSize = info.stepSize;
    frequency_sampling = info.frequency_sampling;
    
    tempWinSize = winSize;
    tempStepSize = stepSize;
    if frequency_sampling ~=1000
        tempWinSize = winSize*frequency_sampling/1000;
        tempStepSize = stepSize*frequency_sampling/1000;
    end
    
    % seizure Mark 
    seizureMarkStart = seizureStart / tempStepSize - 1;
    if seeg
        seizureMarkStart = (seizureStart-1) / tempStepSize;
    end  
    
    seizureMarkEnd = seizureEnd / tempStepSize - 1;
    if seeg
        seizureMarkEnd = (seizureEnd-1) / tempStepSize;
    end
 
    %- get clinical indices of annotations
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
    clinicalIndices.all_indices = y_indices;
    clinicalIndices.ezone_indices = y_ezoneindices;
    clinicalIndices.earlyspread_indices = y_earlyspreadindices;
    clinicalIndices.latespread_indices = y_latespreadindices;
    clinicalIndices.resection_indices = y_resectionindices;
    clinicalIndices.included_labels = included_labels;
    
    %% PLOTTING
    %- 1. Plot adjacency matrix
    % get random index
    [T, N, ~] = size(adjMats);
    randIndice = randsample(seizureMarkStart, 1); % get random time point
    timeWindow = timePoints(randIndice,:) - seizureStart;
    timeWindow(1) = timeWindow(1) - 1;
    timeWindow = timeWindow / frequency_sampling;
    adjMat = squeeze(adjMats(randIndice,:,:));
    
    fig = figure;
    minpertplot = 1:4;
    minpertplot([1, 2]) = []; hold on;
    
    included_labels = strrep(included_labels, 'POL', '');
    
    %% Plot A_i matrix
    firstfig = subplot(2, 2, 1);
    imagesc(adjMat); hold on; axis tight;
    axes = gca; currfig = gcf;
    titleStr = {'LTI Model A From', [num2str(timeWindow(1)), ' to ', num2str(timeWindow(2))]};
    ylabelStr = '';
    xlabelStr = '';
    colorbarStr = 'State Transition Vals';
    cbar = colorbar(); colormap('jet'); set(axes, 'box', 'off'); set(axes, 'YDir', 'normal');
    labelColorbar(cbar, colorbarStr, FONTSIZE);
    labelBasicAxes(axes, titleStr, ylabelStr, xlabelStr, FONTSIZE);
    axy = axes.YAxis;
    ylabcoords = axy.Label.Position;
    text(ylabcoords(1), ylabcoords(2), ylabcoords(3), 'Electrodes', 'FontSize', FONTSIZE, 'Rotation', 90);
    axy.TickValues = 1:N;
    axy.TickLabels = included_labels;
    axy.FontSize = 5;
    axes.XTickLabel = [];
    
    %% Plot Eigenspectrum
    secfig = subplot(2, 2, 2);
    
    chan = 1;
    for chan=1:N
        ek = [zeros(chan-1, 1); 1; zeros(N-chan,1)]; % unit column vector at this node
        del_table = final_data.del_table;
        del = del_table{chan, randIndice};
        if size(del, 2) == 1 || size(del, 1) == 1
            del = reshape(del, N, 1);
            temp = del*ek';
            test = adjMat + temp;
            a =plot(real(eig(test)), imag(eig(test)), 'r*', 'MarkerSize', 5); hold on;
        else
            for i=1:size(del,2)
                del_temp = reshape(squeeze(del(:,i)), N, 1);
                temp = del_temp*ek';
                test = adjMat + temp;
                plot(real(eig(test)), imag(eig(test)), 'r*', 'MarkerSize', 5); hold on;
            end
        end
    end
    b = plot(real(eig(adjMat)), imag(eig(adjMat)), 'b*', 'MarkerSize', 5); hold on;
    legend([a, b], 'Perturbed', 'Original')
    axes = gca;
    xlabelStr = 'Real Part';
    ylabelStr = 'Imag Part';
    titleStr = ['Eigenspectrum of ', perturbationType, ' Perturbation'];
    labelBasicAxes(axes, titleStr, ylabelStr, xlabelStr, FONTSIZE);
    xlim([-radius radius]);
    ylim([-radius radius]);
    plot(get(axes, 'XLim'), [0 0], 'k');
    plot([0 0], get(axes, 'YLim'), 'k');
    th = 0:pi/50:2*pi;
    r = 1; x = 0; y = 0;
    xunit = r * cos(th) + x;
    yunit = r * sin(th) + y;
    h = plot(xunit, yunit);

    %% Plot Minimum Norm Perturbation
    thirdfig = subplot(2,2, [3,4]);
    imagesc(minPerturb_time_chan); hold on; axis tight;
    axes = gca; currfig = gcf;
    cbar = colorbar(); colormap('jet'); set(axes, 'box', 'off'); set(axes, 'YDir', 'normal');
    XLim = get(gca, 'xlim'); XLowerLim = XLim(1); XUpperLim = XLim(2);
    colorbarStr = 'Minimum Norm Perturbation';
    xlabelStr = 'Time (sec)';
    ylabelStr = 'Electrodes';
    titleStr = {patient, ['Min Norm ', perturbationType, ' Perturbation WRT Seizure']};
    
    labelColorbar(cbar, colorbarStr, FONTSIZE);
    set(cbar.Label, 'Rotation', 270);
    % create title string and label the axes of plot
    labelBasicAxes(axes, titleStr, ylabelStr, xlabelStr, FONTSIZE);
    ylab = axes.YLabel;
    
    % set x/y ticks and increment xlim by 1
    xTickStep = (XUpperLim - XLowerLim) / 10;
    timeStart = -seizureStart / frequency_sampling;
    timeEnd = (timePoints(end,2) - seizureStart) / frequency_sampling;
    xTicks = round(timeStart: (timeEnd-timeStart)/10 :timeEnd);
%     yTicks = [1, 5:5:size(minPerturb_time_chan,1)];
%     set(gca, 'YTick', yTicks);
    set(gca, 'XTick', (XLowerLim+0.5 : xTickStep : XUpperLim+0.5)); set(gca, 'XTickLabel', xTicks); % set xticks and their labels
    xlim([XLowerLim, XUpperLim+1]);

    % plot start star's for the different clinical annotations
    figIndices = {ezone_indices, earlyspread_indices, latespread_indices};
    colors = {[1 0 0], [1 .5 0], [0 0 1]};
    for i=1:length(figIndices)
        if sum(figIndices{i})>0
            xLocations = repmat(XUpperLim+1, length(figIndices{i}), 1);
            plotAnnotatedStars(fig, xLocations, figIndices{i}, colors{i});
        end
    end
    
    try
        plot([seizureMarkStart seizureMarkStart], get(gca, 'ylim'), 'k', 'MarkerSize', 4);
        plot([seizureMarkEnd seizureMarkEnd], get(gca, 'ylim'), 'k', 'MarkerSize', 4);
    catch e
        disp(e)
    end
    
    
    % plot the different labels on different axes to give different colors
    plotOptions = struct();
    plotOptions.YAXFontSize = YAXFONTSIZE;
    plotOptions.FONTSIZE = FONTSIZE;
    plotIndices(currfig, plotOptions, y_indices, included_labels, ...
                                ezone_indices, ...
                                earlyspread_indices, ...
                                latespread_indices)
    % make sure the cbar label is find
    pause(0.001);
    cbarPos = cbar.Label.Position;
    cbar.Label.Position = [cbarPos(1)*1.45 cbarPos(2) cbarPos(3)]; % moving it after resizing
    
                            
%     currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
    currfig.Position = [1986           1        1535        1121];
    ylabPos = ylab.Position;
    ylab.Position = [ylabPos(1)*3 ylabPos(2) ylabPos(3)]; % move ylabel to the left

    patDir = fullfile(figDir, patient_id);
    if ~exist(patDir, 'dir')
        mkdir(patDir);
    end
    toSaveFigFile = fullfile(patDir, strcat(patient, '_preplots'));
    
    %%%%% CONVERT TO PDF
    print(toSaveFigFile, '-dpng', '-r0')
%     print(toSaveFigFile, '-dpng');
    close all
end

% function h = circle(x,y,r)
% hold on
% th = 0:pi/50:2*pi;
% xunit = r * cos(th) + x;
% yunit = r * sin(th) + y;
% h = plot(xunit, yunit);
% hold off
% end