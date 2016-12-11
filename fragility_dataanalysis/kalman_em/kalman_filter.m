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
% function [xnn, pnn] = kalman_filter(parameters, y)
numChans = 10;
y = randn(numChans, 500);
parameters = struct();
parameters.stateQ =   diag(randn(numChans^2));
parameters.observationR = randn(numChans);
parameters.observationModel = 1;

Q = parameters.stateQ;              % N^2 x N^2 cov matrix of state
R = parameters.observationR;        % N x N cov matrix of observations
H = parameters.observationModel;    % N x N^2 matrix observation model linking state
[N, T] = size(y);

% posterior states and variances
xnn = zeros(N^2, T);
pnn = zeros(N^2, T); 
% prior states and variances
x_priors = repmat([1; zeros(N^2-1, 1)], T);
p_priors = repmat([1; zeros(N^2-1, 1)], T);

% initial seed prior
p_prior = p1;
x_prior = x1;

%% Perform Actual Kalman Filter
for iTrial=1:T
    %%- Store previous priors
    p_priors(:, iTrial) = p_prior;
    x_priors(:, iTrial) = x_prior;
    
    % get current y observation 
    yn = y(:, iTrial);
    
    %%- 01: Compute Kalman Gain K(t)
    K = p_prior;
    
    %%- 02: Compute Posteriors and Store
    p_posterior = 1;
    x_posterior = x_prior;
    xnn(:, iTrial) = x_posterior;
    pnn(:, iTrial) = p_posterior;
    
    %%- 03: Forward Projection Using State Equation
    % new priors
    x_prior = x_prior;
    p_prior = p_prior; 
end

% end