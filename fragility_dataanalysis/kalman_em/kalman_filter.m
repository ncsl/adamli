% Author: Adam Li
% Neuromedical Systems Control Laboratory
% 12/09/2016
%
% This function computes the Kalman filter estimates for the expected
% state, variance of state using the forward Kalman filter. This assumes no
% perturbations in the observation model.
% 
%%% Inputs: y - this is the observations (eeg data) N x T
%%%         parameters - struct of our parameter set
%%% Outputs: 
%%%         xnn - this is an N^2 x T array containing the estimated Kalman
%%%                expected states
%%%          Pnn - this is an N^2 x T array containing the estimated Kalman
%%%                state variances
% TEST CODE => COPY AND PASTE IF YOU WANT TO TEST
% numChans = 5;
% A = randn(numChans, numChans);
% Xtemp = A(:);
% 
% %- initialize covariance matrices for state and observation
% Q = diag(randn(length(Xtemp),1));
% Q = Q'*Q;
% R = normrnd(0, rand(numChans, numChans)); 
% R = R'*R;
% 
% Y0 = randn(5,1); % generate initial Y observation matrix
% currentY = Y0;
% 
% X = zeros(numChans^2, 500);
% Y = ones(numChans, 500);
% Y(:, 1) = Y0;
% X(:, 1) = Xtemp;
% currentX = Xtemp;
% for j=2:500 % generate 500 samples of data
%     V = mvnrnd(zeros(1,length(R)), R);
%     W = mvnrnd(zeros(length(Q),1), Q);
%     
%     V = randn(numChans,1);
%     W = randn(numChans^2,1);
%     
% 
%     %- create current H(t)
%     H = zeros(numChans, numChans^2);
%     indices = 1:numChans;
%     H(1, indices) = currentY;
%     for i=2:length(Y0) % loop and create H matrix
%         indices = numChans*(i-1)+1:numChans*(i);
%         H(i,indices) = currentY;
%     end
% 
%     %- simulate Y(t+1)
%     Y(:,j) = H*currentX + V;
% 
%     %- simulate X(t+1)
%     X(:, j) = currentX + W;
%     
%     
%     %- update X/Y
%     currentX = X(:, j);
%     currentY = Y(:, j);  
% end
% 
% % now we have sequence of Y's, use that to reproduce X
% parameters = struct();
% parameters.stateQ = Q;
% parameters.observationR = R;
% parameters.p1 = ones(numChans^2);
% parameters.x1 = ones(numChans^2,1);
% [xnn, pnn] = kalman_filter(parameters, Y);

function [xnn, pnn] = kalman_filter(parameters, y)
    % initialize parameters
    Q = parameters.stateQ;              % N^2 x N^2 cov matrix of state
    R = parameters.observationR;        % N x N cov matrix of observations
    p1 = parameters.p1;
    x1 = parameters.x1;
    [N, T] = size(y);
    numChans = N;
    
    % posterior states and variances
    xnn = zeros(N^2, T);
    pnn = zeros(N^2,T); 
    % prior states and variances
    x_priors = repmat([1; zeros(N^2-1, 1)], 1, T);
    p_priors = repmat([1; zeros(N^2-1, 1)], 1, T);

%     x_priors = 
    
    % initial seed prior
    p_prior = p1;
    x_prior = x1;

    %% Perform Actual Kalman Filter
    for iTrial=1:T
        %%- Store previous priors
        p_priors(:, :, iTrial) = p_prior;
        x_priors(:, iTrial) = x_prior;

        % get current y observation 
        yn = y(:, iTrial);

        if iTrial ~= 1
            %- create current H(t)
            H = zeros(numChans, numChans^2);
            indices = 1:numChans;
            H(1, indices) = yn;
            for i=2:length(yn) % loop and create H matrix
                indices = numChans*(i-1)+1:numChans*(i);
                H(i,indices) = yn;
            end

            %%- 01: Compute Kalman Gain K(t)
            K = p_prior*H'/(H*p_prior*H' + R);
%             numer = (p_prior*H');
%             denom = (H*p_prior*H' + R);
%             
%             size(numer)
%             size(denom)
            
            %%- 02: Compute Posteriors and Store
            p_posterior = (eye(N^2) - K*H) * p_prior;
            x_posterior = x_prior + K*(yn - H*x_prior);
            xnn(:, iTrial) = x_posterior;
            pnn(:,:, iTrial) = p_posterior;

            %%- 03: Forward Projection Using State Equation
            % x_prior stays the same, just with white noise
            p_prior = p_prior + Q; 
        end
    end
end

