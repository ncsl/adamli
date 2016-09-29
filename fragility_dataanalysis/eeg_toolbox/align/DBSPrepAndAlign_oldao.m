function DBSPrepAndAlign_oldao(homeDir, subject, T_date, behdataFiles,BRbehdataFiles,NKbehdataFiles, behTasks)
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
tracks_dir=dir(fullfile(rawDir,'traj*'));
track_name=tracks_dir(1).name; track_no=str2double(track_name(end));

for index1=track_no:3:(track_no+length(dir(fullfile(rawDir,'traj*')))-1)
    trajName=['traj' num2str(index1)]; 
    trajDir=fullfile(rawDir,trajName);
    matFiles=filterStruct(dir(trajDir),{'~isempty(regexp(name,''.mat''))'}); % get all mat files in traj directory
    
    for index2=1:length(matFiles) % loop through mat files
        fileName=matFiles(index2).name;
        matIdx=regexp(fileName,'.mat');
        fileName=fileName(1:matIdx-1);
        if isempty(find(strcmp(fileName, behdataFiles)));
            ao_split(homeDir, subject, T_date, trajName(5:end), fileName, 0) % extract ao .mat file to eegreref file
        else
            % Step 1: run extract[TASK]events to create an events structure
            session=num2str(find(strcmp(fileName, behdataFiles))-1);
            expDir=fullfile(homeDir,subject,'behavioral',behTasks{str2num(session)+1});
            events=eval(['extract' behTasks{str2num(session)+1} 'Events(subject,expDir,session);']) % extract the events from the session.log file
            savefile=fullfile(expDir,['session_' session], 'events.mat');
            save(savefile,'events');
            
            % Step 2: split the AO raw data into channel data and spike data
            ao_split(homeDir, subject, T_date, trajName(5:end), fileName, 1)
            if ~isempty(BRbehdataFiles{str2num(session)+1})
                [EEGfilestem]=br_split(homeDir, subject, T_date, BRbehdataFiles{str2num(session)+1}, 1)
            elseif ~isempty(NKbehdataFiles{str2num(session)+1})
                [EEGfilestem]=nk_split_dbs_wrapper(homeDir, subject, session);    
            end
            
            % Step 3: Align the two sets of data for ecog data
            if ~isempty(BRbehdataFiles{str2num(session)+1}) || ~isempty(NKbehdataFiles{str2num(session)+1})
                subj.sess.dir = fullfile(homeDir,subject,'behavioral',behTasks{str2num(session)+1}); %'/Volumes/shares/FRNU/dataworking/dbs/DBS021/behavioral/GoAntiGo';
                subj.sess.eegfile = fullfile(homeDir,subject, 'eeg.noreref',EEGfilestem);%'/Volumes/shares/FRNU/dataworking/dbs/DBS021/eeg.noreref/DBS021_140425_1045;
                subj.sess.pulse_dir =fullfile(homeDir,subject,'eeg.noreref');% '/Volumes/shares/FRNU/dataworking/dbs/DBS021/eeg.noreref';
                subj=DBSalign_subj(subj,session);
                load(savefile,'events');
                [events.BReegfile]=events.eegfile;
                [events.BReegoffset]=events.eegoffset;
                events = rmfield(events,{'eegfile'; 'eegoffset'});
                save(savefile,'events');
                display('Check alignment. If good enough (Max. Dev. < about 10 ms), type ''return'' and hit enter')
            end
                
            % Step 4: Align the two sets of data for LFPdata
            subj.sess.dir = fullfile(homeDir,subject,'behavioral',behTasks{str2num(session)+1}); %'/Volumes/shares/FRNU/dataworking/dbs/DBS021/behavioral/GoAntiGo';
            subj.sess.eegfile = fullfile(homeDir,subject, 'eeg.noreref',sprintf('%s_%s_%s_%s',subject,T_date,trajName(5:end),fileName));%'/Volumes/shares/FRNU/dataworking/dbs/DBS020/eeg.noreref/DBS020_021214_1_00858';
            subj.sess.pulse_dir =fullfile(homeDir,subject,'eeg.noreref');% '/Volumes/shares/FRNU/dataworking/dbs/DBS020/eeg.noreref';
            subj=DBSalign_subj(subj,session);
            display('Check alignment. If good enough (Max. Dev. < about 10 ms), type ''return'' and hit enter')
            
            %step 5: consolidate the BReegfiles and the eegfiles 
            if ~isempty(BRbehdataFiles{str2num(session)+1}) || ~isempty(NKbehdataFiles{str2num(session)+1})
                Consolidate_ECOGDBS_EventEegfiles(savefile, 'comparebeforeandafter');
            end
            
            changeEventsEegFile(subject,homeDir, 'dataworking', 'data'); %change events pointer to the data directory
%             keyboard
        end
    end
end