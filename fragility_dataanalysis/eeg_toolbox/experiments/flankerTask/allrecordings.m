close all; 
clear all;

homeDir = '/Volumes/shares/FRNU/dataworking/dbs/';


%GPis
patients(17).subj='DBS030';
patients(17).T_date = '141217';
patients(17).dataFile = {'01032'; '01507001'};
patients(17).BRdataFile = {'gpi121714righthandleftgpi','gpi121714rightgpi'};
patients(17).NKdataFile = [];
patients(17).tasks = {'Flanker'; 'Flanker'};

patients(16).subj='DBS026';
patients(16).T_date = '141001';
patients(16).dataFile = {'-00076001'; '-00977001'};
patients(16).BRdataFile = [];
patients(16).NKdataFile = {'CA211159';'CA21115B'};
patients(16).tasks = {'Flanker'; 'Flanker'};

patients(15).subj='DBS008';
patients(15).T_date = '103112';
patients(15).dataFile = {'01510001'; '01010001'};

patients(14).subj='DBS004';
patients(14).T_date = '051512';
patients(14).dataFile = {'02921'};


% STNs

patients(13).subj='DBS015';
patients(13).T_date = '073113';
patients(13).dataFile = {'00512001'};

patients(12).subj='DBS014';
patients(12).T_date = '061213';
patients(12).dataFile = {'03502';'-00593001'};

patients(11).subj='DBS013';
patients(11).T_date = '052213';
patients(11).dataFile = {'02495001'};

patients(10).subj='DBS012';
patients(10).T_date = '051513';
patients(10).dataFile = {'01068002';'00887';'-00116'};

patients(9).subj='DBS011';
patients(9).T_date = '030113';
patients(9).dataFile = {'00000001'; '00500001'};

patients(8).subj='DBS010';
patients(8).T_date = '010913';
patients(8).dataFile = {'-06007001'; '00999'};

patients(7).subj='DBS009';
patients(7).T_date = '112812';
patients(7).dataFile = {'-0048'; '00476'};

patients(6).subj='DBS007';
patients(6).T_date = '072312';
patients(6).dataFile = {'00013001'};

patients(5).subj='DBS006'; 
patients(5).T_date = '062912';
patients(5).dataFile = {'-00491001'};

patients(4).subj='DBS005';
patients(4).T_date = '062712';
patients(4).dataFile = {'00019002'; '-01678'; '00020001'};

patients(3).subj='DBS003';
patients(3).T_date = '022912';
patients(3).dataFile = {'00513001'; '-0031'};

patients(2).subj='DBS001';
patients(2).T_date = '120911';
patients(2).dataFile = {'00798'; '00998'};

patients(1).subj='DBS000';
patients(1).T_date = '120211';
patients(1).dataFile = {'00558'; '01013001'};

%%

patients(cellfun('isempty',{patients.subj}))=[];
for patient=1:length(patients)
    patients(patient).subj
    DBSPrepAndAlign(homeDir,patients(patient).subj, patients(patient).T_date, patients(patient).dataFile, patients(patient).BRdataFile, patients(patient).NKdataFile, patients(patient).tasks)
end