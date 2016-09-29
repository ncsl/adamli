function[fixed_events] = events_wrapper(events,chan)

amp = get_freiburg_amp_by_chan(chan);
fixed_events = [];
for i = 1:length(events)
    next_event = events(i);
    if ~isempty(events(i).eegfile_micro)
        [eegpath,tmp] = fileparts(events(i).eegfile_micro);
        [~,eegfile] = fileparts(tmp);
        next_event.eegfile = fullfile(eegpath,'microeeg',eegfile);
        next_event.eegoffset = events(i).spike_time_amp(amp);
        fixed_events = [fixed_events next_event]; %#ok<AGROW>
    end
end
fixed_events = rmfield(rmfield(fixed_events,'eegfile_micro'),'spike_time_amp');