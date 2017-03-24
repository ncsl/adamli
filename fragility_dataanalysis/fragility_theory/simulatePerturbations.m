% script to test fragility theory
% 1. Create a 3x3, 4x4 matrix with 1 real eigenvalue and 2 complex
% conjugate eigenvalues
%
% 2. Compute minimum norm perturbation of real eigenvalue and complex
%
% 3. Show the minimum norm perturbation
close all;

%% add paths/library
%% Set Working Directories
% set working directory
% data directories to save data into - choose one
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                      % ICM SERVER
% eegRootDirHome = '/Users/adam2392/Documents/MATLAB/Johns Hopkins/NINDS_Rotation'; % home
eegRootDirHome = '/Volumes/NIL_PASS/';                                              % external HD
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';         % at work - JHU

% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
else   error('Neither Work nor Home EEG directories exist! Exiting.'); end

addpath(genpath(fullfile(rootDir, '/fragility_library/')));
addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
addpath(rootDir);

center = 'nih';
patient = 'pt1sz2';
dataDir = fullfile(rootDir, 'data', center, patient);

%- plotting options
FONTSIZE = 16;

%% create simulated matrices
% create a random matrix
P = 3; % the size of the random matrix
A = randn(P,P);
while rank(A) ~= P
    A = randn(P,P);
end

% perform QR factorization to get an orthogonal matrix
[Q, ~] = qr(A);

imagev = 0.18;
conjev = sqrt(0.99-imagev^2);
L = diag([0.99 + 0*i, conjev+imagev*i, conjev-imagev*i]);
adjMat = A*L*inv(A);

radius = 1.5;
pertArgs.perturbationType = 'C';
pertArgs.w_space = linspace(-radius, radius, 101);
pertArgs.radius = radius;

perturbationType = pertArgs.perturbationType;
w_space = pertArgs.w_space;
radius = pertArgs.radius;

sigma = sqrt(radius^2 - w_space.^2); % move to the unit circle 1, for a plethora of different radial frequencies
b = [0; -1];                          % initialize for perturbation computation later

% add to sigma and w to create a whole circle search
w_space = [w_space, w_space];
sigma = [-sigma, sigma];

% figure;
% plot(sigma, w_space, 'k*')
%% Perform Algorithm
%%- Compute Minimum Norm Perturbation
[N, ~] = size(adjMat);

minPerturbation = zeros(N,1); % initialize minPerturbation Matrix

% store min delta for each electrode X w
del_size = zeros(N, length(w_space));   % store min_norms
del_table = cell(N, 1);                 % store min_norm vector for each node

%%- grid search over sigma and w for each row to determine, what is
%%- the min norm perturbation
A = adjMat;
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
        
        % Paper way of computing this?...
        Cr = real(C);  Ci = imag(C);
        Cr = Cr'; Ci = Ci';
        if (norm(Ci) < tol)
            B = eye(N);
        else
            B = null(orth(Ci)'); 
        end
        
        del = -(B*inv(B'*B)*B'*Cr)/(Cr'*B*inv(B'*B)*B'*Cr);
        
        % compute perturbation necessary
        if w_space(iW) ~= 0
%             del = B'*inv(B*B')*b;
        else
%             del = -C./(norm(C)^2);
            
             % test to make sure things are working...
%             if strcmp(perturbationType, 'C')
%                 del = reshape(del, N, 1);
%                 temp = del * ek';
%             else
%                 temp = ek*del';
%             end
%             test = A + temp;
%             
%             iW
%             lambda
%             iNode
%             eig(test)
%             figure;
%             plot(real(eig(test)), imag(eig(test)), 'ko'); hold on;
%             th = 0:pi/50:2*pi;
%             r = radius; x = 0; y = 0;
%             xunit = r * cos(th) + x;
%             yunit = r * sin(th) + y;
%             h = plot(xunit, yunit, 'b-'); 
%             axes = gca;
%             plot(get(axes, 'XLim'), [0 0], 'k');
%             plot([0 0], get(axes, 'YLim'), 'k');
%             if isempty(find(abs(radius - abs(eig(test))) < 1e-8))
%                 disp('Max eigenvalue is not displaced to correct location')
%             end
%             close all
        end
        
        % store the l2-norm of the perturbation vector
        del_size(iNode, iW) = norm(del); 
        
        % store the perturbation vector at this specified radii point
        del_vecs{iW} = del;
    end

    %%- 03: Store Results min norm perturbation
    % find index of min norm perturbation for this node
    min_index = find(del_size(iNode,:) == min(del_size(iNode, :)));
    
    if length(min_index) == 1
        % store the min-norm perturbation vector for this node
        del_table(iNode) = {reshape(del_vecs{min_index}, N, 1)};
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
    
    min_index
    % test on the min norm perturbation vector
    if strcmp(perturbationType, 'C')
        del = reshape(del_vecs{min_index}, N, 1);
        pertTest = del * ek';
    else
        del = reshape(del_vecs{min_index}, 1, N);
        pertTest = ek*del_vecs{min_index};
    end
    test = A + pertTest;
    figure;
    %- plot radius circle
    th = 0:pi/50:2*pi;
    r = radius; x = 0; y = 0;
    xunit = r * cos(th) + x;
    yunit = r * sin(th) + y;
    h = plot(xunit, yunit, 'b-'); hold on;
    axes = gca;
    plot(get(axes, 'XLim'), [0 0], 'k');
    plot([0 0], get(axes, 'YLim'), 'k');
    plot(real(eig(test)), imag(eig(test)), 'ko')
    
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
figure;
plot(minPerturbation); hold on;

markers = {'*', 'o', '+'};
colors = {'r', 'b', 'k'};

figure;
for chan=1:N
    ek = [zeros(chan-1, 1); 1; zeros(N-chan,1)]; % unit column vector at this node
    del = del_table{chan};
    if size(del, 2) == 1 || size(del, 1) == 1
        del = reshape(del, N, 1);
        temp = del*ek';
        test = adjMat + temp;
        
        chan
        eig(test)
        a=plot(real(eig(test)), imag(eig(test)), strcat(colors{chan}, '.'), 'Marker', markers{chan}, 'MarkerSize', 5); hold on;
    else
        chan
        for i=1:size(del,2)
            del_temp = reshape(squeeze(del(:,i)), N, 1);
            temp = del_temp*ek';
            test = adjMat + temp;
            plot(real(eig(test)), imag(eig(test)), 'g*', 'MarkerSize', 5); hold on;
        end
    end
end 
b= plot(real(eig(adjMat)), imag(eig(adjMat)), 'k*'); hold on;
legend([a, b], 'Perturbed', 'Original')
axes = gca;
xlabelStr = 'Real Part';
ylabelStr = 'Imag Part';
titleStr = ['Eigenspectrum of ', perturbationType, ' Perturbation'];
labelBasicAxes(axes, titleStr, ylabelStr, xlabelStr, FONTSIZE);
xlim([-radius radius]);
ylim([-radius radius]);
plot(get(axes, 'XLim'), [0 0], 'k');
plot([0 0], get(axes, 'YLim'), 'k');

%- plot unit circle
th = 0:pi/50:2*pi;
r = 1; x = 0; y = 0;
xunit = r * cos(th) + x;
yunit = r * sin(th) + y;
h = plot(xunit, yunit);

%- plot radius circle
th = 0:pi/50:2*pi;
r = radius; x = 0; y = 0;
xunit = r * cos(th) + x;
yunit = r * sin(th) + y;
h = plot(xunit, yunit, 'b-');