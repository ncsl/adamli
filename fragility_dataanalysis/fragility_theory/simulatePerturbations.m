% script to test fragility theory
% 1. Create a 3x3, 4x4 matrix with 1 real eigenvalue and 2 complex
% conjugate eigenvalues
%
% 2. Compute minimum norm perturbation of real eigenvalue and complex
%
% 3. Show the minimum norm perturbation

%% add paths/library
addpath(genpath('../fragility_library/'));

%% create simulated matrices
% create a random matrix
A = randn(3,3);

% perform QR factorization to get an orthogonal matrix
[Q, ~] = qr(A);

L = diag([1, 0.9+1i, 0.9-1i]);
adjMat = Q*L*inv(Q);

radius = 1.5;
pertArgs.perturbationType = 'C';
pertArgs.w_space = linspace(-radius, radius, 101);
pertArgs.radius = radius;

%% Perform Algorithm
%%- Compute Minimum Norm Perturbation
% store min delta for each electrode X w
del_size = zeros(N, length(w_space));   % store min_norms
del_table = cell(N, 1);                 % store min_norm vector for each node

%%- grid search over sigma and w for each row to determine, what is
%%- the min norm perturbation
for iNode=1:N % 1st loop through each electrode
    ek = [zeros(iNode-1, 1); 1; zeros(N-iNode,1)]; % unit column vector at this node
   
    del_vecs = cell(length(w_space), 1);       % store all min_norm vectors
    for iW=1:length(w_space) % 2nd loop through frequencies
        curr_sigma = sigma(iW);
        curr_w = w_space(iW);
        lambda = curr_sigma + 1i*curr_w;
        
        % compute row, or column perturbation
        % A\b => Ax = b => x = inv(A)*b
        if (perturbationType == 'R')
            C = (A-lambda*eye(N))\ek;
        elseif (perturbationType == 'C')
            C = ek'/(A-lambda*eye(N)); 
%             C = (A-lambda*eye(N))'\ek;
        end

        %- extract real and imaginary components
        %- create B vector of constraints
        Cr = real(C);  Ci = imag(C);
        if strcmp(perturbationType, 'R')
            B = [Ci, Cr]';
        else
            B = [Ci; Cr];
%             B = [Ci, Cr]';
        end
        
        % compute perturbation necessary
        if w_space(iW) ~= 0
            del = B'*inv(B*B')*b;
        else
            del = -C./(norm(C)^2);
        end
        
        % store the l2-norm of the perturbation vector
        del_size(iNode, iW) = norm(del); 
        
        % store the perturbation vector at this specified radii point
        del_vecs{iW} = del;
        
        % test to make sure things are working...
%         if strcmp(perturbationType, 'C')
%             del = del';
%             try
%                 temp = del*ek';
%             catch e
% %                 disp(e)
%                 temp = del'*ek'; 
%             end
%         else
%             temp = ek*del';
%         end
%         test = A + temp;
%         plot(real(eig(test)), imag(eig(test)), 'ko')
% %         if isempty(find(abs(radius - abs(eig(test))) < 1e-8))
% %             disp('Max eigenvalue is not displaced to correct location')
% %         end
%         close all
    end

    %%- 03: Store Results min norm perturbation
    % find index of min norm perturbation for this node
    min_index = find(del_size(iNode,:) == min(del_size(iNode, :)));
    
    if length(min_index) == 1
        % store the min-norm perturbation vector for this node
        del_table(iNode) = del_vecs(min_index);
    else
        temp = del_vecs(min_index);

        for i=1:length(min_index)
            vec = reshape(temp{i}, N, 1);
            
            if i==1
                to_insert = vec;
            else
                to_insert = cat(2, to_insert, vec);
            end
        end
        
        del_table(iNode) = {to_insert};
    end
    
    % test on the min norm perturbation vector
%     if strcmp(perturbationType, 'C')
%         pertTest = del_vecs{min_index} * ek';
%     else
%         pertTest = ek*del_vecs{min_index};
%     end
%     test = A + pertTest;
%     plot(real(eig(test)), imag(eig(test)), 'ko')
    
    % store the min-norm perturbation for this node
    if length(min_index) > 1
        if del_size(iNode, min_index(1)) == del_size(iNode, min_index(2))
            minPerturbation(iNode) = del_size(iNode, min_index(1));
        end
    else
        minPerturbation(iNode) = del_size(iNode, min_index);
    end
end % end of loop through channels\

%% Plotting

