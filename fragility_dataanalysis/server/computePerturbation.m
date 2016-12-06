function computePerturbation(patient_id, seizure_id, perturb_args)%, clinicalLabels)
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
frequency_sampling = 1000;
patient = strcat(patient_id, seizure_id);%     'pt14sz1' 'pt14sz2' 'pt14sz3' 'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
%     'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt17sz1' 'pt17sz2',...

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
matFile = fullfile(adjDir, strcat(patient, '_adjmats_', lower(TYPE_CONNECTIVITY), '.mat'));
matFiles = [matFile];

data = load(matFile);
adjmat_struct = data.adjmat_struct;%     'pt14sz1' 'pt14sz2' 'pt14sz3' 'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
%     'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt17sz1' 'pt17sz2',...


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
try
frequency_sampling = adjmat_struct.frequency_sampling;
catch e
    disp(e)
end
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

num_channels = size(adjmat_struct.adjMats, 3);
N = num_channels;
num_times = size(adjmat_struct.adjMats, 1);

%% 1: Begin Perturbation Analysis
%- initialize matrices for colsum, rowsum, and minimum perturbation\
minPerturb_time_chan = zeros(num_channels, num_times);
del_table = cell(num_channels, num_times);

colsum_time_chan = zeros(num_channels, num_times);
rowsum_time_chan = zeros(num_channels, num_times);

% loop through mat files and open them upbcd
tic; % start counter
%%- 01: Extract File and Information
data = load(matFile);
adjmat_struct = data.adjmat_struct;
adjMats = adjmat_struct.adjMats;

parfor iTime=1:num_times % loop through each time window of adjacency matrix
    adjMat = squeeze(adjMats(iTime,:,:)); % get current adjacency matrix

    if max(abs(eig(adjMat))) > radius
        logfile = strcat(patient, '_perturbation_log.txt');
        fid = fopen(logfile, 'w');
        fprintf(fid, '%6s, %f \n', ['This patient has eigenvalue > radius, check it!', ...
            patient, '_', num2str(frequency_sampling), '_', num2str(winSize), '_', num2str(stepSize)]);
        fclose(fid);
    elseif max(abs(eig(adjMat))) - radius < 1e-8
        logfile = strcat(patient, '_equaleigenvals_perturbation_log.txt');
        fid = fopen(logfile, 'w');
        fprintf(fid, '%6s, %f \n', ['This patient has eigenvalue == radius, check it!', ...
            patient, '_', num2str(frequency_sampling), '_', num2str(winSize), '_', num2str(stepSize)]);
        fclose(fid);
    end

    %%- 02:Compute Minimum Norm Perturbation
    % determine which indices have eigenspectrums that are stable
    max_eig = max(abs(eig(adjMat)));
    if (max_eig < radius) % this is a stable eigenspectrum
        % store min delta for each electrode X w
        del_size = zeros(N, length(w_space));   % store min_norms
        del_temp = cell(length(w_space));       % store all min_norm vectors

        %%- grid search over sigma and w for each row to determine, what is
        %%- the min norm perturbation
        for iNode=1:N % 1st loop through each electrode
            ek = [zeros(iNode-1, 1); 1; zeros(N-iNode,1)]; % unit column vector at this node
            A = adjMat; 

            for iW=1:length(w_space) % 2nd loop through frequencies
                lambda = sigma(iW) + 1i*w_space(iW);

                % compute row, or column perturbation
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

                %- extract real and imaginary components
                %- create B vector of constraints
                Cr = real(C);  Ci = imag(C);
                if strcmp(perturbationType, 'R')
                    B = [Ci; Cr];
                else
                    B = [Ci, Cr]';
                end

                % compute perturbation necessary
                if w_space(iW) ~= 0
                    del = B'*inv(B*B')*b;
                else
                    del = C./(norm(C)^2);
                end

                % store the l2-norm of the perturbation
                del_size(iNode, iW) = norm(del); 
                del_temp{iW} = del;
            end

            %%- 03: Store Results min norm perturbation
            % store minimum perturbation, for each node at a certain time point
            min_index = find(del_size(iNode,:) == min(del_size(iNode, :)),1);
            minPerturb_time_chan(iNode, iTime) = del_size(iNode, min_index);
            del_table(iNode, iTime) = del_temp(min_index);
        end % end of loop through channels

        % update pointer for the fragility heat map
        disp(['On ', num2str(iTime), ' out of ', num2str(num_times), ' to analyze.']);
    else
        disp(['max eigenvalue problem for ', num2str(iTime), ' time point.']);
    end
end % end of loop through time
toc

%% 3. Compute fragility rankings per column by normalization
fragility_rankings = zeros(size(minPerturb_time_chan,1),size(minPerturb_time_chan,2));
for i=1:size(minPerturb_time_chan,1)      % loop through each channel
    for j=1:size(minPerturb_time_chan, 2) % loop through each time point
        fragility_rankings(i,j) = (max(minPerturb_time_chan(:,j)) - minPerturb_time_chan(i,j)) ...
                                    / max(minPerturb_time_chan(:,j));
    end
end

info.del_table = del_table;

% initialize struct to save
perturbation_struct = struct();
perturbation_struct.info = info; % meta data info
perturbation_struct.minNormPertMat = minPerturb_time_chan;
perturbation_struct.timePoints = timePoints;
perturbation_struct.fragility_rankings = fragility_rankings;

filename = strcat(patient, '_', perturbationType, 'perturbation_', lower(TYPE_CONNECTIVITY), '.mat');
save(fullfile(toSaveFinalDataDir, filename), 'perturbation_struct');
end