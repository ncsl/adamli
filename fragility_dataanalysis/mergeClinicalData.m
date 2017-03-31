dataDir = './data/';

nihFile = fullfile(dataDir, 'nihclinicalData.mat');
ummcFile = fullfile(dataDir, 'ummcclinicalData.mat');
% jhuFile = fullfile(dataDir, 'jhuclinicalData.mat');
% ccFile = fullfile(dataDir, 'ccclinicalData.mat');

patients = {};
nihdata = load(nihFile);
ummcdata = load(ummcFile);
% patients = cell(length(fieldnames(nihdata.clinicaldata)) + length(fieldnames(ummcdata.clinicaldata)), 1);
patients = vertcat(fieldnames(nihdata.clinicaldata), fieldnames(ummcdata.clinicaldata));

clinicaldata = struct();
% for each identifier
for id=1:length(patients)
    patient = patients{id};
    
    try
        clinicaldata.(patient) = nihdata.clinicaldata.(patient);
    catch e
        clinicaldata.(patient) = ummcdata.clinicaldata.(patient);
%     catch e
%         clinicaldata.(patient) = jhudata.(patient);
    end
end

save(fullfile(dataDir, 'clinicalData.mat'), 'clinicaldata');