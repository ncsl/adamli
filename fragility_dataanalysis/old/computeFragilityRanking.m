clear all;
close all;

% script: computeFragilityRanking
% helps recompute fragility ranking based on how we want to define
% fragility after minimum norm perturbation.

patients = {'EZT030_seiz002'};

perturbationTypes = ['R', 'C'];
radius = 1.5;             % spectral radius
winSize = 500;            % 500 milliseconds
stepSize = 500; 
frequency_sampling = 1000; % in Hz

for pat_id=1:length(patients)
    patient = patients{pat_id};
    
    patient_id = patient(1:strfind(patient, 'seiz')-1);
    seizure_id = strcat('_', patient(strfind(patient, 'seiz'):end));
    seeg = 1;
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'sz')-1);
        seizure_id = patient(strfind(patient, 'sz'):end);
        seeg = 0;
    end
    
    for p=1:length(perturbationTypes) % loop through pertrubatrion types
        perturbationType = perturbationTypes(p);
        
        finalDataDir = fullfile(strcat('./adj_mats_win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), strcat(perturbationType, '_finaldata', ...
            '_radius', num2str(radius)));
        load(fullfile(finalDataDir, strcat(patient, 'final_data.mat')));
        
        fragility_rankings = zeros(size(minPerturb_time_chan));
        minPerturb_time_chan = minPerturb_time_chan / max(minPerturb_time_chan(:));
        max(minPerturb_time_chan(:))
        min(minPerturb_time_chan(:))
        %% 3. Compute fragility rankings per column by normalization
% fragility_rankings = zeros(size(minPerturb_time_chan,1),size(minPerturb_time_chan,2));
% for i=1:size(minPerturb_time_chan,1)      % loop through each channel
%     for j=1:size(minPerturb_time_chan, 2) % loop through each time point
%         fragility_rankings(i,j) = (max(minPerturb_time_chan(:,j)) - minPerturb_time_chan(i,j)) ...
%                                     / max(minPerturb_time_chan(:,j));
%     end
% end
        
    end
end