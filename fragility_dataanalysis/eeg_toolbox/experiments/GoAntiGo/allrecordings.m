close all; 
clear all;

homeDir = '/Volumes/shares/FRNU/dataworking/dbs/';

patients(18).subj='DBS043';
patients(18).T_date = '151118';
patients(18).dataFile = {'RT1D1.470'; 'LT2D1.602'};
patients(18).tasks = {'GoAntiGo'; 'GoAntiGo'};

patients(17).subj='DBS042';
patients(17).T_date = '151028';
patients(17).dataFile = {'RT2D1.453'; 'LT1D1.004'};
patients(17).tasks = {'GoAntiGo'; 'GoAntiGo'};

patients(16).subj='DBS041';
patients(16).T_date = '151014';
patients(16).dataFile = {'RT1D-0.023'; 'LT1D1.014'};
patients(16).tasks = {'GoAntiGo'; 'GoAntiGo'};

patients(15).subj='DBS040';
patients(15).T_date = '150930';
patients(15).dataFile = {'02325002'; '-00018'};
patients(15).BRdataFile = {'';''};
patients(15).NKdataFile = {'JA02502M';'JA02502O'};
patients(15).tasks = {'GoAntiGo'; 'GoAntiGo'};

patients(14).subj='DBS038';
patients(14).T_date = '150722';
patients(14).dataFile = {'-01098'}; 
patients(14).BRdataFile = {'DBS038_rightstnlefthand'};
patients(14).NKdataFile = {''};
patients(14).tasks = {'GoAntiGo'};

patients(13).subj='DBS037';
patients(13).T_date = '150715';
patients(13).dataFile = {'00022002'; '-00957001'}; % For session 0, only Macro's recroded and they were recorded on micro (CElectrode) channel . See readme. Do not ever export again or read the readme very carefully
patients(13).BRdataFile = {'DBS037RightSideB'; 'DBS037LeftSideB'};
patients(13).NKdataFile = {'',''};
patients(13).tasks = {'GoAntiGo'; 'GoAntiGo'};

patients(12).subj='DBS036';
patients(12).T_date = '150501';
patients(12).dataFile = {'01006'};
patients(12).BRdataFile = {'DBS036_rightSTNlefthand'};
patients(12).NKdataFile = {'',''};
patients(12).tasks = {'GoAntiGo'};

patients(11).subj='DBS035';
patients(11).T_date = '150401';
patients(11).dataFile = {'02996'; '03505001'};
patients(11).BRdataFile = {'dbs035_leftstn'; 'dbs035_rightstn'};
patients(11).NKdataFile = {'',''};
patients(11).tasks = {'GoAntiGo';'GoAntiGo'};

patients(10).subj='DBS034';
patients(10).T_date = '150327';
patients(10).dataFile = {'00913'; '01293'};
patients(10).BRdataFile = {'dbs034_RIGHTSTN'; 'dbs034_LEFTSTN'};
patients(10).NKdataFile = {'',''};
patients(10).tasks = {'GoAntiGo';'GoAntiGo'};

patients(9).subj='DBS033';
patients(9).T_date = '150311';
patients(9).dataFile = {'00502'; '01500'};
patients(9).BRdataFile = {'DBS033_rightSTN'; 'DBS033_leftSTN'};
patients(9).NKdataFile = {'',''};
patients(9).tasks = {'GoAntiGo';'GoAntiGo'};

patients(8).subj='DBS032';
patients(8).T_date = '150204';
patients(8).dataFile = {'01007001'; '00203'};
patients(8).BRdataFile = {'DBS032leftstnrighthand'; 'DBS032rightstnleftthand'};
patients(8).NKdataFile = {'',''};
patients(8).tasks = {'GoAntiGo';'GoAntiGo'};

patients(7).subj='DBS031';
patients(7).T_date = '150121';
patients(7).dataFile = {'-00805'; '-01016001'};
patients(7).BRdataFile = {''; 'lefthandrightstn'};
patients(7).NKdataFile = {'',''};
patients(7).tasks = {'GoAntiGo';'GoAntiGo'}; 

patients(6).subj='DBS029';
patients(6).T_date = '141107';
patients(6).dataFile = {'-01980001'; '00909'};
patients(6).BRdataFile = {'DBS029'; 'DBS029b'};
patients(6).NKdataFile = {'',''};
patients(6).tasks = {'GoAntiGo';'GoAntiGo'};

patients(5).subj='DBS028';
patients(5).T_date = '141024';
patients(5).dataFile = {'-00966001'; '-02770001'};
patients(5).BRdataFile = {'',''};
patients(5).NKdataFile = {'CA21115S';'CA21115U'};
patients(5).tasks = {'GoAntiGo';'GoAntiGo'};

patients(4).subj='DBS025';
patients(4).T_date = '140806';
patients(4).dataFile = {'00708'};
patients(4).BRdataFile = {'20140806-101438-001'};
patients(4).tasks = {'GoAntiGo'};

patients(3).subj='DBS023';
patients(3).T_date = '140530';
patients(3).dataFile = {'01711001';'01809'};
patients(3).BRdataFile = {'20140530-103554-001';'20140530-115504-001'};
patients(3).tasks = {'GoAntiGo'; 'GoAntiGo'};

patients(2).subj='DBS022';
patients(2).T_date = '140516';
patients(2).dataFile = {'00730001';'00400001'};
patients(2).BRdataFile = {'20140516-105400-001';'20140516-122720-001'};
patients(2).tasks = {'GoAntiGo'; 'GoAntiGo'};

patients(1).subj='DBS021';
patients(1).T_date = '140425';
patients(1).dataFile = {'01511';'01015001'};
patients(1).BRdataFile = {'20140425-103248-001';'20140425-103248-002'};
patients(1).tasks = {'GoAntiGo'; 'GoAntiGo'};

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