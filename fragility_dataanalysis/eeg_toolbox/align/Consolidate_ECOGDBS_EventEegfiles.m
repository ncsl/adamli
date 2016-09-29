function Consolidate_ECOGDBS_EventEegfiles(eventsfile, varargin)
%ConsolidateEventEegfiles   
% when two machines were used to record data, two eegoffsets and eegfiles
% must be created to align the two data sets. This script then takes those
% off sets and files, either lengthens or shortens the blackrock files so 
% they begin at the same time as the ao or nk files. This results in only 
% one eegoffset being needed. The BReegfiles are then renamed and saved to 
% the names of the eegfiles.
%
%
%  align_subj(eventsfile, ...)
%
%  INPUTS:
%    eventsfile: the filenames of the events.mat file that has the two
%                eegoffsets. 
%                '/Volumes/shares/FRNU/dataworking/dbs/DBS021/behavioral/GoAntiGo/session_1/events.mat'
%
%  OUTPUTS: none
%
%  Optional PARAMS:
%  These options may be specified using parameter. Defaults are shown in parentheses.

%   'useregressionforfit' -Send in this string to use regression to determine the best offset.
%                         By default, the script uses the average difference 
%                         between the eegoffset and the BReegoffset to determine 
%                         how much earlier (or later) the BR started recording 
%                         data relative to the ao or nk machines.  
%                          
% 'comparebeforeandafter' - Send in this string to plot the eegdata for one  
%                           event before and after the files were changed
%  'continuechanname'     - Send in this string and the new BR filenames will be a numerical 
%                         continuation of the ao/nk filenames found in the 
%                         ao/nk jacksheet. By default, the code will just add 500 to the
%                         channel number the BR files were originally saved under

useregressionforfit = 0; % by default use simple fit
comparebeforeandafter = 0; %by default dont compare the plots
continuechanname = 0; % by default just add 500 to the old channel name

if (~isempty(varargin))
    for c=1:length(varargin)
        switch varargin{c}
            case {'comparebeforeandafter'}
                comparebeforeandafter = 1;
            case {'useregressionforfit'}
                useregressionforfit=1;
            case {'continuechanname'}
                continuechanname=1;            
        otherwise         
            error(['Invalid optional argument, ', ...
                varargin{c}]);
        end % switch
    end % for
end % if
    
    
load(eventsfile); % load the events struct
alignedevents=find(~cellfun(@isempty,({events.eegfile}))); % find the events that were actually aligned
firstalignedevent=alignedevents(1); % find the first event with an eegfile

if useregressionforfit==0
    %do a simple subtraction to find the mean differnce between the eegoffset and BReegoffset
    offsetdiff=[events(alignedevents).eegoffset]-[events(alignedevents).BReegoffset];
    offset=round(mean(offsetdiff));
    % check that the offsets are not off by much
    if std(offsetdiff)>5 | (max(offsetdiff)-min(offsetdiff))>10 | max(abs([events(alignedevents).BReegoffset]+offset-[events(alignedevents).eegoffset])) >10
        warning('There is a large deviation between the offsets. Check if pulses were aligned correctly.')
        keyboard
    end
else  %use the regression code for the fit. More complicated but gives slightly better fit
    bfix = events(firstalignedevent).BReegoffset;
    [b,bint,r,rin,stats] = regress([events(alignedevents).eegoffset]', [ones(length([events(alignedevents).BReegoffset]),1) [events(alignedevents).BReegoffset]'-bfix]);
    b(1) = b(1) - bfix*b(2);

    % calc max deviation
    act=round([ones(length([events(alignedevents).BReegoffset]),1) [events(alignedevents).BReegoffset]']*b(:));
    maxdeveeg = max(abs(act - [events(alignedevents).eegoffset]'));
    meddeveeg = median(abs(act - [events(alignedevents).eegoffset]'));
    offset=round(mean(act - [events(alignedevents).BReegoffset]'));
    maxdevBR =max(abs(act - [events(alignedevents).BReegoffset]'-offset));
    meddevBR =median(abs(act - [events(alignedevents).BReegoffset]'-offset));
    fprintf('BReegoffset vs eegoffset regression statistics:');
    fprintf('\tRegression Slope  = %f\n', b(2));
    fprintf('\tR^2               = %f\n', stats(1));
    fprintf('\tMedian Deviation EEG  = %f ms\n', meddev);
    fprintf('\tMax Deviation EEG    = %f ms\n', maxdev);
    fprintf('\tMedian Deviation BREEG  = %f ms\n', meddevBR);
    fprintf('\tMax Deviation BREEG    = %f ms\n', maxdevBR);

    % check that the offsets are not off by much
        % look for red flags and provide additional plots if helpful
        if maxdev>5 | maxdevBR>5,       strWarning = sprintf('%s WARNING: max deviation (%f ms) is >5 ms\n', strWarning, maxdev);    end;
        if stats(1)<0.98,  strWarning = sprintf('%s WARNING: regression R^2 (%f)   is <0.98\n', strWarning, stats(1));  end;
end

% find the file stem name
eegfile=regexprep(events(firstalignedevent).eegfile,'eeg.reref','eeg.noreref');
BReegfile=regexprep(events(firstalignedevent).BReegfile,'eeg.reref','eeg.noreref');

rerefindex=regexp(eegfile, '/eeg.noreref/');
if ~strcmp(eegfile(1:rerefindex),BReegfile(1:rerefindex))
    error('eegfile and BReegfile do not point to the same folder')
end

% open the jacksheet files
fideegjack=fopen([eegfile '.jacksheet.txt']);
jacksheeteeg=textscan(fideegjack, '%d %s');
fclose(fideegjack);
fidBReegjack=fopen([BReegfile '.jacksheet.txt']);
jacksheetBR=textscan(fidBReegjack, '%d %s');
fclose(fidBReegjack);
channameoffset=500; % by default, the new channels will be the same as they were originally saved plus 500
if continuechanname==1
    channameoffset=jacksheeteeg{1}(end);
end

if comparebeforeandafter % plot the aligned date of one event before the manipulations
    sentevent=events(firstalignedevent);
    sentevent.eegfile=sentevent.BReegfile;
    sentevent.eegoffset=sentevent.BReegoffset;
    [EEG] = gete_ms(jacksheetBR{1}(1),sentevent,1000);
    figure; hold on; plot(EEG); 
end

% load the Blackrock saved files from the noreref directory
BRdirectory=BReegfile(1:rerefindex);
BRfilestem=BReegfile(rerefindex+length('/eeg.noreref/'):end);
eegfilestem=eegfile(rerefindex+length('/eeg.noreref/'):end);
BRFiles=filterStruct(dir([BRdirectory 'eeg.noreref']),{['~isempty(regexp(name,''' BRfilestem '''))']}); % get all event's BR files in reref directory
for channel=1:length(BRFiles)
    if ~isempty(regexp(BRFiles(channel).name, 'jacksheet')) | ~isempty(regexp(BRFiles(channel).name, 'sync')) | ~isempty(regexp(BRFiles(channel).name, 'params'))% check if file is jacksheet or sync or params file
        delete([BRdirectory 'eeg.noreref/' BRFiles(channel).name]); % delete the old jacksheet and old sync file        
        continue
    end
    
    % read data
    fidBRfile=fopen([BRdirectory 'eeg.noreref/' BRFiles(channel).name]);
    BRdata=fread(fidBRfile,'int16');
    fclose(fidBRfile);
    if offset<0 % if BR started recording earlier than the other machine, remove the earlier indexes
        BRdata(1:abs(offset))=[];
    else % if BR started recording after the other machine, pad with zeros
        BRdata=[zeros(abs(offset),1); BRdata]; 
    end
    dotindex=find(BRFiles(channel).name== '.');
    fidnewchan=fopen(sprintf('%seeg.noreref/%s.%03i',BRdirectory,eegfilestem,channameoffset+str2num(BRFiles(channel).name(dotindex+2:end))), 'w');
    fwrite(fidnewchan, BRdata, 'int16');
    fclose(fidnewchan);
    delete([BRdirectory 'eeg.noreref/' BRFiles(channel).name]); % delete the data file        

    % save channel to jacksheet
    jacksheetBRindex=find(jacksheetBR{1}==str2num(BRFiles(channel).name(end-2:end)));
    jacksheeteeg{1}=[jacksheeteeg{1}; channameoffset+jacksheetBR{1}(jacksheetBRindex)]; %add the channel+500
    jacksheeteeg{2}=[jacksheeteeg{2}; jacksheetBR{2}(jacksheetBRindex)];%add the channel label
end

%save the new jacksheet
fidnewjack=fopen([BRdirectory 'eeg.noreref/' eegfilestem '.jacksheet.txt'], 'w');
for channel=1:length(jacksheeteeg{1})
    fprintf(fidnewjack,'%d %s\n',jacksheeteeg{1}(channel),jacksheeteeg{2}{channel}); 
end
fclose(fidnewjack);



% load the Blackrock saved files from the reref directory
BRFiles=filterStruct(dir([BRdirectory 'eeg.reref']),{['~isempty(regexp(name,''' BRfilestem '''))']}); % get all event's BR files in reref directory
for channel=1:length(BRFiles)
    if ~isempty(regexp(BRFiles(channel).name, 'jacksheet')) | ~isempty(regexp(BRFiles(channel).name, 'sync')) | ~isempty(regexp(BRFiles(channel).name, 'params'))% check if file is jacksheet or sync or params file
        delete([BRdirectory 'eeg.reref/' BRFiles(channel).name]); % delete the data file        
    end
    
    % read data
    fidBRfile=fopen([BRdirectory 'eeg.reref/' BRFiles(channel).name]);
    BRdata=fread(fidBRfile,'int16');
    fclose(fidBRfile);
    if offset<0 % if BR started recording earlier than the other machine, remove the earlier indexes
        BRdata(1:abs(offset))=[];
    else % if BR started recording after the other machine, pad with zeros
        BRdata=[zeros(abs(offset),1); BRdata]; 
    end
    dotindex=find(BRFiles(channel).name== '.');
    dashindex=find(BRFiles(channel).name== '-');
    if isempty(dashindex)
        fidnewchan=fopen(sprintf('%seeg.reref/%s.%03i',BRdirectory,eegfilestem,channameoffset+str2num(BRFiles(channel).name(dotindex+2:end))), 'w');
    else
        fidnewchan=fopen(sprintf('%seeg.reref/%s.%03i-%03i',BRdirectory,eegfilestem,channameoffset+str2num(BRFiles(channel).name(dotindex+2:dotindex+3)), channameoffset+str2num(BRFiles(channel).name(dashindex+2:end))), 'w');
    end
    fwrite(fidnewchan, BRdata, 'int16');
    fclose(fidnewchan);
    delete([BRdirectory 'eeg.reref/' BRFiles(channel).name]); % delete the data file         
end


events = rmfield(events,{'BReegfile'; 'BReegoffset'});
save(eventsfile, 'events')

if comparebeforeandafter % plot the aligned date of one event before the manipulations
    sentevent=events(firstalignedevent);
    [EEG] = gete_ms(jacksheetBR{1}(1)+channameoffset,sentevent,1000);
    plot(EEG, 'r:'); legend('old', 'new'); 
end
    
