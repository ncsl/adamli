% compute pinv
function x = computePinv(eegMat, observationVector, OPTIONS)
    % step 0: extract options and intialize variables
    l2regularization = OPTIONS.l2regularization;
    [num_chans, num_times] = size(eegMat);
    
    tmpdata = eegMat'; % store transpose of eeg matrix
    
    % step 1: either initialize new H matrix with sparse, or full matrix.
    try
        H = zeros(length(observationVector), num_chans^2);
    catch e
        disp(e)
        H = sparse(length(observationVector, num_chans^2));
    end
    
    % step 2: build up H matrix
    N = 1:num_chans:size(H,1); % step size per row iteration
    H(N, 1:num_chans) = tmpdata(1:end-1,:); % build first C columns

    for iChan=2:num_chans % loop through all C columns
        % row/col indices we want to slice 
        rowInds = N+(iChan-1); 
        colInds = (iChan-1)*num_chans+1 : iChan*num_chans; 
        H(rowInds, colInds) = tmpdata(1:end-1, :);
    end
    
    % H is a sparse matrix, so store it as such
    if ~issparse(H)
        H = sparse(H);
    end
    observationVector = double(observationVector);

    % step 3: Perform least squares - with/without regularization
    % create the reshaped adjacency matrix
    if l2regularization == 0
        x = pinv(H)*observationVector;                                              
    else
        symmetricH = H'*H;
        x = (symmetricH+l2regularization*eye(length(symmetricH))) \ ...
            (H'*observationVector);
    end
end