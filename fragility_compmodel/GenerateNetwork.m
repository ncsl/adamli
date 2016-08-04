%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION: generateNetwork
% DESCRIPTION: Used to generate an initialized weight matrix between the
% inhibitory and excitatory neurons. This could follow the Master Equation
% simulation using Gillespie Algorithm.
%   We = 1/2 * (Ws + Wd)
%   Wi = 1/2 * (Ws - Wd)
%
% INPUT:
% - N = the number of neurons per network
% - frac =
% OUTPUT:
% - We = the synaptic connectivity matrix for the excitatory network
% - Wi = the synaptic connectivity matrix for the inhibitory network
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [We, Wi] = generateNetwork(N, frac)
% N = 3;
% frac = 1;
scale = sqrt(N);
mag = 1;

% define Ws
Ws = zeros(N, N);
ind = ceil(N*N*rand(ceil(N*N*frac),1)); % return a random N*N vector from 1:N*N
ind = unique(ind);                      % get the unique indices
val = randn(length(ind), 1);            % get normally distributed numbers
Ws(ind) = val;                          % initialize weights with normally distributed parameters

% define Wd
Wd = zeros(N, N);
ind = ceil(N*N*rand(ceil(N*N*frac),1)); % return a random N*N vector from 1:N*N
ind = unique(ind);                      % get the unique indices
val = randn(length(ind), 1);            % get normally distributed numbers
Wd(ind) = val;                          % initialize weights with normally distributed parameters

%%- OPTIONAL: scale weighting matrices
Ws = mag*Ws*scale;
Wd = mag*Wd*scale;

% i. compute We and Wi and 
% ii. remove negative weights because there is no biological meaning behind them
% iii. set diagonals to 0
We = (Ws+Wd) / 2;
Wi = (Ws-Wd) / 2;
We(We<0) = 0;
Wi(Wi<0) = 0;
We(logical(eye(N))) = 0;
Wi(logical(eye(N))) = 0;
% figure;
% subplot(211);
% imagesc(We)
% colorbar(); colormap('jet');
% subplot(212)
% imagesc(Wi)
% colorbar(); colormap('jet');
end