%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION: PerturbNetworkRow
% DESCRIPTION: Perturbs the structural connection matrix at a certain row
% (neuron/node).
%
% INPUT:
% - alpha = refractory period
% - beta = weights on Jacobian
% - Wo =
% - p = 
% - h = the synaptic inputs into a cell
% - Jo = the initial functional connectivity from fixed point
% - DelJo = some computed DELTA_j from fixed fixed point
% - link = the corresponding response function (e.g. 'tanh')
% - constrained = 
% OUTPUT:
% - W = the final structure connections 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 function [W J] = PerturbNetworkRow(alpha, beta, Wo, p, h, Jo, DelJo, link, constrained)
    % perturb network at a certain row
%     alpha, beta, W, p, h, J, DelJ{i}, constrained(i)
    N = length(p); % number of nodes in network
    r = find(sum(abs(DelJo) , 2));
    er = [zeros(r-1, 1); 1; zeros(N-r, 1)];
    
    Jp = Jo + DelJo;    % get perturbed functional connectivity
    Jp = Jp(r, :)';     % get a single row from the functional connectivity
    W = Wo;             % initialize structural connectivity
    
    numSteps = 10000;   % number of steps to perform grad descent
    eta = 0.1;          % step size for line search
    gamma = 0.1;        % step size
    
    if (constrained == 0)
        B = null(p');
    elseif (constrained == 1)
        B = null(orth([p er])');
    elseif (constrained == 2)
        I = eye(N);
        E =  I(:,W(r,:)~=0);
        B = null(orth([p null(E')])');
    end
    
    line_search = false; % should we do line search?

    %%- PERFORM CONSTRAINED GRAD DESCENT
    for i=1:numSteps 
        J = Jacobian(alpha, beta, W, p, h, link); % compute the Jacobian at fixed point, with varying W
        G = J(r,:)'-Jp;                           % difference between functional connect and its perturbed row

        %%- compute Jacobian of J, the functional connectivity of row r
        Wr = W(r, :)';
        sr = Wr'*p + h(r);
        
        % initialize parameters for Jacobian of J
        n = length(p);
        er = [zeros(r-1, 1); 1; zeros(n-r, 1)];
        dF = ResponseFunction(beta(r), sr, link, 1);
        d2F = ResponseFunction(beta(r), sr, link, 2);
        
        % general form of Jacobian of functional connectivity of row r at
        % fixed point wrt row r
        grad = d2F*(1 - p(r)) .* repmat(Wr, [1 n]) .* repmat(p', [n 1]) + diag(dF)*(1 - p(r)) - er*dF*p';
        grad = grad'*G;
        cost = norm(grad);

        if (line_search)
            J = Jacobian(alpha, W-er*grad', p, h, link);
            Glook = Jp-J(r,:)';
            crit = 2*norm(G-Glook)/cost^2;
            if (crit < 1)
                gamma = eta^floor(log(crit)/log(eta));
            else
                gamma = eta;
            end
        end
        
        %%- make sure the gradient descent is in the right direction
        if (subspace(grad, B*inv(B'*B)*B'*grad) <= pi/2)
            dw = -gamma*B*inv(B'*B)*B'*grad;
        else
            dw = gamma*B*inv(B'*B)*B'*grad;
        end
        
        W(r,:) = W(r,:)+dw'; % update structural connections at node r
    end

    % display end cost
    disp(['End cost of gradient is ', num2str(cost)]);
    
    dw = W(r,:)' - Wo(r,:)'; % final pertrubation to the structure
 end