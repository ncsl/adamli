function fileroots = make_files_roots(subject)
% fileroots = make_files_roots(subject)

fileroots = {};
d = dir(fullfile('/data/eeg/',subject,'eeg.noreref'));

names = {};
for i = 1:length(d)
    [p,n,e] = fileparts(d(i).name);
    if (~isempty(strmatch(subject,n)) && strmatch(subject,n)) ...
            && ~isempty(str2num(e))
        names{end+1} = ['eeg.noreref/',n];
    end
end
fileroots = unique(names);
