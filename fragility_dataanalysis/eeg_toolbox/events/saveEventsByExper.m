function saveEventsByExper(overwrite,exper)
%
% getAndSaveEvents.m
%
% This function grabs and saves all events associated with the experimen
% for subjects in the EEG directory.  
% 
% Input Args
% overwrite          - overwrite current events directory
% exper              - experiment 
% subj               - subject
% Output Args
% 
% allEvents          - all events
% evEnc              - encoding events 
% evRec              - recall events




% define directories
motherDir = '/Volumes/kareem/';
dataDir   = fullfile(motherDir,'data');
eegDir    = fullfile(dataDir,'eeg');
eventsDir = fullfile(eegDir, 'events');

% get subjects
subs = getSubs('all');

% loop subjects
for s = 1:length(subs)

  % initialize variables
  allEvents = [];  
  
  % this subject
  subj = subs{s};  
  fprintf('SAVING %s \n',subj) 
  
  % event file location for experiment
  subjEventsExperFile = fullfile(eventsDir,exper,sprintf('%s.mat',subj));
  
  % if event file exists and overwite not indicated, go to next subject
  if exist(subjEventsExperFile) & ~overwrite; 
    fprintf('Event file exists & overwrite not indicated. Exiting.\n'); 
    continue; 
  end
  
  % if subject does not have experiment, go to next subject
  subjExperDir = fullfile(eegDir,subj,'behavioral',exper);     
  if ~exist(subjExperDir)
    fprintf('No experiment directory for this subject. Exiting.\n');
    continue;
  end
  
  % find sessions for this experiment
  sessDirs=dir([subjExperDir '/session_*']);
  
  % if no sessions, go to next subject
  if isempty(sessDirs)
    fprintf('No experimental sessions for this experiment. Exiting.\n');
    continue
  end
  
  % concatenate events for every session
  for d = 1:length(sessDirs)
  
    % events for this experiment, subject, and session
    evFile=fullfile(subjExperDir,sessDirs(d).name,'events.mat');
    
    if exist(evFile,'file')
      sessEvents = load(evFile);
      
      if ~isfield(sessEvents.events,'eegfile') 
        fprintf('this session has no eegfile field, skipped session \n') 
        continue
      end
      if ~isfield(sessEvents.events,'comprehension') & strcmp(exper,'languageTask')
        fprintf('this session has no comprehension field, skipped session \n') 
        continue
      end
      
      
      allEvents  = [allEvents sessEvents.events];
      
      
    end
  end

  if isempty(allEvents)
    fprintf('No events for this experiment. Exiting.\n');
    continue
  end  
  
  % save out events
  subjEventsExperDir = fullfile(eventsDir,exper);
  if ~exist(subjEventsExperDir,'dir'); mkdir subjEventsExperDir; end
  
  events = allEvents;

  save(subjEventsExperFile,'events')
  fprintf('DONE %s \n',subj) 
  
end

