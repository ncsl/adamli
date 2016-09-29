function [phase,zpow,broad,kInd] = getbroad(chan,events,DurationMS,OffsetMS,BufferMS,flagbroad,varargin)

%GETBROAD - Calculate Z-transformed power, phase and broadband shifts.
%
% This function will calculate Z-transformed power, normalized per each session,
% phase and broadband shifts for all the specified events and the specified
% time window
%
% This function uses getphasepow to calculate power.  You can pass
% optional args to getphasepow using the varargin at the end.
%
%
% FUNCTION:
%   [zpow,phase,kInd] = getbroad(chan,events,DurationMS,OffsetMS,BufferMS,flagbroad,varargin)
%
% INPUT ARGs:
%   chan = 2;
%   events = events;
%   DurationMS = 2000;
%   OffsetMS = 0;
%   BufferMS = 1000;
%
%   OPTIONAL PARAMS:
%
%     'flagbroad' - set to 'slow' to obtain the broadband shift for each point in
%               time (slower)
%                 - set to 'fast' to obtain the broadband averaged across time
%               (faster)
%     'freqs'
%     'width'
%     'filtfreq'
%     'filttype'
%     'filtorder'
%     'resampledrate' - resample applied before calculating phase/power
%     'downsample' - decimate applied after calculating power
%     'powonly'
%     'usesingles'
%     'kthresh'- Kurtosis threshold to throw out events.
%
% OUTPUT ARGS:
%   phase- (Events,Freqs,Time)
%   zpow- (Events,Freqs,Time)
%   broad- (Events,Time) if flagbroad=='slow' or (Events) if flagbroad=='fast'
%   kInd - logical indexes of the events that were not thrown out due to kurtosis
%   (if no phase is demanded then kInd will be the second output argument)
%


if( exist('flagbroad','var') && ~strcmp(flagbroad,'slow') && ~strcmp(flagbroad,'fast') )
    error('Error: The argument ''flagbroad'' must be a string and can either be ''fast'' or ''slow''');
end;

if ~exist('flagbroad','var')
  flagbroad='fast';
end

[phase,pow,kInd] = getphasepow(chan,events,DurationMS,OffsetMS,BufferMS,varargin{:});

pow(pow<=0) = eps;
pow = log10(pow);

zpow=zscorebysession(pow,events);


meanfr=mean(1:size(zpow,2));


if(strcmp(flagbroad,'slow'))
    
    broad=zeros(size(zpow,1),size(zpow,3));
    
    for e=1:size(zpow,1)
        fprintf('%d ',e);
        for t=1:size(zpow,3)
            fitz=robustfit(1:41,squeeze(zpow(e,:,t)));
            broad(e,t)=fitz(1)+meanfr*fitz(2);
        end;
    end;
    
  
else
    
    broad=zeros(size(zpow,1),1);
    
    zpow2=nanmean(zpow,3);    
    
    for e=1:size(zpow2,1)
        fprintf('%d ',e);
        fitz=robustfit(1:41,squeeze(zpow2(e,:)));
        broad(e)=fitz(1)+meanfr*fitz(2);
    end;
    
end;

fprintf('\n');



