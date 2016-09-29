function [zpow] = zscorebysession(pow,events,powbas,eventsbas)

%ZSCOREBYSESSION - Calculates Z-transformed power normalized within each
%                  session
%
% This function takes as input a power matrix and the relative structure of
% events and calculates the z-transformed power normalized within each
% session.
% 
% The matrix of power can be obtained from getphasepow. Before using the
% present function, it can be useful to compute the logarithm of the power.
% The number of events must be equal to the number of rows of the power
% matrix.
% 
% It is possible to specify another power matrix to be used as the baseline
% to compute the z-scores. Another structure of events must be provided,
% and the number of sessions must match.
%
%
% FUNCTION:
%   [zpow] = zscorebysession(pow,events,powbas,eventsbas)
%
% INPUT ARGs:
%   pow - the power to be normalized
%   events - the events relative to the power to be normalized
% 
% OPTIONAL PARAMS:
%   powbas - if specified, it is used to compute the baseline
%   eventsbas - the events relative to the power used to compute the baseline
%
% OUTPUT ARGS:
%   zpow - the matrix of normalized powers
%



%%% Some controls


if ~exist('pow','var')
  fprintf('Error: missing argument ''pow''');
end

if ~exist('events','var')
  fprintf('Error: missing argument ''events''');
end

if (exist('powbas','var') && ~exist('eventsbas','var'))
  fprintf('Error: missing argument ''eventsbas''');
end

if (length(events)~=size(pow,1))
   fprintf('Error: the matrix of powers and the events structure don''t match');
end;
    
if (exist('powbas','var') && (length(eventsbas)~=size(powbas,1)) )
   fprintf('Error: the matrix of baseline powers and the relative events structure don''t match');
end
    
if (exist('powbas','var') && ( ~issame(unique([events.session]),unique([eventsbas.session])) ) )
   fprintf('Error: the sessions in the events structures don''t match');
end



%%% Computation of the z-scores within each session




zpow=pow; % preallocation of zpow for speed


if exist('powbas','var')

    ses=[events.session];
    sesbas=[eventsbas.session];
    
    for i=unique(ses)
        
        eventsses = ses==i;
        eventssesbas = sesbas==i;
        
        zmean = nanmean(nanmean(powbas(eventssesbas,:,:),3),1);
        zstd = nanstd(nanmean(powbas(eventssesbas,:,:),3),0,1);
        
        zpow(eventsses,:,:)=bsxfun(@rdivide, bsxfun(@minus, pow(eventsses,:,:), zmean), zstd);
        
        
    end;
    
else
    
    ses=[events.session];
    
    for i=unique(ses)
        
        eventsses = ses==i;
        
        zmean = nanmean(nanmean(pow(eventsses,:,:),3),1);
        zstd = nanstd(nanmean(pow(eventsses,:,:),3),0,1);

        zpow(eventsses,:,:)=bsxfun(@rdivide, bsxfun(@minus, pow(eventsses,:,:), zmean), zstd);
        
    end;
    
end;

