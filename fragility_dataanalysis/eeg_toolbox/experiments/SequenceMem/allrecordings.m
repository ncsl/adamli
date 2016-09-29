close all; 
clear all;

homeDir = '/Volumes/shares/FRNU/dataworking/dbs/';


patients(14).subj='DBS043';
patients(14).T_date = '151118';
patients(14).dataFile = {'RT1D1.470'; 'LT2D1.510'};
patients(14).tasks = {'SequenceMem'; 'SequenceMem'};

patients(13).subj='DBS042';
patients(13).T_date = '151028';
patients(13).dataFile = {'RT2D1.453'; 'LT1D1.004'};
patients(13).tasks = {'SequenceMem'; 'SequenceMem'};

patients(12).subj='DBS041';
patients(12).T_date = '151014';
patients(12).dataFile = {'RT1D-0.023'; 'LT1D1.014'; 'LT1D-1.121'};
patients(12).tasks = {'SequenceMem'; 'SequenceMem'; 'SequenceMem'};

patients(11).subj='DBS040';
patients(11).T_date = '300915';
patients(11).dataFile = {'02325002'; '-00018'};
patients(11).BRdataFile = {''; ''};
patients(11).NKdataFile = {'JA02502M';'JA02502O'};
patients(11).tasks = {'SequenceMem'; 'SequenceMem'};

patients(10).subj='DBS039';
patients(10).T_date = '160915';
patients(10).dataFile = {'-01000001'};
patients(10).BRdataFile = {'DBS039_leftSTN'};
patients(10).NKdataFile = {''};
patients(10).tasks = {'SequenceMem'};

patients(9).subj='DBS038';
patients(9).T_date = '220715';
patients(9).dataFile = {'-01098'; '02017'};
patients(9).BRdataFile = {'DBS038_rightstnlefthand'; 'DBS038_leftstnrighthand'};
patients(9).NKdataFile = {'',''};
patients(9).tasks = {'SequenceMem'; 'SequenceMem'};

patients(8).subj='DBS037';
patients(8).T_date = '150715';
patients(8).dataFile = {'00917'; '00022002'; '01722'; '-00957001'};
patients(8).BRdataFile = {'DBS037RightSideA'; 'DBS037RightSideB'; 'DBS037LeftSideA'; 'DBS037LeftSideB'};
patients(8).NKdataFile = {'',''};
patients(8).tasks = {'SequenceMem'; 'SequenceMem'; 'SequenceMem'; 'SequenceMem'};

patients(7).subj='DBS036';
patients(7).T_date = '150501';
patients(7).dataFile = {'01006'; '03001'};
patients(7).BRdataFile = {'DBS036_rightSTNlefthand'; 'DBS036_leftSTNrighthand'};
patients(7).NKdataFile = {'',''};
patients(7).tasks = {'SequenceMem';'SequenceMem'};

patients(6).subj='DBS035';
patients(6).T_date = '150401';
patients(6).dataFile = {'02996'};
patients(6).BRdataFile = {'dbs035_leftstn'};
patients(6).NKdataFile = {''};
patients(6).tasks = {'SequenceMem'};

patients(5).subj='DBS033';
patients(5).T_date = '150311';
patients(5).dataFile = {'00502'; '01500'};
patients(5).BRdataFile = {'DBS033_rightSTN'; 'DBS033_leftSTN'};
patients(5).NKdataFile = {'',''};
patients(5).tasks = {'SequenceMem';'SequenceMem'};

patients(4).subj='DBS032';
patients(4).T_date = '150204';
patients(4).dataFile = {'01007001'; '00203'};
patients(4).BRdataFile = {'DBS032leftstnrighthand'; 'DBS032rightstnleftthand'};
patients(4).NKdataFile = {'',''};
patients(4).tasks = {'SequenceMem';'SequenceMem'};

patients(3).subj='DBS031';
patients(3).T_date = '150121';
patients(3).dataFile = {'-00805'; '-01016001'};
patients(3).BRdataFile = {''; 'lefthandrightstn'};
patients(3).NKdataFile = {'',''};
patients(3).tasks = {'SequenceMem';'SequenceMem'};

patients(2).subj='DBS030'; %GPi subject
patients(2).T_date = '141217';
patients(2).dataFile = {'01505001'; '01507001'};
patients(2).BRdataFile = {'gpi121714righthandleftgpisecond','gpi121714rightgpi'};
patients(2).NKdataFile = [];
patients(2).tasks = {'SequenceMem';'SequenceMem'};

patients(1).subj='DBS029';
patients(1).T_date = '141107';
patients(1).dataFile = {'-01980001'; '00909'};
patients(1).BRdataFile = {'DBS029'; 'DBS029b'};
patients(1).NKdataFile = [];
patients(1).tasks = {'SequenceMem';'SequenceMem'};


%%
patients(cellfun('isempty',{patients.subj}))=[];
for patient=1:length(patients)
    patients(patient).subj
    if ~isempty(patients(patient).BRdataFile) || ~isempty(patients(patient).NKdataFile)
        DBSPrepAndAlign_oldao(homeDir,patients(patient).subj, patients(patient).T_date, patients(patient).dataFile, patients(patient).BRdataFile, patients(patient).NKdataFile, patients(patient).tasks); % The old method with ao_split
    else
        DBSPrepAndAlign(homeDir,patients(patient).subj, patients(patient).T_date, patients(patient).dataFile, patients(patient).tasks); % the new method with no_split. DBS041 and beyond
    end
end