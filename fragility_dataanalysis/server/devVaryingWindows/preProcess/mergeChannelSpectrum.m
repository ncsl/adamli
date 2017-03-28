function mergeChannelSpectrum(patient, winSize, stepSize, typeTransform)
    if nargin==0
        patient='pt1sz4';
%         patient='UMMC003_sz1';
        winSize=500;
        stepSize=250;
        typeTransform='fourier';
    end

     %% Initialization
    % data directories to save data into - choose one
    eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';     % work
    % eegRootDirHome = '/Users/adam2392/Documents/MATLAB/Johns Hopkins/NINDS_Rotation';  % home
    eegRootDirHome = '/Volumes/NIL_PASS/';
    eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';
    % Determine which directory we're working with automatically
    if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
    elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
    elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
    else   error('Neither Work nor Home EEG directories exist! Exiting'); end

    addpath(genpath(fullfile(rootDir, '/fragility_library/')));
    addpath(genpath(fullfile(rootDir, '/eeg_toolbox/')));
    addpath(rootDir);

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
    buffpatid = patient_id;
    if strcmp(patient_id(end), '_')
        patient_id = patient_id(1:end-1);
    end

    % array of frequency bands
    freqBandAr(1).name    = 'delta';
    freqBandAr(1).rangeF  = [2 4];          %[2 4]
    freqBandAr(2).name    = 'theta';
    freqBandAr(2).rangeF  = [4 8];          %[4 8]
    freqBandAr(3).name    = 'alpha';
    freqBandAr(3).rangeF  = [8 16];         %[8 12]
    freqBandAr(4).name    = 'beta';
    freqBandAr(4).rangeF  = [16 32];        %[12 30]
    freqBandAr(5).name    = 'low gamma';
    freqBandAr(5).rangeF  = [32 80];        %[30 70]
    freqBandAr(6).name    = 'high gamma';
    freqBandAr(6).rangeF  = [80 160];       %[70 150]
    freqBandAr(7).name    = 'HFO';
    freqBandAr(7).rangeF  = [160 400];      %[150 400]


    % set the frequency bands to certain ranges for plotting
    for iFB=1:length(freqBandAr),
        freqBandAr(iFB).centerF = mean(freqBandAr(iFB).rangeF);
        %freqBandAr(iFB).label   = sprintf('%s-%.0fHz', freqBandAr(iFB).name(1:[ min( [length(freqBandAr(iFB).name), 6] )]), freqBandAr(iFB).centerF);
        freqBandAr(iFB).label   = sprintf('%s [%.0f-%.0f Hz]', freqBandAr(iFB).name, freqBandAr(iFB).rangeF);
    end
    
     %% DEFINE OUTPUT DIRS AND CLINICAL ANNOTATIONS
    %- Edit this file if new patients are added.
    [included_channels, ezone_labels, earlyspread_labels,...
        latespread_labels, resection_labels, fs, ...
        center] ...
                = determineClinicalAnnotations(patient_id, seizure_id);
    patient_id = buffpatid;
    
    % temp dir to access computed data
    tempDir = fullfile(rootDir, 'server/devVaryingWindows/preProcess/tempData/', strcat(patient, '_', typeTransform));
    
    if seeg
        patient = strcat(patient_id, seizure_id);
        eegDir = fullfile(rootDir, 'data', center);
        data_struct = load(fullfile(eegDir, patient_id, patient));
    else
        eegDir = fullfile(rootDir, 'data', center);
        data_struct = load(fullfile(eegDir, patient, patient));
    end
    
    [numChans, eventDurationMS] = size(data_struct.data);
    elec_labels = data_struct.elec_labels;
    seizure_start = data_struct.seiz_start_mark;
    seizure_end = data_struct.seiz_end_mark;
    data = data_struct.data;
    
    [N, T] = size(data);
    
     % load in adjMats file
    matFiles = dir(fullfile(tempDir, '*.mat'));
    matFileNames = natsort({matFiles.name});
    
    % initialize matrices to store computed data
    chansComputed = zeros(N, 1);    

    
    % construct the adjMats from the windows computed of adjMat
    for iMat=1:length(matFileNames)
        matFile = fullfile(tempDir, matFileNames{iMat});
        load(matFile);
        
        % check window numbers and make sure they are being stored in order
        currentFile = matFileNames{iMat};
        index = strfind(currentFile, '_');
        index = currentFile(1:index-1);
        
        if str2num(index) ~= iMat
            disp(['There is an error at ', num2str(iMat)]);
        end
        chansComputed(str2num(index)) = 1;
        
        % extract the computed transform data
        temppowerMat = data.powerMat;
        temppowerMatZ = data.powerMatZ;
        
        % initialize matrix if first loop and then store results
        if iMat==1
            FILTERTYPE = data.FILTERTYPE;
            waveT = data.waveT;
            freqs = data.freqs;
            winSize = data.winSize;
            stepSize = data.stepSize;
            
            % set directory to save merged computed data
            if FILTERTYPE == 1
                toSaveDir = fullfile(rootDir, strcat('/serverdata/spectral_analysis/', typeTransform, '/notchharmonics/win', num2str(winSize), ...
                    '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
            elseif FILTERTYPE == 2
                toSaveDir = fullfile(rootDir, strcat('/serverdata/spectral_analysis/', typeTransform, '/adaptivefilter/win', num2str(winSize), ...
                    '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
            else 
                toSaveDir = fullfile(rootDir, strcat('/serverdata/spectral_analysis/', typeTransform, '/nofilter/', 'win', num2str(winSize), ...
                    '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
            end


            % create directory if it does not exist
            if ~exist(toSaveDir, 'dir')
                mkdir(toSaveDir);
            end
            
            % initialize matrices
            powerMat = zeros(N, length(freqs), size(waveT, 1));
            powerMatZ = zeros(size(powerMat));
        end
        
        % store the computed transform data into 3D matrix
        powerMat(iMat, :,:) = temppowerMat;
        powerMatZ(iMat, :, :) = temppowerMatZ;
    end
    
    test = find(chansComputed == 0);
    if isempty(test)
       SUCCESS = 1;
    else
       SUCCESS = 0;
    end

    % create to save data struct
    chanData = struct();
    chanData.FILTERTYPE = FILTERTYPE;
    chanData.chanStr = elec_labels;
    chanData.chansComputed = chansComputed;
    chanData.powerMat = powerMat;
    chanData.powerMatZ = powerMatZ;
    chanData.seizure_end = seizure_end;
    chanData.seizure_start = seizure_start;
    chanData.winSize = winSize;
    chanData.stepSize = stepSize;
    chanData.waveT = waveT;
    chanData.freqs = freqs;

    %%- SAVING DIR PARAMETERS
    chanFileName = strcat(patient, '_', typeTransform, '.mat');
    saveChannel(toSaveDir, chanFileName, chanData); 
    
    % Check if it was successful full computation
    if SUCCESS
%         try
%             save(fullfile(adjMatDir, fileName), 'adjmat_struct');
%         catch e
%             disp(e);
%             save(fullfile(adjMatDir, fileName), 'adjmat_struct', '-v7.3');
%         end
        rmdir(fullfile(tempDir));
    else
        fprintf('Make sure to fix the windows not computed!');
    end
end