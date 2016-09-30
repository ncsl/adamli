% function: leastSquaresAdjMat
% Description: Used to compute an adjacency matrix using least squares
% solving of a linear system of equations of a window of ecog data.
% 
% Input:
% 
function serverLeastSquaresAdjMat(i, eeg, metadata) 
    dataStart               = metadata.dataStart;
    num_channels            = metadata.num_channels;
    patient                 = metadata.patient;
    included_channels       = metadata.included_channels;
    frequency_sampling      = metadata.frequency_sampling;
    seizureStart            = metadata.seizureStart;
    seizureEnd              = metadata.seizureEnd;
    adjDir                  = metadata.adjDir;
    preseizureTime          = metadata.preseizureTime;
    postseizureTime         = metadata.postseizureTime;
    winSize                 = metadata.winSize;
    stepSize                = metadata.stepSize;
    ezone_labels            = metadata.ezone_labels;
    earlyspread_labels      = metadata.earlyspread_labels;
    latespread_labels       = metadata.latespread_labels;
    
    dataWindow = dataStart + (i-1)*stepSize;
    
    % step 1: extract the data and apply the notch filter. Note that column
    %         #i in the extracted matrix is filled by data samples from the
    %         recording channel #i.
    tmpdata = eeg(:, dataWindow + 1:dataWindow + winSize);
    clear metadata eeg % save space - save ram
    
    % step 2: compute some functional connectivity 
    % linear model: Ax = b; A\b -> x
    b = tmpdata(:); % define b as vectorized by stacking columns on top of another
    b = b(num_channels+1:end); % only get the time points after the first one
    
    tmpdata = tmpdata';
    tic;
    % build up A matrix with a loop modifying #time_samples points and #chans at a time
    A = zeros(length(b), num_channels^2);               % initialize A for speed
    N = 1:num_channels:size(A,1);                       % set the indices through rows
    A(N, 1:num_channels) = tmpdata(1:end-1,:);          % set the first loop
    
    for iChan=2 : num_channels % loop through columns #channels per loop
        rowInds = N+(iChan-1);
        colInds = (iChan-1)*num_channels+1:iChan*num_channels;
        A(rowInds, colInds) = tmpdata(1:end-1,:);
    end
    toc;
    fprintf('%6s \n', 'done');
    % create the reshaped adjacency matrix
    tic;
    theta = A\b;                                                % solve for x, connectivity
    theta_adj = reshape(theta, num_channels, num_channels)';    % reshape fills in columns first, so must transpose
    toc;
    
    %% save the theta_adj made
    fileName = strcat(patient, '_', num2str(i), '.mat');
    
    %- save the data into a struct into a mat file
    %- save the data into a struct into a mat file - time all in
    %milliseconds
    data = struct();
    data.theta_adj = theta_adj;
    data.seizureTime = seizureStart;
    data.seizureEnd = seizureEnd;
    data.winSize = winSize;
    data.stepSize = stepSize;
    data.timewrtSz = dataWindow - seizureStart;
    data.timeStart = seizureStart - preseizureTime*frequency_sampling; %start time of analysis
    data.timeEnd = seizureStart + postseizureTime*frequency_sampling;  %end time of analysis
    data.index = i;
    data.included_channels = included_channels;
    data.ezone_labels = ezone_labels;
    data.earlyspread_labels = earlyspread_labels;
    data.latespread_labels = latespread_labels;
    
    save(fullfile(adjDir, fileName), 'data');
end