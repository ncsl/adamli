function elec_indices = findResectionIndices(all_labels, resection_areas)
    if nargin==0
%         patient = 'EZT011seiz001';
        patient = 'pt1sz2';
        
        % set patientID and seizureID
        patient_id = patient(1:strfind(patient, 'seiz')-1);
        seizure_id = strcat('_', patient(strfind(patient, 'seiz'):end));
        seeg = 1;
        if isempty(patient_id)
            patient_id = patient(1:strfind(patient, 'sz')-1);
            seizure_id = patient(strfind(patient, 'sz'):end);
            seeg = 0;
        end
        if isempty(patient_id)
            patient_id = patient(1:strfind(patient, 'aslp')-1);
            seizure_id = patient(strfind(patient, 'aslp'):end);
            seeg = 0;
        end
        if isempty(patient_id)
            patient_id = patient(1:strfind(patient, 'aw')-1);
            seizure_id = patient(strfind(patient, 'aw'):end);
            seeg = 0;
        end

        [included_channels, ezone_labels, earlyspread_labels, latespread_labels,...
            resection_labels, frequency_sampling, center] ...
                = determineClinicalAnnotations(patient_id, seizure_id);
        
        resection_areas = resection_labels;
        %%- Directory at work
        % set dir to find raw data files
        dataDir = fullfile('./data/', center);
            
        
        %% Set EEG Data Path
        if seeg
            patient_eeg_path = fullfile(dataDir, patient_id);
            patient = strcat(patient_id, seizure_id);
        else
            patient_eeg_path = fullfile(dataDir, patient);
        end
        patient_eeg_path
        patient

        %% LOAD DATA IN
        % READ EEG FILE Mat File
        % files to process
        try
            data = load(fullfile(patient_eeg_path, strcat(patient, '.mat')));
        catch e
            disp(e)
            data = load(fullfile(patient_eeg_path, strcat(patient_id, seizure_id, '.mat')));
        end
        eeg = data.data;
        all_labels = data.elec_labels;
        onset_time = data.seiz_start_mark;
        offset_time = data.seiz_end_mark;
        seizureStart = (onset_time); % time seizure starts
        seizureEnd = (offset_time); % time seizure ends
    end
    
    % refine the strings of the electrode labels
    all_labels = upper(all_labels);
    all_labels = strrep(all_labels, 'POL', '');
    
    % go through each resection area and find the indices within the labels
    % that contain the resected electrodes.
    elec_indices = [];
    for iArea=1:length(resection_areas)
        indices = find(~cellfun(@isempty, cellfun(@(x)strfind(x, resection_areas{iArea}), all_labels, 'uniform', 0)));
        
        if isempty(elec_indices)
            elec_indices = indices;
        else
            try
                elec_indices = cat(2, elec_indices, indices);
            catch
                elec_indices = cat(1, elec_indices, indices);
            end
        end
    end
    
end