%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION: Jacobian
% DESCRIPTION: Used to compute the jacobian
% J = f'(W'*p + h) * W * (1-p) - diag(alpha + f(W'*p + h))
%
% INPUT:
% - alpha = refractory period
% - beta = weights on Jacobian
% - W = We - Wi is the resulting synaptic weight matrix, with negative
% values corresponding to inhibition and positive weights to excitation
% - h = the synaptic inputs into a cell
% - link = the corresponding response function (e.g. 'tanh')
%
% OUTPUT:
% - J
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function J = Jacobian(alpha, beta, W, p, h, link)
    s = W*p + h; % the input to nodes
    F = ResponseFunction(s, beta, link, 0);  % get response function
    dF = ResponseFunction(s, beta, link, 1); % get the first derivative response function
    
    n = length(p); % get the number of nodes for Jacobian
    
    % get the general form of Jacobian from eqn. 2.29b
    J = repmat(dF, [1 n])  .*W .*repmat(1-p, [1 n]) - diag(F+alpha);
end