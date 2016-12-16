function serverComputePerturbations(patient_id, seizure_id, currentWin, adjMat, perturb_args)
patient = strcat(patient_id, seizure_id);

%% 0: Extract Vars and Initialize Parameters
perturbationType = perturb_args.perturbationType;
w_space = perturb_args.w_space;
radius = perturb_args.radius;
tempDir = perturb_args.toSaveFinalDataDir;

sigma = sqrt(radius^2 - w_space.^2); % move to the unit circle 1, for a plethora of different radial frequencies
b = [0; 1];                          % initialize for perturbation computation later

% get the number of channels and time points
N = size(adjMat, 1);

%% 1: Begin Perturbation Analysis
%- initialize matrices for colsum, rowsum, and minimum perturbation\
minPerturb_time_chan = zeros(N,1);
del_table = cell(N,1);

% loop through mat files
tic; % start counter

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

            % store the l2-norm of the perturbation vector
            del_size(iNode, iW) = norm(del); 
            del_temp{iW} = del;
        end

        %%- 03: Store Results min norm perturbation
        % store minimum perturbation, for each node at a certain time point
        min_index = find(del_size(iNode,:) == min(del_size(iNode, :)),1);
        minPerturb_time_chan(iNode) = del_size(iNode, min_index);
        del_table(iNode) = del_temp(min_index);
    end % end of loop through channels

    % update pointer for the fragility heat map
    disp(['On ', num2str(iTime), ' out of ', num2str(num_times), ' to analyze.']);
else
    disp(['max eigenvalue problem for ', num2str(iTime), ' time point.']);
end


%% 3. Compute fragility rankings per column by normalization
fragility_rankings = zeros(size(minPerturb_time_chan,1),1);
for i=1:size(minPerturb_time_chan,1)      % loop through each channel
    fragility_rankings(i) = (max(minPerturb_time_chan) - minPerturb_time_chan(i)) ...
                                / max(minPerturb_time_chan);
end

% initialize struct to save
perturbation_struct = struct();
perturbation_struct.del_table = del_table;
perturbation_struct.minNormPertMat = minPerturb_time_chan;
perturbation_struct.fragility_rankings = fragility_rankings;

% display a message for the user
disp(['Finished: ', num2str(currentWin)]);

% save the file in temporary dir
fileName = strcat(patient, '_pert_', num2str(currentWin));
save(fullfile(tempDir, fileName), 'perturbation_struct');
end