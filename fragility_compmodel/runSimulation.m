%%- 01: Compute Fixed Point, p
p = [];
alpha = 0.1;
link = 'tanh';
while (isempty(p))
    frac = 0.5;
    N = 3;
    disp(['Generating Synaptic weights of excitatory and inhibitory']);
    
    [We, Wi] = GenerateNetwork(N, frac);
    
    % use gradient descent to compute fixed point
    h = 0.25+0.5*(rand(N,1));                  % external input
    beta = ones(N, 1); %1.0+0.0*rand(N,1);                  % randomly distributed weighting factors
    p = GradientDescent(alpha, beta, We-Wi, h, link);     
end

%%- 02: put excitatory and inhibitory into 1 network
N = N*2;
h = [h; h];
beta = [beta; beta];
p = [p; p];
W = [We -Wi; We -Wi]; % the general structural conenctivity

%%- 03: Compute Functional Perturbation for concatenated E/I neural network
J = Jacobian(alpha, beta, W, p, h, link); % g(W; p_hat) with constatnt fixed_point computed before and variable W

w = 1:21; % sweep over these rows to
% initialize parameters to store
DelJ = cell(length(w), 1); % the change to functional connectivity
DelW = cell(length(w), 1); % the change to structural connectivity

Wp = cell(length(w), 1); % the perturbed structural network
Jp = cell(length(w), 1); % the perturbed functional connect

constrained = zeros(length(w), 1);
omega = linspace(0, 2*pi/10, 101); % oscillations
r = zeros(length(w), 1);           % store the most fragile node indices
lambda = zeros(length(w), 1);

for iSim=1:length(w)
    % verify that the fragility is continuous, and compute DELTA_j at
    % specific fixed point, then get perturbed structure
    DelJ{iSim} = GetFragilityDelta(J, 'R', 0.01, w(iSim));
    [Wp, Jp{i}] = PerturbNetworkRow(alpha, beta, W, p, h, J, DelJ{iSim}, link, constrained(i));
    
%     [P D] = eig(Jp{i});
end

    [dP D] = eig(Jp{1});
    dP = dP(:,1);
    elo = -p./dP;
    ehi = (1-p)./dP;
    ilo = find(abs(elo) == min(abs(elo)));
    ihi = find(abs(ehi) == min(abs(ehi)));
    Plo = p+elo(ilo(1))*dP;
    Phi = p+ehi(ihi(1))*dP;
    
trials = 100;
T = 1000;
bin_delta = 0.1;

ft = (1-p).*ResponseFunction(beta, W*p + h, link, 0);
Wp = [W; Wp];
pa = zeros(N, length(Wp));
fa = zeros(N, length(Wp));
pas = zeros(N, length(Wp));
fas = zeros(N, length(Wp));
Sim = cell(trials, length(Wp));

size(Wp)
Wp

disp('Simulating networks');
for i=1:length(Wp)
    ptemp = zeros(N, trials);
    ftemp = zeros(N, trials);
    for j = 1:trials
        disp([i j]);
        Sim{j,i} = Simulation(alpha, beta, Wp(i,:), Phi, h, T, bin_delta, link);
        ptemp(:,j) = Sim{j,i}.p;
        ftemp(:,j) = Sim{j,i}.fr;
    end
    pa(:,i) = mean(ptemp, 2);
    fa(:,i) = mean(ftemp, 2);
    pas(:,i) = std(ptemp, 1, 2);
    fas(:,i) = std(ftemp, 1, 2);
end