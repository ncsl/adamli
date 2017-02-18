% #########################################################################
% Script for testing function DOA. 
%
% Script Summary: Computes statistic (DOA = Degree of Agreement) indicat-
% ing how well EEZ (from EpiMap) and CEZ (clinical ezone) agree. 
% 
% Inputs: [function]
%   EpiMap: Map with keys as electrode labels and corresponding values from
%   0-1 indicating how likely an electrode is in the ezone 
%   EpiMapStruct: struct with EpiMap in it
%   CEZ: cell with clinically predicted ezone labels 
%   ALL: cell with all electrode labels
%   clinicalStruct: struct with clinical values, with CEZ and ALL values in it 
%   threshold: value from 0 - 1 required for an electrode in the EpiMap to 
%   be considered part of the EEZ
%   
% Output: [function]
%   DOA: (#CEZ intersect EEZ / #CEZ) / (#NOTCEZ intersect EEZ / #NOTCEZ)
%   Value between -1 and 1, Computes how well CEZ and EEZ match. 
%   < 0 indicates poor match.
% 
% Author: Kriti Jindal, NCSL 
% Last Updated: 02.10.17
%   
% #########################################################################
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
%     'pt3sz2' 'pt3sz4', ...
%     'pt6sz3' 'pt6sz4' 'pt6sz5',...
%     'pt8sz1' 'pt8sz2' 'pt8sz3',...
%     'pt10sz1' 'pt10sz2' 'pt10sz3', ...
%     'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
%     'pt14sz1' 'pt14sz2' 'pt14sz3', ...
%      'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
%     'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt17sz1' 'pt17sz2',...
%     'JH101sz1' 'JH101sz2' 'JH101sz3' 'JH101sz4',...
% 	'JH102sz1' 'JH102sz2' 'JH102sz3' 'JH102sz4' 'JH102sz5' 'JH102sz6',...
% 	'JH103sz1' 'JH103sz2' 'JH103sz3',...
% 	'JH104sz1' 'JH104sz2' 'JH104sz3',...
% 	'JH105sz1' 'JH105sz2' 'JH105sz3' 'JH105sz4' 'JH105sz5',...
% 	'JH106sz1' 'JH106sz2' 'JH106sz3' 'JH106sz4' 'JH106sz5' 'JH106sz6',...
% 	'JH107sz1' 'JH107sz2' 'JH107sz3' 'JH107sz4' 'JH107sz5' 
%     'JH107sz6' 'JH107sz7' 'JH107sz8' 'JH107sz9',...
%    'JH108sz1', 'JH108sz2', 'JH108sz3', 'JH108sz4', 'JH108sz5', 'JH108sz6', 'JH108sz7',...
%     'EZT004seiz001', 'EZT004seiz002', ...
%     'EZT006seiz001', 'EZT006seiz002', ...
%     'EZT008seiz001', 'EZT008seiz002', ...
%     'EZT009seiz001', 'EZT009seiz002', ...    
%     'EZT011seiz001', 'EZT011seiz002', ...
%     'EZT013seiz001', 'EZT013seiz002', ...
%     'EZT020seiz001', 'EZT020seiz002', ...
%     'EZT025seiz001', 'EZT025seiz002', ...
    'EZT026seiz001', 'EZT026seiz002', ...
    'EZT028seiz001', 'EZT028seiz002', ...
   'EZT037seiz001', 'EZT037seiz002',...
   'EZT019seiz001', 'EZT019seiz002',...
   'EZT005seiz001', 'EZT005seiz002',...
    'EZT007seiz001', 'EZT007seiz002', ...
%    	'EZT070seiz001', 'EZT070seiz002', ...
    };

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% GLOBAL VARIABLES FOR TESTING 

EpiMap = 'fake_data.EpiMap';
EpiMapStruct = 'fake_data.mat';
CEZ = 'adjmat_struct.ezone_labels';
ALL = 'adjmat_struct.all_labels';
clinicalStruct = 'pt1sz2_adjmats_leastsquares.mat';
threshold = 0.70;

EXTERNAL = 1;

addpath('../../');
%- set the weights dir and params
weightsDir = '../../figures/electrodeWeights/';
winSize = 500;
stepSize = 500;
frequency_sampling = 1000;
radius = 1.5;
TYPE_CONNECTIVITY = 'leastsquares';

%- perturbation directory to compute a weight
serverDir = '../../serverdata/'; 
perturbationType = 'C';
TEST_DESCRIP = 'after_first_removal';
TEST_DESCRIP = [];

if EXTERNAL
    weightsDir = '';
    serverDir = '/Volumes/NIL_PASS/serverdata/';
end

summaryFile = 'summarydoafile.csv';
fid = fopen(summaryFile, 'w');

successPatients = {
    'EZT004seiz001', 'EZT004seiz002', ...
    'EZT005seiz001', 'EZT005seiz002', ...
    'EZT007seiz001', 'EZT007seiz002', ...
    'EZT019seiz001', 'EZT019seiz002',...
    'EZT037seiz001', 'EZT037seiz002',...
    'EZT028seiz001', 'EZT028seiz002', ...
    'EZT009seiz001', 'EZT009seiz002', ...   
    'EZT011seiz001', 'EZT011seiz002', ...
    'EZT026seiz001', 'EZT026seiz002', ...
    };

failPatients = {   
    'EZT006seiz001', 'EZT006seiz002', ...
    'EZT008seiz001', 'EZT008seiz002', ...   
    'EZT013seiz001', 'EZT013seiz002', ...
    'EZT020seiz001', 'EZT020seiz002', ...
    'EZT025seiz001', 'EZT025seiz002', ...
};

%%- Loop through each patient and compute DOA
successDOA = zeros(length(successPatients),1);
for iPat=1:length(successPatients)
    patient = successPatients{iPat}
    
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
        
     % directory that computed perturbation structs are saved
    finalDataDir = fullfile(serverDir, strcat(perturbationType, '_perturbations', ...
            '_radius', num2str(radius)), 'win500_step500_freq1000', patient);

    try
        TEST_DESCRIP = 'after_first_removal';
        if ~isempty(TEST_DESCRIP)
            finalDataDir = fullfile(finalDataDir, TEST_DESCRIP);
        end

        final_data = load(fullfile(finalDataDir, strcat(patient, ...
            '_', perturbationType, 'perturbation_', lower(TYPE_CONNECTIVITY), ...
            '_radius', num2str(radius), '.mat')));
    catch e
        disp(e)
        finalDataDir = fullfile(serverDir, strcat(perturbationType, '_perturbations', ...
            '_radius', num2str(radius)), 'win500_step500_freq1000', patient);
        final_data = load(fullfile(finalDataDir, strcat(patient, ...
            '_', perturbationType, 'perturbation_', lower(TYPE_CONNECTIVITY), ...
            '_radius', num2str(radius), '.mat')));
    end
    final_data = final_data.perturbation_struct;

    % set data to local variables
    minPerturb_time_chan = final_data.minNormPertMat;
    fragility_rankings = final_data.fragilityMat;
    timePoints = final_data.timePoints;
    info = final_data.info;
    num_channels = size(minPerturb_time_chan,1);
    seizureStart = info.seizure_start;
    seizureEnd = info.seizure_end;
    included_labels = info.all_labels;

    seizureMarkStart = seizureStart/winSize;
    if seeg
        seizureMarkStart = (seizureStart-1) / winSize;
    end

    minPerturb_time_chan = minPerturb_time_chan(:, 1:seizureMarkStart);
    fragility_rankings = fragility_rankings(:, 1:seizureMarkStart);
    timePoints = timePoints(1:seizureMarkStart,:);  

    %- rowsum (overall strength of fragility)
    rowsum = sum(fragility_rankings, 2);
    rowsum = rowsum./max(rowsum);
    EEZ_indices = find(rowsum > mean(rowsum)+std(rowsum));
    EEZ = included_labels(EEZ_indices);
    ALL = included_labels;
    CEZ = ezone_labels;
     
    NotCEZ = setdiff(ALL, CEZ);
    CEZ_EEZ = intersect(CEZ, EEZ);
    NotCEZ_EEZ = intersect(NotCEZ, EEZ);

    term1 = length(CEZ_EEZ) / length(CEZ);
    term2 = length(NotCEZ_EEZ) / length(NotCEZ);

    D = term1 - term2;
    fprintf('The degree of agreement with threshold %.2f is %.5f. \n',threshold, D);
    
    %- rowsum -> after thresholding (intensity of fragility)
    fragility_rankings(fragility_rankings < threshold) = 0;
    rowsum = sum(fragility_rankings, 2);
    rowsum = rowsum./max(rowsum);
    EEZ_indices = find(rowsum > threshold);
    [sorted_rowsum, sorted_indices] = sort(rowsum,'descend');
    if ismember(0, sorted_rowsum(1:length(ezone_labels)))
        EEZ_indices = find(sorted_rowsum(1:find(0==sorted_rowsum, 1)-1));
    else
        EEZ_indices = find(sorted_rowsum(1:length(ezone_labels)));
    end
    EEZ_indices = sorted_indices(EEZ_indices);
    EEZ = included_labels(EEZ_indices);
    ALL = included_labels;
    CEZ = ezone_labels;
     
    NotCEZ = setdiff(ALL, CEZ);
    CEZ_EEZ = intersect(CEZ, EEZ);
    NotCEZ_EEZ = intersect(NotCEZ, EEZ);

    term1 = length(CEZ_EEZ) / length(CEZ);
    term2 = length(NotCEZ_EEZ) / length(NotCEZ);

    D = term1 - term2;
    fprintf('The degree of agreement with threshold %.2f is %.5f. \n',threshold, D);

    %- rowsum instances of fragility 
    fragility_rankings = final_data.fragilityMat;
     fragility_rankings = fragility_rankings(:, 1:seizureMarkStart);
    fragility_rankings(fragility_rankings < threshold) = 0;
    fragility_rankings(fragility_rankings >= threshold) = 1;
    rowsum = sum(fragility_rankings, 2);
    
    test = rowsum(rowsum > 0);
    EEZ_indices = find(rowsum > mean(test));
    EEZ = included_labels(EEZ_indices);
    ALL = included_labels;
    CEZ = ezone_labels;
     
    NotCEZ = setdiff(ALL, CEZ);
    CEZ_EEZ = intersect(CEZ, EEZ);
    NotCEZ_EEZ = intersect(NotCEZ, EEZ);

    term1 = length(CEZ_EEZ) / length(CEZ);
    term2 = length(NotCEZ_EEZ) / length(NotCEZ);

    D = term1 - term2;
    fprintf('The degree of agreement with threshold %.2f is %.5f. \n',threshold, D);
    
    %%- output data to summarize
    %- 1. is CEZ within EEZ? -> what proportion?
    fragility_rankings = final_data.fragilityMat;
     fragility_rankings = fragility_rankings(:, 1:seizureMarkStart);
    fragility_rankings(fragility_rankings < threshold) = 0;
    rowsum = sum(fragility_rankings, 2);
    rowsum = rowsum./max(rowsum);
    
    EEZ_indices = find(rowsum > threshold);
    [sorted_rowsum, sorted_indices] = sort(rowsum,'descend');
    if ismember(0, sorted_rowsum(1:length(ezone_labels)))
        EEZ_indices = find(sorted_rowsum(1:find(0==sorted_rowsum, 1)-1));
    else
        EEZ_indices = find(sorted_rowsum(1:length(ezone_labels)));
    end
    EEZ_indices = sorted_indices(EEZ_indices);
    EEZ = included_labels(EEZ_indices);
    ALL = included_labels;
    CEZ = ezone_labels;
     
    NotCEZ = setdiff(ALL, CEZ);
    CEZ_EEZ = intersect(CEZ, EEZ);
    NotCEZ_EEZ = intersect(NotCEZ, EEZ);

    term1 = length(CEZ_EEZ) / length(CEZ);
    term2 = length(NotCEZ_EEZ) / length(NotCEZ);
    
    intersection = intersect(included_labels(find(rowsum > 0)), CEZ);
    proportion_intersection = length(intersection) / length(CEZ);
    
    %- 2. what is DOA?
    D = term1 - term2;
    
    successDOA(iPat) = D;
    %- 3. Log data into a csv file
    fprintf(fid, 'patient, proportion detected?, DOA\n');
    fprintf(fid, '%s, %f, %f\n', patient, proportion_intersection, D);
end


failedDOA = zeros(length(failPatients),1);
for iPat=1:length(failPatients)
    patient = failPatients{iPat}
    
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
        
     % directory that computed perturbation structs are saved
    finalDataDir = fullfile(serverDir, strcat(perturbationType, '_perturbations', ...
            '_radius', num2str(radius)), 'win500_step500_freq1000', patient);

    try
        TEST_DESCRIP = 'after_first_removal';
        if ~isempty(TEST_DESCRIP)
            finalDataDir = fullfile(finalDataDir, TEST_DESCRIP);
        end

        final_data = load(fullfile(finalDataDir, strcat(patient, ...
            '_', perturbationType, 'perturbation_', lower(TYPE_CONNECTIVITY), ...
            '_radius', num2str(radius), '.mat')));
    catch e
        disp(e)
        finalDataDir = fullfile(serverDir, strcat(perturbationType, '_perturbations', ...
            '_radius', num2str(radius)), 'win500_step500_freq1000', patient);
        final_data = load(fullfile(finalDataDir, strcat(patient, ...
            '_', perturbationType, 'perturbation_', lower(TYPE_CONNECTIVITY), ...
            '_radius', num2str(radius), '.mat')));
    end
    final_data = final_data.perturbation_struct;

    % set data to local variables
    minPerturb_time_chan = final_data.minNormPertMat;
    fragility_rankings = final_data.fragilityMat;
    timePoints = final_data.timePoints;
    info = final_data.info;
    num_channels = size(minPerturb_time_chan,1);
    seizureStart = info.seizure_start;
    seizureEnd = info.seizure_end;
    included_labels = info.all_labels;

    seizureMarkStart = seizureStart/winSize;
    if seeg
        seizureMarkStart = (seizureStart-1) / winSize;
    end

    minPerturb_time_chan = minPerturb_time_chan(:, 1:seizureMarkStart);
    fragility_rankings = fragility_rankings(:, 1:seizureMarkStart);
    timePoints = timePoints(1:seizureMarkStart,:);  

    %- rowsum (overall strength of fragility)
    rowsum = sum(fragility_rankings, 2);
    rowsum = rowsum./max(rowsum);
    EEZ_indices = find(rowsum > mean(rowsum)+std(rowsum));
    EEZ = included_labels(EEZ_indices);
    ALL = included_labels;
    CEZ = ezone_labels;
     
    NotCEZ = setdiff(ALL, CEZ);
    CEZ_EEZ = intersect(CEZ, EEZ);
    NotCEZ_EEZ = intersect(NotCEZ, EEZ);

    term1 = length(CEZ_EEZ) / length(CEZ);
    term2 = length(NotCEZ_EEZ) / length(NotCEZ);

    D = term1 - term2;
    fprintf('The degree of agreement with threshold %.2f is %.5f. \n',threshold, D);
    
    %- rowsum -> after thresholding (intensity of fragility)
    fragility_rankings(fragility_rankings < threshold) = 0;
    rowsum = sum(fragility_rankings, 2);
    rowsum = rowsum./max(rowsum);
    EEZ_indices = find(rowsum > threshold);
    [sorted_rowsum, sorted_indices] = sort(rowsum,'descend');
    if ismember(0, sorted_rowsum(1:length(ezone_labels)))
        EEZ_indices = find(sorted_rowsum(1:find(0==sorted_rowsum, 1)-1));
    else
        EEZ_indices = find(sorted_rowsum(1:length(ezone_labels)));
    end
    EEZ_indices = sorted_indices(EEZ_indices);
    EEZ = included_labels(EEZ_indices);
    ALL = included_labels;
    CEZ = ezone_labels;
     
    NotCEZ = setdiff(ALL, CEZ);
    CEZ_EEZ = intersect(CEZ, EEZ);
    NotCEZ_EEZ = intersect(NotCEZ, EEZ);

    term1 = length(CEZ_EEZ) / length(CEZ);
    term2 = length(NotCEZ_EEZ) / length(NotCEZ);

    D = term1 - term2;
    fprintf('The degree of agreement with threshold %.2f is %.5f. \n',threshold, D);

    %- rowsum instances of fragility 
    fragility_rankings = final_data.fragilityMat;
     fragility_rankings = fragility_rankings(:, 1:seizureMarkStart);
    fragility_rankings(fragility_rankings < threshold) = 0;
    fragility_rankings(fragility_rankings >= threshold) = 1;
    rowsum = sum(fragility_rankings, 2);
    
    test = rowsum(rowsum > 0);
    EEZ_indices = find(rowsum > mean(test));
    EEZ = included_labels(EEZ_indices);
    ALL = included_labels;
    CEZ = ezone_labels;
     
    NotCEZ = setdiff(ALL, CEZ);
    CEZ_EEZ = intersect(CEZ, EEZ);
    NotCEZ_EEZ = intersect(NotCEZ, EEZ);

    term1 = length(CEZ_EEZ) / length(CEZ);
    term2 = length(NotCEZ_EEZ) / length(NotCEZ);

    D = term1 - term2;
    fprintf('The degree of agreement with threshold %.2f is %.5f. \n',threshold, D);
    
    %%- output data to summarize
    %- 1. is CEZ within EEZ? -> what proportion?
    fragility_rankings = final_data.fragilityMat;
     fragility_rankings = fragility_rankings(:, 1:seizureMarkStart);
    fragility_rankings(fragility_rankings < threshold) = 0;
    rowsum = sum(fragility_rankings, 2);
    rowsum = rowsum./max(rowsum);
    
    EEZ_indices = find(rowsum > threshold);
    [sorted_rowsum, sorted_indices] = sort(rowsum,'descend');
    if ismember(0, sorted_rowsum(1:length(ezone_labels)))
        EEZ_indices = find(sorted_rowsum(1:find(0==sorted_rowsum, 1)-1));
    else
        EEZ_indices = find(sorted_rowsum(1:length(ezone_labels)));
    end
    EEZ_indices = sorted_indices(EEZ_indices);
    EEZ = included_labels(EEZ_indices);
    ALL = included_labels;
    CEZ = ezone_labels;
     
    NotCEZ = setdiff(ALL, CEZ);
    CEZ_EEZ = intersect(CEZ, EEZ);
    NotCEZ_EEZ = intersect(NotCEZ, EEZ);

    term1 = length(CEZ_EEZ) / length(CEZ);
    term2 = length(NotCEZ_EEZ) / length(NotCEZ);
    
    intersection = intersect(included_labels(find(rowsum > 0)), CEZ);
    proportion_intersection = length(intersection) / length(CEZ);
    
    %- 2. what is DOA?
    D = term1 - term2;
    
    if isnan(D)
        D = 0;
    end
    failedDOA(iPat) = D;
    %- 3. Log data into a csv file
    fprintf(fid, 'patient, proportion detected?, DOA\n');
    fprintf(fid, '%s, %f, %f\n', patient, proportion_intersection, D);
end

% plotting box plot
g = [ones(size(successDOA)); 2*ones(size(failedDOA))];
figure;
boxplot([successDOA; failedDOA], g);
axes = gca;
axes.FontSize = 18;
axes.XTickLabel = {'Success', 'Failures'};

title(['Summary Degree of Agreement']);
ylabel('Degree of Agreement');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load in necesssary structs for EpiMap, CEZ and ALL 

load(EpiMapStruct);
load(clinicalStruct);

% seperate EpiMap values and keys 

EpiMap_values = cell2mat(values(EpiMap));
EpiMap_keys = keys(EpiMap);

% saves all labels in EpiMap with > THRESHOLD in vector 'EEZ'

y = 1;
for x = 1:length(EpiMap_values)
    if EpiMap_values(x) > threshold
        EEZ(y) = EpiMap_keys(x);
        y = y + 1;
    end
end

% finds appropriate set intersections to plug into DOA formula 

NotCEZ = setdiff(ALL, CEZ);
CEZ_EEZ = intersect(CEZ, EEZ);
NotCEZ_EEZ = intersect(NotCEZ, EEZ);

term1 = length(CEZ_EEZ) / length(CEZ);
term2 = length(NotCEZ_EEZ) / length(NotCEZ);

D = term1 - term2;

fprintf('The degree of agreement with threshold %.2f is %.5f. \n',threshold, D);
