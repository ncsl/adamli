% script to test fragility theory
% 1. Create a 3x3, 4x4 matrix with 1 real eigenvalue and 2 complex
% conjugate eigenvalues
%
% 2. Compute minimum norm perturbation of real eigenvalue and complex
%
% 3. Show the minimum norm perturbation
close all;

%% INITIALIZATION
% data directories to save data into - choose one
eegRootDirHD = '/Volumes/ADAM LI/';
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                 % at ICM server 
eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';   % at home macbook
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';    % at JHU workstation
% eegRootDirMarcc = '/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/'; % at MARCC server
eegRootDirMarcc = '/scratch/groups/ssarma2/adamli/fragility_dataanalysis/';
% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
elseif ~isempty(dir(eegRootDirMarcc)), rootDir = eegRootDirMarcc;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

if     ~isempty(dir(eegRootDirServer)), dataDir = eegRootDirServer;
elseif ~isempty(dir(eegRootDirHD)), dataDir = eegRootDirHD;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

addpath(genpath(fullfile(rootDir, '/fragility_library/')));
addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
addpath(rootDir);

%% Clinical Annotations
center = 'nih';
patient = 'pt1sz2';

% set patientID and seizureID
[~, patient_id, seizure_id, seeg] = splitPatient(patient);

%- Edit this file if new patients are added.
[included_channels, ezone_labels, earlyspread_labels,...
    latespread_labels, resection_labels, fs, ...
    center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);

dataDir = fullfile(dataDir, 'data', center, patient);

%- plotting options
FONTSIZE = 16;

%% Create simulated matrices & Initialize Parameters
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

% set perturbation parameters
perturbationTypes = ['C', 'R'];
perturbationType = perturbationTypes(1);
radius = 1.25;

w_space = linspace(-radius, radius, 51);
sigma = sqrt(radius^2 - w_space.^2); % move to the unit circle 1, for a plethora of different radial frequencies
% add to sigma and w to create a whole circle search
w_space = [w_space, w_space(2:end-1)];
sigma = [-sigma, sigma(2:end-1)];
b = [0; -1];                          % initialize for perturbation computation later

perturb_args = struct();
perturb_args.perturbationType = perturbationType;
perturb_args.w_space = w_space;
perturb_args.radius = radius;
perturb_args.sigma = sigma;

% figure;
% plot(sigma, w_space, 'k*')
%% Perform Algorithm
%%- Compute Minimum Norm Perturbation
[N, ~] = size(adjMat);

%%- grid search over sigma and w for each row to determine, what is
%%- the min norm perturbation
A = adjMat;

% perform minimum norm perturbation
[minPerturbation, del_table, del_freqs, ~] = minNormPerturbation(A, perturb_args)%, clinicalLabels)

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
% xlim([-radius radius]);
% ylim([-radius radius]);
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