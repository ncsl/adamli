patients = {...,
%      'pt1aw1','pt1aw2', ...
%     'pt1aslp1','pt1aslp2', ...
%     'pt2aw1', 'pt2aw2', ...
%     'pt2aslp1', 'pt2aslp2', ...
%     'pt3aw1', ...
%     'pt3aslp1', 'pt3aslp2', ...
%     'pt1sz2', 'pt1sz3', 'pt1sz4',...
%     'pt2sz1' 'pt2sz3' , 'pt2sz4', ...
%     'pt3sz2' 'pt3sz4', ...
%     'pt6sz3', 'pt6sz4', 'pt6sz5',...
%     'pt7sz19', 'pt7sz21', 'pt7sz22',...
%     'pt8sz1' 'pt8sz2' 'pt8sz3',...
%     'pt10sz1','pt10sz2' 'pt10sz3', ...
%     'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
%     'pt12sz1', 'pt12sz2', ...
%     'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5',...
%     'pt14sz1' 'pt14sz2' 
    'pt14sz3' ...
    'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
    'pt16sz1' 'pt16sz2' 'pt16sz3',...
    'pt17sz1' 'pt17sz2', 'pt17sz3', ...

%     'UMMC001_sz1', 'UMMC001_sz2', 'UMMC001_sz3', ...
%     'UMMC002_sz1', 'UMMC002_sz2', 'UMMC002_sz3', ...
%     'UMMC003_sz1', 'UMMC003_sz2', 'UMMC003_sz3', ...
%     'UMMC004_sz1', 'UMMC004_sz2', 'UMMC004_sz3', ...
%     'UMMC005_sz1', 'UMMC005_sz2', 'UMMC005_sz3', ...
%     'UMMC006_sz1', 'UMMC006_sz2', 'UMMC006_sz3', ...
%     'UMMC007_sz1', 'UMMC007_sz2','UMMC007_sz3', ...
%     'UMMC008_sz1', 'UMMC008_sz2', 'UMMC008_sz3', ...
%     'UMMC009_sz1', 'UMMC009_sz2', 'UMMC009_sz3', ...
%     
%     'JH103aslp1', 'JH103aw1', ...
%     'JH105aslp1', 'JH105aw1',...
    
%     'JH103sz1' 'JH103sz2' 'JH103sz3',...
%     'JH105sz1' 'JH105sz2' 'JH105sz3' 'JH105sz4' 'JH105sz5',...
%     'Pat2sz1p', 'Pat2sz2p', 'Pat2sz3p', ...
%     'Pat16sz1p', 'Pat16sz2p', 'Pat16sz3p', ...
%     'LA01_ICTAL', 'LA01_Inter', ...
%     'LA02_ICTAL', 'LA02_Inter', ...
%     'LA03_ICTAL', 'LA03_Inter', ...
%     'LA04_ICTAL', 'LA04_Inter', ...
%     'LA05_ICTAL', 'LA05_Inter', ...
%     'LA06_ICTAL', 'LA06_Inter', ...
%     'LA08_ICTAL', 'LA08_Inter', ...
%     'LA09_ICTAL', 'LA09_Inter', ...
%     'LA10_ICTAL', 'LA10_Inter', ...
%     'LA11_ICTAL', 'LA11_Inter', ...
%     'LA15_ICTAL', 'LA15_Inter', ...
%     'LA16_ICTAL', 'LA16_Inter', ...
};

% parameters
winSize = 250;
stepSize = 125;
filterType = 'notchfilter';
% filterType = 'adaptivefilter';
radius = 1.5;
typeConnectivity = 'leastsquares';
typeTransform = 'fourier';
rejectThreshold = 0.3;
reference = '';

for iPat=1:length(patients)
    patient = patients(iPat);
    plotting_fragility(patient, winSize, stepSize, filterType, radius, typeConnectivity, typeTransform, rejectThreshold, reference)
end