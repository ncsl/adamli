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

%- plotting options
FONTSIZE = 16;
figDir = fullfile(rootDir, 'fragility_theory', 'figures');
if ~exist(figDir, 'dir')
    mkdir(figDir);
end

 %- perturbation options
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


%% create small perturbation simulation from real data


center = 'nih';
patient = 'pt7sz19';

center='cc';
patient = 'EZT019seiz001';

% set patientID and seizureID
patient_id = patient(1:strfind(patient, 'seiz')-1);
seizure_id = strcat('_', patient(strfind(patient, 'seiz'):end));
seeg = 1;
INTERICTAL = 0;
if isempty(patient_id)
    patient_id = patient(1:strfind(patient, 'sz')-1);
    seizure_id = patient(strfind(patient, 'sz'):end);
    seeg = 0;
end
if isempty(patient_id)
    patient_id = patient(1:strfind(patient, 'aslp')-1);
    seizure_id = patient(strfind(patient, 'aslp'):end);
    seeg = 0;
    INTERICTAL = 1;
end
if isempty(patient_id)
    patient_id = patient(1:strfind(patient, 'aw')-1);
    seizure_id = patient(strfind(patient, 'aw'):end);
    seeg = 0;
    INTERICTAL = 1;
end
buffpatid = patient_id;
if strcmp(patient_id(end), '_')
    patient_id = patient_id(1:end-1);
end
[included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
    resection_labels, frequency_sampling, center, success_or_failure] ...
        = determineClinicalAnnotations(patient_id, seizure_id);
    
dataDir = fullfile(rootDir, 'data', center, patient);
dataDir = fullfile(rootDir, 'data', center, patient_id);
    
data = load(fullfile(dataDir, strcat(patient_id, seizure_id)));
data.data = data.data(included_channels, :);
seizureStart = data.seiz_start_mark;
eegdata = data.data;

%- create an example adjMat
adj_args.BP_FILTER_RAW = 2;
adj_args.frequency_sampling = frequency_sampling;
adj_args.winSize = 500;
adj_args.stepSize = 500;
adj_args.seizureStart = 0;
adj_args.seizureEnd = 0;
adj_args.l2regularization = 0;
adj_args.numHarmonics = 7;
adj_args.TYPE_CONNECTIVITY = 'leastsquares';

P = 3; % size of simulation
numSims = 200;
all_del_sizes = zeros(numSims, P, length(w_space));
for iSim=1:numSims
    randIndices = randsample(size(eegdata,1), P);
    randTime = randsample(seizureStart-500, 1);
    adjMat = squeeze(computeConnectivity(eegdata(randIndices, randTime:randTime+499), adj_args));

    [N, ~] = size(adjMat);

    minPerturbation = zeros(P,1); % initialize minPerturbation Matrix

    % store min delta for each electrode X w
    del_size = zeros(N, length(w_space));   % store min_norms
    del_table = cell(N, 1);                 % store min_norm vector for each node

    % %- check orthogonality of 
%     [V, D] = eig(adjMat);
% 
%     % testing if eigenvectors are real vs complex
%     V = complex(randn(N, N), randn(N,N));
%     V = randn(N,N);
%     adjMat = V*D*inv(V);
    tol = 1e-7;

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
    %             disp('.');
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

        % test on the min norm perturbation vector
%         if strcmp(perturbationType, 'C')
%             del = reshape(del_vecs{min_index}, N, 1);
%             pertTest = del * ek';
%         else
%             del = reshape(del_vecs{min_index}, 1, N);
%             pertTest = ek*del_vecs{min_index};
%         end
% 
%         test = A + pertTest;
%         figure;
%         %- plot radius circle
%         th = 0:pi/50:2*pi;
%         r = radius; x = 0; y = 0;
%         xunit = r * cos(th) + x;
%         yunit = r * sin(th) + y;
%         h = plot(xunit, yunit, 'b-'); hold on;
%         axes = gca;
%         plot(get(axes, 'XLim'), [0 0], 'k');
%         plot([0 0], get(axes, 'YLim'), 'k');
%         plot(real(eig(test)), imag(eig(test)), 'ko')
% 
%         iNode
%         eig(test)
%         min_index
        % store the min-norm perturbation for this node
        if length(min_index) > 1
            if del_size(iNode, min_index(1)) == del_size(iNode, min_index(2))
                minPerturbation(iNode) = del_size(iNode, min_index(1));
            end
        else
            minPerturbation(iNode) = del_size(iNode, min_index);
        end
    end % end of loop through channels\

%     figure;
%     for i=1:P
%         plot(del_size(i,:));
%         hold on;
%     end
    
    all_del_sizes(iSim,:,:) = del_size;
end

for i=1:numSims
    for j=1:N
        testindex = find(all_del_sizes(i,j,:) == min(all_del_sizes(i,j,:)));
        if testindex ~= 152 && testindex ~= 51
            disp(['Wrong at ', num2str(i), ' ', num2str(j)]);
        end
    end
end

colors = {'k', 'b', 'r'};

temp = squeeze(mean(all_del_sizes, 1));
tempstd = squeeze(std(all_del_sizes, 0, 1));
% figure;
for i=1:N
    figure;
    %     shadedErrorBar(1:length(w_space), temp(i,:), tempstd(i,:));
    plot(1:length(w_space), temp(i,:), 'Color', colors{i}); hold on;
    plot(1:length(w_space), squeeze(min(all_del_sizes(:,i,:))), 'LineStyle', ':', 'Color', colors{i});
%     plot(1:length(w_space), squeeze(max(all_del_sizes(:,i,:))), 'LineStyle', '--', 'Color', colors{i});
    ax = gca;
    ax.FontSize = FONTSIZE;
    xlabel('Along W Space');
    ylabel('Delta Norms');
    title(['Channel ', num2str(i), ' Delta Norms over Space']);
    legend('Average Norms', 'Min Norms', 'Max Norms');
    
    currfig = gcf;
    set(currfig, 'Units', 'inches');
    currfig.Position = [17.3438         0   15.9896   11.6771];
    
    toSaveFigFile = fullfile(figDir, strcat(patient, '_chanindex', num2str(i), '_realdata_randomtime'));
    print(toSaveFigFile, '-dpng', '-r0');
    
    close all
end

disp('done')