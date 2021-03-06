% script for organizing finalized fragility results for NIH
%
% all NIH patients follow naming convention: pt<#>sz<#>, or pt<#>aw<#>, or
% pt<#>aslp<#>
% 

patients = {...,
%      'pt1aw1','pt1aw2', ...
%     'pt2aw2', 'pt2aslp2',...
%     'pt1aslp1','pt1aslp2', ...
%     'pt2aw1', 'pt2aw2', ...
%     'pt2aslp1', 'pt2aslp2', ...
%     'pt3aw1', ...
%     'pt3aslp1', 'pt3aslp2', ...
    'pt1sz2', 'pt1sz3', 'pt1sz4',...
    'pt2sz1' 'pt2sz3' , 'pt2sz4', ...
    'pt3sz2' 'pt3sz4', ...
    'pt6sz3', 'pt6sz4', 'pt6sz5',...
    'pt7sz19', 'pt7sz21', 'pt7sz22',...
    'pt8sz1' 'pt8sz2' 'pt8sz3',...
    'pt10sz1','pt10sz2' 'pt10sz3', ...
    'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
    'pt12sz1', 'pt12sz2', ...
    'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5',...
    'pt14sz1' 'pt14sz2' 'pt14sz3'  'pt16sz1' 'pt16sz2' 'pt16sz3',...
    'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
    'pt16sz1' 'pt16sz2' 'pt16sz3',...
    'pt17sz1' 'pt17sz2', 'pt17sz3', ...
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

save(fullfile(saveDir, 'nih_patients'), 'organized_patients');