% Author: Adam Li
% Neuromedical Systems Control Laboratory
% 12/09/2016
%
% This function computes the Kalman smoothedestimates for the expected
% state, variance of state using the forward Kalman filter. This assumes no
% perturbations in the observation model.
% 
%%% Inputs: y - this is the observations (eeg data) N x T
%%%         parameters - struct of our parameter set
%%% Outputs: 
%%%         xnN - this is an N^2 x T array containing the smnoothed estimated Kalman
%%%                expected states
%%%         pnN - this is an N^2 x T array containing the smoothed estimated Kalman
%%%                state variances
%%%
%%%         pnp1nN - this is an N^2 x T array containing the smoothed
%%%         estimated Kalman covariances.
function [xnN, pnN, pnp1nN] = kalman_smoother(xnn, pnn, x_priors, p_priors)
    [N, T] = size(xnn);
    
    % smoothed states and covariance
    xnN = zeros(N^2, T);
    pnN = zeros(N^2, T); 
    pnp1nN = zeros(N^2, T);
    pnp1nN(end) = NaN;
    
    xnN(:,T) = xnn(:,T);
    pnN(:,T) = pnn(:,T);
    for trialNum=N-1:-1:1
        %%- 01: Compute J(t)
        J = pnn(trialNum) / p_priors(trialNum+1);
        
        %%- 02: Compute Backward Smoothed Estimates
        xnN(:, trialNum) = xnn(:, trialNum) + J*(xnN(trialNum+1) - x_priors(trialNum+1));
        pnN(:, trialNum) = pnn(:, trialNum) + J^2*(pnN(trialNum+1) - p_priors(trialNum+1));
        pnp1nN(:, trialNum) = pnN(:, trialNum+1) * J;
    end
end