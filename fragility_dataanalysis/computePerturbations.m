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
TYPE_CONNECTIVITY = perturb_args.TYPE_CONNECTIVITY;

sigma = sqrt(radius^2 - w_space.^2); % move to the unit circle 1, for a plethora of different radial frequencies
b = [0; 1];                          % initialize for perturbation computation later

% get list of mat files
matFile = fullfile(adjDir, strcat(patient, '_adjMat_', lower(TYPE_CONNECTIVITY), '.mat'));

data = load(matFile);
adjmat_struct = data.adjmat_struct;

timePoints = adjmat_struct.timePoints;
ezone_labels = adjmat_struct.ezone_labels;
earlyspread_labels = adjmat_struct.earlyspread_labels;
latespread_labels = adjmat_struct.latespread_labels;
resection_labels = adjmat_struct.resection_labels;
all_labels = adjmat_struct.all_labels;
seizure_start = adjmat_struct.seizure_start;
seizure_end = adjmat_struct.seizure_end;
winSize = adjmat_struct.winSize;
stepSize = adjmat_struct.stepSize;
frequency_sampling = adjmat_struct.frequency_sampling;

info.ezone_labels = ezone_labels;
info.earlyspread_labels = earlyspread_labels;
info.latespread_labels = latespread_labels;
info.resection_labels = resection_labels;
info.all_labels = all_labels;
info.seizure_start = seizure_start;
info.seizure_end = seizure_end;
info.winSize = winSize;
info.stepSize = stepSize;
info.frequency_sampling = frequency_sampling;

num_channels = size(adjmat_struct.adjMat, 3);
num_times = size(adjmat_struct.adjMat, 1);

%% 1: Begin Perturbation Analysis
%- initialize matrices for colsum, rowsum, and minimum perturbation\
minPerturb_time_chan = zeros(num_channels, num_times);
del_table = cell(num_channels, num_times);

colsum_time_chan = zeros(num_channels, num_times);
rowsum_time_chan = zeros(num_channels, num_times);

% loop through mat files and open them upbcd
iTime = 1; % time pointer for heatmaps
tic; % start counter
for i=1:length(matFiles) % loop through each adjacency matrix
    %%- 01: Extract File and Information
    data = load(matFile);
    adjmat_struct = data.adjmat_struct;
    adjMats = adjmat_struct.adjMats;
    
    for j=1:num_times % loop through each time window of adjacency matrix
        adjMat = adjMats(j,:,:); % get current adjacency matrix
        
        if max(abs(eig(adjMat))) > radius
            logfile = strcat(patient, '_perturbation_log.txt');
            fid = fopen(logfile, 'w');
            fprintf(fid, '%6s, %f \n', ['This patient has eigenvalue > radius, check it!', ...
                patient, '_', num2str(frequency_sampling), '_', num2str(winSize), '_', num2str(stepSize)]);
            fprintf(fid, '%6s \n', ['on this number of the mat files, ' num2str(i)]);
            fclose(fid);
        elseif max(abs(eig(adjMat))) - radius < 1e-8
            logfile = strcat(patient, '_equaleigenvals_perturbation_log.txt');
            fid = fopen(logfile, 'w');
            fprintf(fid, '%6s, %f \n', ['This patient has eigenvalue == radius, check it!', ...
                patient, '_', num2str(frequency_sampling), '_', num2str(winSize), '_', num2str(stepSize)]);
            fprintf(fid, '%6s \n', ['on this number of the mat files, ' num2str(i)]);
            fclose(fid);
        end
        
        %%- 02:Compute Minimum Norm Perturbation
        % determine which indices have eigenspectrums that are stable
        max_eig = max(abs(eig(adjMat)));
        if (max_eig < radius) % this is a stable eigenspectrum
            N = size(adjMat, 1); % number of rows
            del_size = zeros(N, length(w_space));
            del_temp = cell(length(w_space));

            %%- grid search over sigma and w for each row to determine, what is
            %%- the min norm perturbation
            for iNode=1:N
                ek = [zeros(iNode-1, 1); 1; zeros(N-iNode,1)]; % unit column vector at this node
                A = adjMat; 

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
            colsum_time_chan(:, iTime) = sum(adjMat, 1);
            rowsum_time_chan(:, iTime) = sum(adjMat, 2);

            % update pointer for the fragility heat map
            iTime = iTime+1;
            disp(['On ', num2str(i), ' out of ', num2str(length(matFiles)), ' to analyze.']);
        else
            disp(['max eigenvalue for ']);
        end
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