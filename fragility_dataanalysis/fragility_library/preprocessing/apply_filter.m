function [filtered_eeg] = apply_filter(eeg, elec_labels, patient_id)
%APPLY_FILTER Summary of this function goes here
%   Detailed explanation goes here
    [N, T] = size(eeg);
    if N ~= length(elec_labels)
        fprintf('Number of electrodes in eeg does not match electrode labels!');
        exit
    end
    
    filtered_eeg = eeg;
    if strcmp(patient_id, 'EZT005')
        freqs_to_reject = 150;
        
        filtered_eeg = buttfilt(eeg, freqs_to_reject, 1000, 'low', 1);
    end
    
end

