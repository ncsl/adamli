function computeEZTPerturbations(patient_id, seizure_id, winSize, stepSize, ...
    included_channels, ezone_labels, earlyspread_labels, latespread_labels, ...
    w_space, radius, perturbationType)
if nargin == 0
    addpath('./fragility_library/');
    patient_id = '005';
    seizure_id = 'seiz001';
    radius = 1.1;
    w_space = linspace(-1, 1, 101);
    perturbationType = 'R';
    winSize = 500;
    stepSize = 500;
    included_channels = 0;
    
    if strcmp(patient_id, '007')
        included_channels = [];
        ezone_labels = {'O7', 'E8', 'E7', 'I5', 'E9', 'I6', 'E3', 'E2',...
            'O4', 'O5', 'I8', 'I7', 'E10', 'E1', 'O6', 'I1', 'I9', 'E6',...
            'I4', 'O3', 'O2', 'I10', 'E4', 'Y1', 'O1', 'I3', 'I2'}; %pt1
        earlyspread_labels = {};
        latespread_labels = {};
    elseif strcmp(patient_id, '005')
        included_channels = [];
        ezone_labels = {'U4', 'U3', 'U5', 'U6', 'U8', 'U7'}; 
        earlyspread_labels = {};
         latespread_labels = {};
    elseif strcmp(patient_id, '019')
        included_channels = [];
        ezone_labels = {'I5', 'I6', 'B9', 'I9', 'T10', 'I10', 'B6', 'I4', ...
            'T9', 'I7', 'B3', 'B5', 'B4', 'I8', 'T6', 'B10', 'T3', ...
            'B1', 'T8', 'T7', 'B7', 'I3', 'B2', 'I2', 'T4', 'T2'}; 
        earlyspread_labels = {};
         latespread_labels = {}; 
     elseif strcmp(patient_id, '045') % FAILURES
        included_channels = [];
        ezone_labels = {'X2', 'X1'}; %pt2
        earlyspread_labels = {};
         latespread_labels = {}; 
      elseif strcmp(patient_id, '090') % FAILURES
        included_channels = [];
        ezone_labels = {'N2', 'N1', 'N3', 'N8', 'N9', 'N6', 'N7', 'N5'}; 
        earlyspread_labels = {};
         latespread_labels = {}; 
    end
    patient_id = 'EZT005';
end

%% 0: Initialize All Necessary Vars and Dirs
sigma = sqrt(radius^2 - w_space.^2); % move to the unit circle 1, for a plethora of different radial frequencies
b = [0; 1];
patient = strcat(patient_id, '_', seizure_id);

%- initialize directories and labels
adjDir = fullfile(strcat('./adj_mats_win', num2str(winSize), ...
    '_step', num2str(stepSize)));

%- set file path for the patient file 
dataDir = './data/';
patient_eeg_path = fullfile('./data/Seiz_Data/', patient_id, patient);
eegdata = load(patient_eeg_path);
labels = eegdata.elec_labels;

%% 1: Read in Data and Initialize Variables For Analysis
matFiles = dir(fullfile(adjDir,patient, '*.mat'));
matFiles = {matFiles.name};         % cell array of all mat file names in order
matFiles = natsortfiles(matFiles);  % 3rd party - natural sorting order

% define cell function to search for the EZ labels
cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));
ezone_indices = zeros(length(ezone_labels),1);
for i=1:length(ezone_labels)
    indice = cellfun(cellfind(ezone_labels{i}), labels, 'UniformOutput', 0);
    indice = [indice{:}];
    test = 1:length(labels);
    if ~isempty(test(indice))
        ezone_indices(i) = test(indice);
    end
end
earlyspread_indices = zeros(length(earlyspread_labels),1);
for i=1:length(earlyspread_labels)
    indice = cellfun(cellfind(earlyspread_labels{i}), labels, 'UniformOutput', 0);
    indice = [indice{:}];
    test = 1:length(labels);
    if ~isempty(test(indice))
        earlyspread_indices(i) = test(indice);
    end
end
earlyspread_indices(earlyspread_indices==0) =  [];
latespread_indices = zeros(length(latespread_labels),1);
if ~isempty(latespread_labels)
    for i=1:length(latespread_labels)
        indice = cellfun(cellfind(latespread_labels{i}), labels, 'UniformOutput', 0);
        indice = [indice{:}];
        test = 1:length(labels);
        if ~isempty(test(indice))
            latespread_indices(i) = test(indice);
        end
    end
end

%- initialize matrices for colsum, rowsum, and minimum perturbation
timeRange = length(matFiles);               % the number of mat files to analyze
colsum_time_chan = zeros(length(labels), ... % colsum at each time/channel
                    timeRange);
rowsum_time_chan = zeros(length(labels), ... % rowsum at each time/channel
                    timeRange);
minPerturb_time_chan = zeros(length(labels), ... % fragility at each time/channel
                    timeRange);
timeIndices = [];             % vector to store time indices (secs) of each window of data

% loop through mat files and open them upbcd
iTime = 1; % time pointer for heatmaps
tic; % start counter
for i=1:length(matFiles) % loop through each adjacency matrix
    %%- 01: Extract File and Information
    matFile = matFiles{i};
    data = load(fullfile(adjDir,patient, matFile));
    data = data.data;
    
    theta_adj = data.theta_adj;
    timewrtSz = data.timewrtSz / 1000; % in seconds
    index = data.index;
    if (i == 1) % only set these variables once -> save time in seconds
        timeStart = data.timeStart / 1000;
        timeEnd = data.timeEnd / 1000;
        seizureTime = data.seizureTime / 1000;
    end
    % store all the time indices with respect to seizure
    timeIndices = [timeIndices; timewrtSz];
    
    %%- 02:Compute Minimum Norm Perturbation
    % determine which indices have eigenspectrums that are stable
    max_eig = max(abs(eig(theta_adj)));
    if (max_eig < radius) % this is a stable eigenspectrum
        N = size(theta_adj, 1); % number of rows
        del_size = zeros(N, length(w_space));
        
        %%- grid search over sigma and w for each row to determine, what is
        %%- the min norm perturbation
        for iNode=1:N
            ek = [zeros(iNode-1, 1); 1; zeros(N-iNode,1)]; % unit column vector at this node
            A = theta_adj; 
            
            for iW=1:length(w_space) % loop through frequencies
                lambda = sigma(iW) + 1i*w_space(iW);

                % row perturbation inversion
                if (perturbationType == 'R')
                    C = ek'*inv(A - lambda*eye(N));  
                    
                    if size(C,1) > 1
                        size(C)
                        disp('Could be an error in setting Row and Col Pert.');
                        k = waitforbuttonpress
                    end
                elseif (perturbationType == 'C')
                    C = inv(A - lambda*eye(N))*ek; 
                    if size(C,2) > 1
                        size(C)
                        disp('Could be an error in setting Row and Col Pert.');
                        k = waitforbuttonpress
                    end
                end
                Cr = real(C);  Ci = imag(C);
                if strcmp(perturbationType, 'R')
                    B = [Ci; Cr];
                else
                    B = [Ci, Cr]';
                end

%                 del = B'*inv(B*B')*b;
%                 
                if w_space(iW) ~= 0
                    % compute perturbation necessary
                    del = B'*inv(B*B')*b;
                else
                    del = C./(norm(C)^2);
                end
                
                % store the l2-norm of the perturbation
                del_size(iNode, iW) = norm(del); 
            end
            % store minimum perturbation, for each node at a certain time point
            minPerturb_time_chan(iNode, iTime) = min(del_size(iNode,:));
        end % end of loop through channels
        
        %%- 03: Store Results (colsum, rowsum, perturbation,
        % store col/row sum of adjacency matrix
        colsum_time_chan(:, iTime) = sum(theta_adj, 1);
        rowsum_time_chan(:, iTime) = sum(theta_adj, 2);
        
        % update pointer for the fragility heat map
        iTime = iTime+1;
        disp(['On ', num2str(i), ' out of ', num2str(length(matFiles)), ' to analyze.']);
    end
end
toc

%% 3. Compute fragility rankings per column by normalization
fragility_rankings = zeros(size(minPerturb_time_chan,1),size(minPerturb_time_chan,2));
for i=1:size(minPerturb_time_chan,1)      % loop through each channel
    for j=1:size(minPerturb_time_chan, 2) % loop through each time point
        fragility_rankings(i,j) = (max(minPerturb_time_chan(:,j)) - minPerturb_time_chan(i,j)) ...
                                    / max(minPerturb_time_chan(:,j));
    end
end

%- make processed file dir, if not saved yet.
if ~exist(fullfile(adjDir, strcat(perturbationType, '_finaldata')), 'dir')
    mkdir(fullfile(adjDir,  strcat(perturbationType, '_finaldata')));
end
save(fullfile(adjDir, strcat(perturbationType, '_finaldata'), strcat(patient,'final_data.mat')),...
 'minPerturb_time_chan', 'colsum_time_chan', 'rowsum_time_chan', 'fragility_rankings');

end