function [goodevents] = removebadevents(events)

%REMOVEBADEVENTS - Removes bad events from an events structure
%
% This function takes as input a structure of events and removes the events
% formatted in the wrong way or linking to bad eeg data
%
% FUNCTION:  [goodevents] = removebadevents(events)
%
% INPUT ARGs:
%   events - the events structure
% 
% OUTPUT ARGS:
%   goodevents - a structure containing only the good events
%

if(~isfield(events,'eegfile'))
    error('The field ''eegfile'' is not present in the ''events'' structure');
end;

eegstrings={events.eegfile};

badevents=length(find(cellfun('isempty',strfind(eegstrings,'noreref'))==0));
if(badevents>0)
    fprintf('Warning: %d events are linking to not rereferenced data: deleted\n',badevents);
    events=filterStruct(events,'cellfun(''isempty'',strfind(eegfile,''noreref''))');
end;


badevents2=length(find(cellfun('isempty',eegstrings)==1));
if(badevents2>0)
    fprintf('Warning: %d events do not specify any eeg file: deleted\n',badevents2);
    events=filterStruct(events,'~strcmp(eegfile,'''')');
end;


if(isempty(events))
    error('Error: No events left');
end; 


if(~isfield(events,'session'))
    fprintf('Warning: The field ''session'' is not present in the ''events'' structure\n');
end;

goodevents=events;

