dataDir = './data/';

nihFile = fullfile(dataDir, 'nihclinicalData.mat');
ummcFile = fullfile(dataDir, 'ummcclinicalData.mat');
jhuFile = fullfile(dataDir, 'jhuclinicalData.mat');
% ccFile = fullfile(dataDir, 'ccclinicalData.mat');

patients = {};
nihdata = load(nihFile);
ummcdata = load(ummcFile);
jhudata = load(jhuFile);
% patients = cell(length(fieldnames(nihdata.clinicaldata)) + length(fieldnames(ummcdata.clinicaldata)), 1);
patients = vertcat(fieldnames(nihdata.clinicaldata), fieldnames(ummcdata.clinicaldata), fieldnames(jhudata.clinicaldata));

clinicaldata = struct();
% for each identifier
for id=1:length(patients)
    patient = patients{id};
    
    if strfind(patient, 'pt')
        clinicaldata.(patient) = nihdata.clinicaldata.(patient);
    elseif strfind(patient, 'UMMC')
        clinicaldata.(patient) = ummcdata.clinicaldata.(patient);
    else
        clinicaldata.(patient) = jhudata.clinicaldata.(patient);
    end
end

save(fullfile(dataDir, 'clinicalData.mat'), 'clinicaldata');