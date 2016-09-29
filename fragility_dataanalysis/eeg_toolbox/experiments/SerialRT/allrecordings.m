close all; 
clear all;

homeDir = '/Volumes/shares/FRNU/dataworking/dbs/';


%ViMs

patients(1).subj='DBS027';
patients(1).T_date = '141003';
patients(1).dataFile = {'-10000001'; '-10000002'};
patients(1).BRdataFile = [];
patients(1).NKdataFile = {'CA21115E';'CA21115G'};
patients(1).tasks = {'SerialRT'; 'SerialRT'};

%%

patients(cellfun('isempty',{patients.subj}))=[];
for patient=1:length(patients)
    patients(patient).subj
    DBSPrepAndAlign(homeDir,patients(patient).subj, patients(patient).T_date, patients(patient).dataFile, patients(patient).BRdataFile, patients(patient).NKdataFile, patients(patient).tasks)
end