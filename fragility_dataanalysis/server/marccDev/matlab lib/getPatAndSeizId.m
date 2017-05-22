function [pat_id, seiz_id, is_seeg] = getPatAndSeizId(patient)
    % set patientID and seizureID
    pat_id = patient(1:strfind(patient, 'seiz')-1);
    seiz_id = strcat('_', patient(strfind(patient, 'seiz'):end));
    is_seeg = 1;
    if isempty(pat_id)
        pat_id = patient(1:strfind(patient, 'sz')-1);
        seiz_id = patient(strfind(patient, 'sz'):end);
        is_seeg = 0;
    end
    if isempty(pat_id)
        pat_id = patient(1:strfind(patient, 'aslp')-1);
        seiz_id = patient(strfind(patient, 'aslp'):end);
        is_seeg = 0;
    end
    if isempty(pat_id)
        pat_id = patient(1:strfind(patient, 'aw')-1);
        seiz_id = patient(strfind(patient, 'aw'):end);
        is_seeg = 0;
    end
end