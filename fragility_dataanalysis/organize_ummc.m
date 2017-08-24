% script for organizing finalized fragility results for UMMC
%
% all NIH patients follow naming convention: UMMC<#>_seiz<#>
% 

patients = {...,
     'UMMC001_sz1', 'UMMC001_sz2', 'UMMC001_sz3', ...
    'UMMC002_sz1', 'UMMC002_sz2','UMMC002_sz3', ...
    'UMMC003_sz1', 'UMMC003_sz2', 'UMMC003_sz3', ...
    'UMMC004_sz1', 'UMMC004_sz2', 'UMMC004_sz3', ...
    'UMMC005_sz1', 'UMMC005_sz2', 'UMMC005_sz3', ...
    'UMMC006_sz1', 'UMMC006_sz2', 'UMMC006_sz3', ...
    'UMMC007_sz1', 'UMMC007_sz2','UMMC007_sz3', ...
    'UMMC008_sz1', 'UMMC008_sz2', 'UMMC008_sz3', ...
    'UMMC009_sz1','UMMC009_sz2', 'UMMC009_sz3', ...
};

saveDir = './serverdata/organized_patients/';
if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end

organized_patients = struct();

for iPat=1:length(patients)
    patient = patients{iPat};
    
    pid = strsplit(patient, '_');
    pnum = pid{1};
    
    if ~isfield(organized_patients, pnum)
        organized_patients.(pnum) = {};
    end
    organized_patients.(pnum){end+1} = patient;
end

organized_patients

save(fullfile(saveDir, 'ummc_patients'), 'organized_patients');