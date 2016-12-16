% TEST CODE => COPY AND PASTE IF YOU WANT TO TEST
numChans = 3;
A = randn(numChans, numChans);
% A = diag(randn(numChans));
Xtemp = A(:);
%- initialize covariance matrices for state and observation
Q = diag(randn(length(Xtemp),1));
Q = Q'*Q;
R = normrnd(0, rand(numChans, numChans)); 
R = R'*R;

Y0 = randn(numChans,1); % generate initial Y observation matrix
currentY = Y0;

X = zeros(numChans^2, 500);
Y = ones(numChans, 500);
Y(:, 1) = Y0;
X(:, 1) = Xtemp;
currentX = Xtemp;
for j=2:500 % generate 500 samples of data
    V = mvnrnd(zeros(length(R),1), R);
    W = mvnrnd(zeros(length(Q),1), Q);
    
%     V = randn(numChans,1);
%     W = randn(numChans^2,1);
%     

    %- create current H(t)
    H = zeros(numChans, numChans^2);
    indices = 1:numChans;
    H(1, indices) = currentY;
    for i=2:length(Y0) % loop and create H matrix
        indices = numChans*(i-1)+1:numChans*(i);
        H(i,indices) = currentY;
    end

    %- simulate Y(t+1)
    Y(:,j) = H*currentX + V;

    %- simulate X(t+1)
    X(:, j) = currentX + W;
    
    
    %- update X/Y
    currentX = X(:, j);
    currentY = Y(:, j);  
end

% now we have sequence of Y's, use that to reproduce X
parameters = struct();
parameters.stateQ = Q;
parameters.observationR = R;
parameters.p1 = ones(numChans^2);
parameters.x1 = ones(numChans^2,1);
[xnn, pnn] = kalman_filter(parameters, Y);
