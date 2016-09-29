function [rerefed_patients, non_rerefed_patients]=reref_all_pts(patients)
% reref_all_pts- References EEG recordings for all sessions of any number
% of patients.  This function uses all leads (leads.txt) to reref the data
%This function will print out a list of those patients that have been
%re-referenced and those that have not been re-rereferenced
%INPUTS:
%   pts: a cell array of patients
%   patients={'TJ005', 'TJ006'}
%   [rerefed_patients, non_rerefed_patients]=reref_all_pts(patients)
rerefed_patients={};
non_rerefed_patients={};

for n=patients
    if exist (['/data/eeg/', n{1}, '/docs/electrodes.m'], 'file') && exist (['/data/eeg/', n{1}, '/eeg.noreref/'], 'dir')
            % determines whether or not /data/eeg/patient/docs/electrodes.m
            % file exist and if there is an eeg.noreref directory.
    pt_dir=['/data/eeg/', n{1}];
    docs_dir=['/data/eeg/', n{1}, '/docs'];
    fileroots=make_file_roots(n{1}); %finds all of the unique eeg.noreref files
    outdir=['/data/eeg/', n{1}, '/eeg.reref.all'];
    taldir=['/data/eeg/', n{1}, '/tal'];
    cd(docs_dir) %changes directory into docs to load electrodes 
    electrodes;
    grids=r;
    
    cd(pt_dir)
    %reref_all(fileroots, grids, outdir, taldir)
    
    rerefed_patients{end+1}=n{1};
    
    else
        fprintf('electrodes.m does not exist for %s\n', n{1})
        non_rerefed_patients{end+1}=n{1};
    end
    
end