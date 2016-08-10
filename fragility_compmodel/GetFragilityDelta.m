%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION: Gradient Descent
% DESCRIPTION: Used to compute the fixed point of our linear model.
%
% INPUT:
% - alpha = 
% - beta =
% - W = We - Wi is the resulting synaptic weight matrix, with negative
% values corresponding to inhibition and positive weights to excitation
% - h = 
% - link = the corresponding response function (e.g. 'tanh')
%
% OUTPUT:
% - p = 
% - CF = 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Del_r] = GetFragilityDelta(J, perturbationType, re, im)    
    w = linspace(0, 2*pi/10, 101); % oscillation at 0-100 Hz
    if (~isempty(im))
        w = w(im);
    end
    tol = 1e-7; % tolerance 
    
    n = size(J, 1); % get the number of nodes in functional connectivity matrix
    del_size = zeros(n, length(w));
    del_table = cell(n, length(w));
    
    for j=1:length(w) % loop through these various w's number of simulations to run
        for iNode=1:n % loop through all nodes
            lambda = re + 1i*w(j);
            ei = [zeros(iNode-1, 1); 1; zeros(n-iNode, 1)]; % unit vector
            
            if (perturbationType == 'R')                    % row perturbation
                C = (J - lambda*eye(n)) \ ei;   
            elseif (perturbationType == 'C')                % column pertrubation
                C = (J - lambda*eye(n))' \ ei;
            end
            
            Cr = real(C);
            Ci = imag(C);
            
            % either make B just all 1's, or make it orthogonal to imaginary
            % column vector
            if (norm(Ci) < tol)
                B = eye(n);
            else
                B = null(orth([Ci])');
            end
            
            % get projected gradient into orthongonal space to p | eqn. A.10
            del = -(B * inv(B'*B)*B' * Cr) / (Cr'*B*inv(B'*B)*B'*Cr);
            del_size(iNode, j) = norm(del); % store the norm of the DELTA
            del_table{iNode, j} = del;          % store the actual DELTA
        end
    end
    
    % find row/column of minimum norm perturbation
    [r, c] = ind2sub([n length(w)], find(del_size == min(min(del_size)))); 
    r = r(1); % just get the 1st one
    j = j(1);
    
    ei = [zeros(r-1, 1); 1; zeros(n-r, 1)]; % column unit vector at this minimum row perturb. (n x 1)
    del = del_table{r, c};                   % get the DELTA at this minimum norm area
    
    %%- convert to either row, or column vector
    if (perturbationType == 'R')
        Del_r = ei*del';
    elseif (perturbationType == 'C')
        Del_r = del*ei';
    else
        disp('PerturbationType not set');
    end
    Del_r(abs(Del_r)<tol) = 0;

    lambda = re+1i*w(j);
end