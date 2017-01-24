%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION: computePerturbations
% DESCRIPTION: This function takes adjacency matrices and computes the
% minimum l2-induced-norm perturbation required to destabilize the system.
% 
% INPUT:
% - patient = The id of the patient (e.g. pt1, JH105, UMMC001)
% - A = A NxN adjacency matrix to compute the perturbation on for each
% row, or column
% - perturb_args = struct of different argument parameters
% 
% OUTPUT:
% - minPerturbation = the Nx1 min norm perturbation
% - del_table = the table of min-norm perturbation vectors for each
% i={1,..,N}
% - LOGERROR = some errror message
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [minPerturbation, del_table, LOGERROR] = minNormPerturbation(patient, A, pertArgs)%, clinicalLabels)
if nargin == 0
    patient_id = 'pt1';
    seizure_id = 'sz2';
    radius = 1.1;
    w_space = linspace(-1, 1, 101);
    perturbationType = 'R';
    winSize = 500;
    stepSize = 500;
    included_channels = 0;
end

tol = 1e-7;
%% 0: Extract Vars and Initialize Parameters
%- Note here: radius = sqrt(w_space^2 + sigma^2) for discrete time system
perturbationType = pertArgs.perturbationType;
w_space = pertArgs.w_space;
radius = pertArgs.radius;
sigma = sqrt(radius^2 - w_space.^2); % move to the unit circle 1, for a plethora of different radial frequencies
b = [0; -1];                          % initialize for perturbation computation later

% add to sigma and w to create a whole circle search
w_space = [w_space, w_space];
sigma = [-sigma, sigma];

N = size(A,1); % get the Number of Electrodes
minPerturbation = zeros(N,1); % initialize minPerturbation Matrix

frequency_sampling = 1000;
winSize = 500;
stepSize = 500;
%% Error Checking/Logging
if max(abs(eig(A))) > radius
    LOGERROR =  ['This patient has eigenvalue > radius, check it!', ...
        patient, '_', num2str(frequency_sampling), '_', num2str(winSize), '_', num2str(stepSize)];
elseif abs(max(abs(eig(A))) - radius) < 1e-8
    LOGERROR = ['This patient has eigenvalue == radius, check it!', ...
        patient, '_', num2str(frequency_sampling), '_', num2str(winSize), '_', num2str(stepSize)];
else
    LOGERROR = [];
end

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
        if (perturbationType == 'R')
            C = (A-lambda*eye(N))\ek;
        elseif (perturbationType == 'C')
            C = ek'/(A-lambda*eye(N)); 
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

        % Paper way of computing this?...
%         Cr = Cr'; Ci = Ci';
%         if (norm(Ci) < tol)
%             B = eye(N);
%         else
%             B = null(orth([Ci])'); 
%         end
%         
%         del = -(B*inv(B'*B)*B'*Cr)/(Cr'*B*inv(B'*B)*B'*Cr);
        
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
    min_index = find(del_size(iNode,:) == min(del_size(iNode, :)),1);
    
    % store the min-norm perturbation vector for this node
    del_table(iNode) = del_vecs(min_index);
    
    % test on the min norm perturbation vector
%     if strcmp(perturbationType, 'C')
%         pertTest = del_vecs{min_index} * ek';
%     else
%         pertTest = ek*del_vecs{min_index};
%     end
%     test = A + pertTest;
%     plot(real(eig(test)), imag(eig(test)), 'ko')
    
    % store the min-norm perturbation for this node
    minPerturbation(iNode) = del_size(iNode, min_index);
end % end of loop through channels

end
