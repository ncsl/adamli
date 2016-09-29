function [subs] = getSubs(exper)
%
% getAndSaveEvents.m
%
% This function outputs subjects for all experiments
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
experDir = fullfile(eventsDir,exper);

if strcmp(exper,'all')
   
  % look in eeg directory for list of all subjects
  NIHSubs = dir([eegDir '/NIH*']);
  TJSubs  = dir([eegDir '/TJ*']);
  UPSubs  = dir([eegDir '/UP*']);
  subs = [{NIHSubs.name} {TJSubs.name} {UPSubs.name}];
  
else
  % look in experiment's events directory for list of subjects 
  NIHSubs = dir([experDir '/NIH*']);
  TJSubs  = dir([experDir '/TJ*']);
  UPSubs  = dir([experDir '/UP*']);

  
  subs = [{NIHSubs.name} {TJSubs.name} {UPSubs.name}];

  for i = 1:length(subs)
    tmpsubs = subs{i};
    tmpsubs(ismember(tmpsubs,'.mat')) = [];
    subs{i} = tmpsubs;
  end

end
