%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION: computePerturbations
% DESCRIPTION: This function takes adjacency matrices and computes the
% minimum l2-norm perturbation required to destabilize the system.
% 
% INPUT:
% - patient_id = The id of the patient (e.g. pt1, JH105, UMMC001)
% - seizure_id = the id of the seizure (e.g. sz1, sz3)
% - w_space = the frequency space on unit disc that we want to search over
% - radius = the radius of disc that we want to perturb eigenvalues to
% - perturbationType = 'R', or 'C' for row or column perturbation
% 
% OUTPUT:
% - None, but it saves a mat file for the patient/seizure over all windows
% in the time range -> adjDir/final_data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function computePerturbations(patient_id, seizure_id, perturb_args)%, clinicalLabels)
if nargin == 0
    patient_id = 'pt1';
    seizure_id = 'sz2';
    radius = 1.1;
    w_space = linspace(-1, 1, 101);
    perturbationType = 'R';
    winSize = 500;
    stepSize = 500;
    included_channels = 0;
end
patient = strcat(patient_id, seizure_id);
%% 0: Extract Vars and Initialize Parameters
perturbationType = perturb_args.perturbationType;
w_space = perturb_args.w_space;
radius = perturb_args.radius;
adjDir = perturb_args.adjDir;
toSaveFinalDataDir = perturb_args.toSaveFinalDataDir;
included_channels = perturb_args.included_channels;
num_channels = perturb_args.num_channels
frequency_sampling = perturb_args.frequency_sampling;
% winSize = perturb_args.winSize;
% stepSize = perturb_args.

sigma = sqrt(radius^2 - w_space.^2); % move to the unit circle 1, for a plethora of different radial frequencies
b = [0; 1];                          % initialize for perturbation computation later

matFiles = dir(fullfile(adjDir, '*.mat'));
matFiles = {matFiles.name};         % cell array of all mat file names in order
matFiles = natsortfiles(matFiles);  % 3rd party - natural sorting order

%% 1: Begin Perturbation Analysis
%- initialize matrices for colsum, rowsum, and minimum perturbation
timeRange = length(matFiles);               % the number of mat files to analyze
colsum_time_chan = zeros(num_channels, ... % colsum at each time/channel
                                                timeRange);
rowsum_time_chan = zeros(num_channels, ... % rowsum at each time/channel
                                                timeRange);
minPerturb_time_chan = zeros(num_channels, ... % fragility at each time/channel
                                                timeRange);
timeIndices = [];             % vector to store time indices (secs) of each window of data
del_table = cell(N, timeRange);

% loop through mat files and open them upbcd
iTime = 1; % time pointer for heatmaps
tic; % start counter
for i=1:length(matFiles) % loop through each adjacency matrix
    %%- 01: Extract File and Information
    matFile = matFiles{i};
    data = load(fullfile(adjDir, matFile));
    data = data.data;
    
    theta_adj = data.theta_adj;
    timewrtSz = data.timewrtSz / 1000; % in seconds
    
    index = data.index;
    if (i == 1) % only set these variables once -> save time in seconds
        timeStart = data.timeStart / frequency_sampling;
        timeEnd = data.timeEnd / frequency_sampling;
        seizureStart = data.seizureStart / frequency_sampling;
        seizureEnd = data.seizureEnd / frequency_sampling;
        winSize = data.winSize;
        stepSize = data.stepSize;
    end
    if max(abs(eig(theta_adj))) > radius
        logfile = strcat(patient, '_perturbation_log.txt');
        fid = fopen(logfile, 'w');
        fprintf(fid, '%6s, %f \n', ['This patient has eigenvalue > radius, check it!', ...
            patient, '_', num2str(frequency_sampling), '_', num2str(winSize), '_', num2str(stepSize)]);
        fprintf(fid, '%6s \n', ['on this number of the mat files, ' num2str(i)]);
        fclose(fid);
    elseif max(abs(eig(theta_adj))) - radius < 1e-8
        logfile = strcat(patient, '_equaleigenvals_perturbation_log.txt');
        fid = fopen(logfile, 'w');
        fprintf(fid, '%6s, %f \n', ['This patient has eigenvalue == radius, check it!', ...
            patient, '_', num2str(frequency_sampling), '_', num2str(winSize), '_', num2str(stepSize)]);
        fprintf(fid, '%6s \n', ['on this number of the mat files, ' num2str(i)]);
        fclose(fid);
    end
    % store all the time indices with respect to seizure
    timeIndices = [timeIndices; timewrtSz];
    
    %%- 02:Compute Minimum Norm Perturbation
    % determine which indices have eigenspectrums that are stable
    max_eig = max(abs(eig(theta_adj)));
    if (max_eig < radius) % this is a stable eigenspectrum
        N = size(theta_adj, 1); % number of rows
        del_size = zeros(N, length(w_space));
        del_temp = cell(length(w_space));
        
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

                if w_space(iW) ~= 0
                    % compute perturbation necessary
                    del = B'*inv(B*B')*b;
                else
                    del = C./(norm(C)^2);
                end
                
                % store the l2-norm of the perturbation
                del_size(iNode, iW) = norm(del); 
                del_temp{iW} = del;
            end
            % store minimum perturbation, for each node at a certain time point
            min_index = find(del_size(iNode,:) == min(del_size(iNode, :)),1);
            minPerturb_time_chan(iNode, iTime) = del_size(iNode, min_index);
            del_table(iNode, iTime) = del_temp(min_index);
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

% save some sort of metadata
metadata = struct();
metadata.frequency_sampling = frequency_sampling;
metadata.seizureStart = seizureStart;
metadata.seizureEnd = seizureEnd;
metadata.winSize = winSize;
metadata.stepSize = stepSize;
metadata.radius = radius;
metadata.patient = patient;
metadata.del_table = del_table;

save(fullfile(toSaveFinalDataDir, strcat(patient,'final_data.mat')),...
 'minPerturb_time_chan', 'colsum_time_chan', 'rowsum_time_chan', 'fragility_rankings', 'metadata');
end