function DBSPrepAndAlign(homeDir, subject, T_date, behdataFiles, behTasks)
%This function takes in the data and name of a subject and exports all of
%the data using ao split. It also takes in the names of any mfiles for the
%subject that correspond to the flanker experiment and exports/aligns the
%events

% % homeDir = '/Volumes/Kareem/data/dbs/';
% % subject='DBS014'
% % T_date = '061213';
% % behdataFiles={'03502'; '-00593001'; '01507001'}
% % behTasks = {'Flanker'; 'Flanker'};
if nargin < 4 || isempty(behdataFiles)
    behdataFiles = {''};
end

subjDir=fullfile(homeDir,subject); rawDir=fullfile(subjDir,'raw'); 
make_dbs_readme_struct(homeDir, subject); % calls Andrew's function to turn readme file into a struct .mat file
matFiles=dir([rawDir '/*.mat']); % get all mat files in traj directory
matFiles={matFiles.name};

index1=1; %initialize variables. 
while index1<(length(matFiles)+1) % loop through mat files
    fileName=matFiles{index1};
    FIdx=regexp(fileName,'F');
    fileName=fileName(1:FIdx-1);
    samedepthfiles=matFiles(not(cellfun('isempty', strfind(matFiles, fileName))));
    index1=index1+length(samedepthfiles); % increase counter for the next round of while loop. 

    if isempty(dir(fullfile(homeDir,subject, 'eeg.noreref',sprintf('%s_%s_%s',subject,T_date,[fileName '*.jacksheet.txt']))))
        no_split(homeDir, subject, T_date, samedepthfiles) % extract ao .mat file to eegreref file
    else
        warning('Data for depth %s already exists. Skipping export for this depth.\n',fileName)
    end
        
    if ~isempty(find(strcmp(fileName, behdataFiles)));
        % Step 1: run extract[TASK]events to create an events structure
        session=num2str(find(strcmp(fileName, behdataFiles))-1);
        expDir=fullfile(homeDir,subject,'behavioral',behTasks{str2num(session)+1});
        events=eval(['extract' behTasks{str2num(session)+1} 'Events(subject,expDir,session);']) % extract the events from the session.log file
        savefile=fullfile(expDir,['session_' session], 'events.mat');
        save(savefile,'events');

        % Step 2: Align the two sets of data for LFPdata
        subj.sess.dir = fullfile(homeDir,subject,'behavioral',behTasks{str2num(session)+1}); %'/Volumes/shares/FRNU/dataworking/dbs/DBS021/behavioral/GoAntiGo';
        subj.sess.pulse_dir =fullfile(homeDir,subject,'eeg.noreref');% '/Volumes/shares/FRNU/dataworking/dbs/DBS020/eeg.noreref';
        syncfile=dir(fullfile(homeDir,subject, 'eeg.noreref',sprintf('%s_%s_%s*.sync.txt',subject,T_date,fileName))); % get all of the sync files recorded at that depth
        if length(syncfile)>1; error('ERROR_BZ: There can only be one sync file at each depth.'); end 
        subj.sess.eegfile = fullfile(homeDir,subject, 'eeg.noreref',regexprep(syncfile.name, '.sync.txt',''));%'/Volumes/shares/FRNU/dataworking/dbs/DBS020/eeg.noreref/DBS020_021214_1_00858';
        subj=DBSalign_subj(subj,session);
        display('Check alignment. If good enough (Max. Dev. < about 10 ms), type ''return'' and hit enter')
% 
        changeEventsEegFile(subject,homeDir, 'dataworking', 'data'); %change events pointer to the data directory
%             keyboard
    end
end

display('All done!');