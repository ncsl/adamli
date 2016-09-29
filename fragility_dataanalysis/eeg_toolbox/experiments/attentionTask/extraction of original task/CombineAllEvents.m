
% allEvents1.m
%
% This function grabs all events associated with the attention task for a
% given subject.  Assumes that we are in a subject directory, and
% looks for events file in subdirectories.
%
% Input Args
%
% behDir='/Users/ellenbogenrl/Rachel/data/eeg/NIH016/behavioral/attentionTask/';
% Output Args
% 
% allEventsevents          - all events

%

function [events]= allEvents1(behDir)


% Initialize variable
events=[];

% Set directories

if ~exist(behDir)
  fprintf('No behavioral directory for Attention. Exiting.\n');
  return
end

% Find what sessions were performed
sessDirs=dir([behDir 'session_*']);
if isempty(sessDirs)
  fprintf('No experimental sessions for Attention. Exiting.\n');
  return
end

% Get the events
allEvents=[];
for d=1:length(sessDirs)
  evFile=fullfile(behDir,sessDirs(d).name,'events.mat');

  if exist(evFile)
    load(evFile);
  end
  allEvents=[allEvents, events];
end

if isempty(allEvents)
  fprintf('No events for Attention. Exiting.\n');
  return
end  

% Change name
events=allEvents;

%save(behDir,'/events.mat', 'events');