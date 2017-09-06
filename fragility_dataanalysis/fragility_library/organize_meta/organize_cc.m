% script for organizing finalized fragility results for JHU Patients
%
% all CC patients follow naming convention: JH<#>sz<#>p, or for itnerictal
% 

patients = {...,
    'JH101sz1' 'JH101sz2' 'JH101sz3' 'JH101sz4',...
	'JH102sz1' 'JH102sz2' 'JH102sz3' 'JH102sz4' 'JH102sz5' 'JH102sz6',...
	'JH103sz1' 'JH103sz2' 'JH103sz3',...
	'JH104sz1' 'JH104sz2' 'JH104sz3',...
	'JH105sz1' 'JH105sz2' 'JH105sz3' 'JH105sz4' 'JH105sz5',...
	'JH106sz1' 'JH106sz2' 'JH106sz3' 'JH106sz4' 'JH106sz5' 'JH106sz6',...
	'JH107sz1' 'JH107sz2' 'JH107sz3' 'JH107sz4' 'JH107sz5' 'JH107sz6' 'JH107sz7' 'JH107sz8' 'JH107sz9',...
   'JH108sz1', 'JH108sz2', 'JH108sz3', 'JH108sz4', 'JH108sz5', 'JH108sz6', 'JH108sz7',...
};

saveDir = './serverdata/organized_patients/';
if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end

organized_patients = struct();

for iPat=1:length(patients)
    patient = patients{iPat};
    
    pid = strsplit(patient, 'sz');
    pnum = pid{1};
    
    if ~isfield(organized_patients, pnum)
        organized_patients.(pnum) = {};
    end
    organized_patients.(pnum){end+1} = patient;
end

organized_patients

save(fullfile(saveDir, 'jhu_patients'), 'organized_patients');