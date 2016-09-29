%This script aligns and sorts the events so that the events are separated
%by type of event and they are aligned so that each encoding event is
%aligned with the proper recall event. The events are then sorted by
%condition so that all corrects, intrusions, passes, and vocalizations are placed in
%separate groups. This script saves the sorted, aligned, and grouped events
%in a 1x3 cell called eventsByCondition. 

close all
clear all

pat_ids = {'NIH001', 'NIH003', 'NIH004', 'NIH005', 'NIH006', ...
           'NIH007', 'NIH009', 'NIH012', 'NIH013', 'NIH016', ...
           'NIH017', 'NIH018', 'NIH024', 'TJ025',  'TJ027',  ...
           'TJ028',  'TJ029' , 'TJ030',  'TJ031' , 'TJ032' , ...
           'TJ036' , 'TJ039' , 'TJ041_2','TJ047' , 'TJ060' , ...
           'TJ064' , 'TJ065',  'UP020' , 'UP021' , 'UP028' , ...
           'UP029'};

for pat = pat_ids
    try
        pat_s = pat{1};
        display(pat_s)
        pat_tag = pat_s(1:end-3);
        if strcmp(pat_tag,'NIH')
            num_per_sess = 15;
        else
            num_per_sess = 25;
        end
        load(['/Users/vazap/Alex/patient events/' pat_s '_all_events.mat'])
        sortedEvents = sortEvents(events);
        alignedEvents = alignEvents(sortedEvents);
        alignedEventsIds = add_ids_to_events(alignedEvents);
        ids = unique(getStructField(alignedEventsIds.REC_EVENT,'id'));
        
        %{
        sess = 0;
        list = 1;
        spos = 1;
        for i = 1:numel(ids)
            id = ['id' dec2base(sess,10,3) dec2base(list,10,3) dec2base(spos,10,3)];
            if ~strcmp(id,ids{i})
                keyboard
                break
            end
            spos = spos + 1;
            if spos==5
                spos = 1;
                list = list + 1;
                if list==num_per_sess+1
                    list = 1;
                    sess = sess + 1;
                end
            end
        end
        %}
        %display(numel(ids))
        prunedEvents = pruneEvents(alignedEventsIds,ids);
        %sort by condition now
        eventsByCondition = sortByCondition(prunedEvents);
        num_each = [numel(eventsByCondition{1}.REC_EVENT) numel(eventsByCondition{2}.REC_EVENT) numel(eventsByCondition{3}.REC_EVENT)];
        if sum(num_each)~=numel(ids)
            keyboard
        end
        %keyboard
        %{
        numevents = numel(alignedEvents.REC_EVENT);
        %account for different markings for TJ060, TJ064, and TJ065   
        for e = 1:numevents
            if alignedEvents.REC_EVENT(e).correct==1
                alignedEvents.REC_EVENT(e).pass = 0;
                alignedEvents.REC_EVENT(e).intrusion = 0;
            else
                switch alignedEvents.REC_EVENT(e).resp_word

                    case 'PASS'
                        alignedEvents.REC_EVENT(e).pass = 1;
                        alignedEvents.REC_EVENT(e).intrusion = 0;
                    case {'','<>'}
                        switch pat_s
                            case {'TJ060','TJ064','TJ065'}
                                alignedEvents.REC_EVENT(e).RT = nan;
                                alignedEvents.REC_EVENT(e).pass = 1;
                                alignedEvents.REC_EVENT(e).intrusion = 0;
                            otherwise
                                if alignedEvents.REC_EVENT(e).vocalization~=1
                                    alignedEvents.REC_EVENT(e).RT = nan;
                                    alignedEvents.REC_EVENT(e).pass = 1;
                                    alignedEvents.REC_EVENT(e).intrusion = 0;
                                end
                        end
                            
                        
                    otherwise
                        switch pat_s
                            case {'TJ060','TJ064','TJ065'}
                                alignedEvents.REC_EVENT(e).pass = 0;
                                alignedEvents.REC_EVENT(e).intrusion = 1;
                            otherwise
                                if alignedEvents.REC_EVENT(e).vocalization~=1
                                    alignedEvents.REC_EVENT(e).pass = 0;
                                    alignedEvents.REC_EVENT(e).intrusion = 1;
                                end
                        end
                        
                end
                %{
                if strcmp(alignedEvents.REC_EVENT(e).resp_word,'PASS') || strcmp(alignedEvents.REC_EVENT(e).resp_word,'<>')

                    if strcmp(alignedEvents.REC_EVENT(e).resp_word,'<>')

                    end
                elseif alignedEvents.REC_EVENT(e).intrusion==0 || alignedEvents.REC_EVENT(e).intrusion==-1

                else
                    keyboard
                end
                %}
            end
        end

        for e = 1:numevents
            if alignedEvents.REC_EVENT(e).RT==0
                display(e)
                alignedEvents.REC_EVENT(e).RT = nan;
                
            end
        end
        [eventsByCondition indsByCondition] = sortByCondition(alignedEvents);
        
        save([pat_s '_events_by_cond.mat'],'eventsByCondition','indsByCondition')
        
        %}
        save([pat_s '_events_by_cond.mat'],'eventsByCondition')
    catch thatdidntwork
        show_error(thatdidntwork)
        keyboard
    end
end