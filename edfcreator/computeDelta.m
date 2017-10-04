% Function: computeDelta
%
% (c) 2016 Adam Li
%
% Computes a delta, standing for the minimum l2-norm perturbation to an
% adjacency matrix to bring it from stability to some radius of instability
% on the unit disc. This is applied to discrete-time LTI systems.
%
% Syntax:
%  DELTA = natsortfiles(w, radius, theta_adj)
%
% ### File Dependency ###
%
% ### Input and Output Arguments ###
%
% Inputs :
%  w   = range of jw to search over.
%  radius = The radius of the real-imaginary disc to bring it too
%  A = the adjacency matrix that is NxN
%
% Outputs:
%  Delta = The row/column matrix that brings original A to instability
% 
function delta = computeDelta(w, radius, A)
    delta = 0;                     % initialize delta
    sigma = sqrt(radius^2 - w.^2); % define vector of sigmas that bring w to the radius
    perturbationType = 'R';
    N = size(A,1); % number of rows
    b = [0; 1];
    
    %%- 01: initialize variables
    max_eig = max(abs(eig(A)));
    del_table = cell(N, length(w)); % store the actual Gamma
    del_size = zeros(N, length(w)); % store the norms per w
    
    minDel_table = cell(N,1);
    minPerturb_table = zeros(N, 1); % store the minimum norm of each node
    
    %%- 02: Check
    if(max_eig < radius) 
        for iNode=1:N % loop over channels
            ek = [zeros(iNode-1, 1); 1; zeros(N-iNode,1)]; % unit vector at this node
            
            for iW=1:length(w) % loop through locations on unit circle
                lambda = sigma(iW) + 1i*w(iW);
                
                % row or column perturbation inversion
                if (perturbationType == 'R')
                    C = ek'*inv(A - lambda*eye(N));                
                elseif (perturbationType == 'C')
                    C = inv(A - lambda*eye(N))*ek; 
                end
                Cr = real(C); Ci = imag(C);
                B = [Ci; Cr];
                
                del = B'*inv(B*B')*b;
                
                % store the GAMMA and norm for each channel/freq.
                del_table{iNode, iW} = del;
                del_size(iNode, iW) = norm(del);
            end
            % find column for each row of minimum norm perturbation
            [r, c] = ind2sub([N length(w)], find(del_size == min(del_size(iNode, :))));
            r = r(1); c = c(1);

            minPerturb_table(iNode) = del_size(iNode, c); % min norm perturbation
            minDel_table(iNode) = del_table(iNode, c);    % min perturbation
        end
        
        % find the minimum norm from every gamma (channel)
        k = find(minPerturb_table == min(minPerturb_table));
        ek = [zeros(k-1, 1); 1; zeros(N-k, 1)];
        delta = ek*minDel_table{k}'; % return perturbation in matrix form
    end
end