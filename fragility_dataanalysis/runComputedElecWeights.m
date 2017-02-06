patients = {...,
%      'pt1aw1','pt1aw2', ...
%     'pt1aslp1', 'pt1aslp2', ...
%     'pt2aw1', 'pt2aw2', ...
%     'pt2aslp1', ...
%     'pt2aslp2', ...
%     'pt3aslp1', 'pt3aslp2', ...
%     'pt3aw1', ...
%     'pt3aslp1', 'pt3aslp2', ...
%     'pt1sz2' 'pt1sz3' 'pt1sz4',...
%     'pt2sz1' 'pt2sz3',... %'pt2sz4', ...
    'pt3sz2' 'pt3sz4', ...
    'pt6sz3' 'pt6sz4' 'pt6sz5',...
    'pt8sz1' 'pt8sz2' 'pt8sz3',...
    'pt10sz1' 'pt10sz2' 'pt10sz3', ...
    'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
    'pt14sz1' 'pt14sz2' 'pt14sz3', ...
     'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
    'pt16sz1' 'pt16sz2' 'pt16sz3',...
    'pt17sz1' 'pt17sz2',...
%     'JH101sz1' 'JH101sz2' 'JH101sz3' 'JH101sz4',...
% 	'JH102sz1' 'JH102sz2' 'JH102sz3' 'JH102sz4' 'JH102sz5' 'JH102sz6',...
% 	'JH103sz1' 'JH103sz2' 'JH103sz3',...
% 	'JH104sz1' 'JH104sz2' 'JH104sz3',...
% 	'JH105sz1' 'JH105sz2' 'JH105sz3' 'JH105sz4' 'JH105sz5',...
% 	'JH106sz1' 'JH106sz2' 'JH106sz3' 'JH106sz4' 'JH106sz5' 'JH106sz6',...
% 	'JH107sz1' 'JH107sz2' 'JH107sz3' 'JH107sz4' 'JH107sz5' 
%     'JH107sz6' 'JH107sz7' 'JH107sz8' 'JH107sz9',...
%    'JH108sz1', 'JH108sz2', 'JH108sz3', 'JH108sz4', 'JH108sz5', 'JH108sz6', 'JH108sz7',...
%    'EZT037seiz001', 'EZT037seiz002',...
%    'EZT019seiz001', 'EZT019seiz002',...
%    'EZT005seiz001', 'EZT005seiz002', 'EZT007seiz001', 'EZT007seiz002', ...
%    	'EZT070seiz001', 'EZT070seiz002', ...
    };


close all;
% data parameters to find correct directory
winSize = 500;            % 500 milliseconds
stepSize = 500; 
frequency_sampling = 1000; % in Hz
epsilon = 0.7;
% TEST_DESCRIP = 'noleftandrpp';
TEST_DESCRIP = [];
TYPE_CONNECTIVITY = 'leastsquares';

figDir = './figures/electrodeWeights';
radius = 1.5;             % spectral radius
perturbationTypes = ['C', 'R'];
perturbationType = perturbationTypes(1);

%%- Begin Loop Through Different Patients Here
for p=1:length(patients)
    patient = patients{p};

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

    [included_channels, ezone_labels, earlyspread_labels, latespread_labels, resection_labels, frequency_sampling, center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);
        
    serverDir = './serverdata/';
     % directory that computed perturbation structs are saved
    finalDataDir = fullfile(serverDir, strcat(perturbationType, '_perturbations', ...
            '_radius', num2str(radius)), 'win500_step500_freq1000', patient);

    try
        final_data = load(fullfile(finalDataDir, strcat(patient, ...
            '_', perturbationType, 'perturbation_', lower(TYPE_CONNECTIVITY), '.mat')));
        final_data = final_data.perturbation_struct;
    catch e
        disp(e)
        final_data = load(fullfile(finalDataDir, strcat(patient, ...
            '_', perturbationType, 'perturbation_', lower(TYPE_CONNECTIVITY), ...
            '_radius', num2str(radius), '.mat')));
        final_data = final_data.perturbation_struct;
    end
    % set data to local variables
    minPerturb_time_chan = final_data.minNormPertMat;
    fragility_rankings = final_data.fragilityMat;
    timePoints = final_data.timePoints;
    info = final_data.info;
    num_channels = size(minPerturb_time_chan,1);
    seizureStart = info.seizure_start;
    seizureEnd = info.seizure_end;
    included_labels = info.all_labels;
 
    
    data = struct();
     %% PLOT PERTURBATION RESULTS
    for j=1:length(perturbationTypes)
        perturbationType = perturbationTypes(j);
        
        %- initialize directories to save weights
        toSaveWeightsDir = fullfile(figDir, strcat(perturbationType, '_electrode_weights'), strcat(patient, num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(frequency_sampling), '_radius', num2str(radius)))
        if ~exist(toSaveWeightsDir, 'dir')
            mkdir(toSaveWeightsDir);
        end
           
        % directory that computed perturbation structs are saved
        finalDataDir = fullfile(serverDir, strcat(perturbationType, '_perturbations', ...
            '_radius', num2str(radius)), 'win500_step500_freq1000', patient);
        
        try
            final_data = load(fullfile(finalDataDir, strcat(patient, ...
                '_', perturbationType, 'perturbation_', lower(TYPE_CONNECTIVITY), '.mat')));
            final_data = final_data.perturbation_struct;
        catch e
            disp(e)
            final_data = load(fullfile(finalDataDir, strcat(patient, ...
                '_', perturbationType, 'perturbation_', lower(TYPE_CONNECTIVITY), ...
                '_radius', num2str(radius), '.mat')));
            final_data = final_data.perturbation_struct;
        end
        % set data to local variables
        minPerturb_time_chan = final_data.minNormPertMat;
        fragility_rankings = final_data.fragilityMat;
        info = final_data.info;
        timePoints = final_data.timePoints;
        
        seizureMarkStart = seizureStart/winSize;
        minPerturb_time_chan = minPerturb_time_chan(:, 1:seizureMarkStart);
        fragility_rankings = fragility_rankings(:, 1:seizureMarkStart);
        timePoints = timePoints(1:seizureMarkStart,:);
        
        %% COMPUTE METRICS OF DETERMINING EPIMAP EZ
        %- rowsum
        rowsum = sum(fragility_rankings,2);
        rowsum_normalized = sum(fragility_rankings,2)./size(fragility_rankings,2);
        
        fragility_thresholded = zeros(size(fragility_rankings));
        fragility_thresholded(fragility_rankings>epsilon) = fragility_rankings(fragility_rankings>epsilon);
        rowsum_thresholded = sum(fragility_thresholded,2);
        
        data.(perturbationType).rowsum = rowsum;
        data.(perturbationType).rowsum_normalized = rowsum_normalized;
        data.(perturbationType).rowsum_thresholded = rowsum_thresholded;
    end
    
    fileName = fullfile(toSaveWeightsDir, strcat(patient, '_weights'));
    save(fileName, 'data');
end