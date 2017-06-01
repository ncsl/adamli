%
% Description
% 1. Take spectral power computed before and load in per channel
% 2. For each channel, compute a power distribution for each frequency
% 3. For each channel, go across time and look if there are frequencies in
% tails of the power distribution
% 4. apply thresholding
% 5. Return time points that are broadband noise affected
patients = {
%     'UMMC001_sz1', 'UMMC001_sz2', 'UMMC001_sz3', ...
%     'UMMC002_sz1', 'UMMC002_sz2', 'UMMC002_sz3', ...
%     'UMMC003_sz1', 'UMMC003_sz2', 'UMMC003_sz3', ...
%     'UMMC004_sz1', 'UMMC004_sz2', 'UMMC004_sz3', ...
%     'UMMC005_sz1', 'UMMC005_sz2', 'UMMC005_sz3', ...
%     'UMMC006_sz1', 'UMMC006_sz2', 'UMMC006_sz3', ...
%     'UMMC007_sz1', 'UMMC007_sz2','UMMC007_sz3', ...
%     'UMMC008_sz1', 'UMMC008_sz2', 'UMMC008_sz3', ...
%     'UMMC009_sz1', 'UMMC009_sz2', 'UMMC009_sz3', ...
     'pt1aw1','pt1aw2', ...
%     'pt1aslp1','pt1aslp2', ...
%     'pt2aw1', 'pt2aw2', ...
%     'pt2aslp1', 'pt2aslp2', ...
%     'pt3aw1', ...
%     'pt3aslp1', 'pt3aslp2', ...
%     'pt1sz2', 'pt1sz3', 'pt1sz4',...
%     'pt2sz1' 'pt2sz3' , 'pt2sz4', ...
%     'pt3sz2' 'pt3sz4', ...
%      'pt6sz3', 'pt6sz4', 'pt6sz5',...
%     'pt7sz19', 'pt7sz21', 'pt7sz22',...
%     'pt8sz1' 'pt8sz2' 'pt8sz3',...
%     'pt10sz1','pt10sz2' 'pt10sz3', ...
%     'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
%     'pt12sz1', 'pt12sz2', ...
%     'pt13sz1', 'pt13sz2', 'pt13sz3', 'pt13sz5',...
%     'pt14sz1' 'pt14sz2' 'pt14sz3'  'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
%     'pt16sz1' 'pt16sz2' 'pt16sz3',...
%     'pt17sz1' 'pt17sz2', 'pt17sz3',...
};

thresholds = linspace(0, 1, 100);
thresh_sense = zeros(length(patients), length(thresholds));
for iPat=1:length(patients)
    patient = patients{iPat};
    typeTransform = 'fourier';

    % Initialization
    %- 0 == no filtering
    %- 1 == notch filtering
    %- 2 == adaptive filtering
    FILTER_RAW = 2; 
    winSize = 500;
    stepSize = 250;

    % data directories to save data into - choose one
    eegRootDirHD = '/Volumes/NIL Pass/';
    eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';                 % at ICM server 
    eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';   % at home macbook
    eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/';    % at JHU workstation
    eegRootDirMarcctest = '/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/'; % at MARCC server
    eegRootDirMarcc = '/scratch/groups/ssarma2/adamli/fragility_dataanalysis/';
    
    % Determine which directory we're working with automatically
    if     ~isempty(dir(eegRootDirServer)), rootDir = eegRootDirServer;
    elseif ~isempty(dir(eegRootDirHome)), rootDir = eegRootDirHome;
    elseif ~isempty(dir(eegRootDirJhu)), rootDir = eegRootDirJhu;
    elseif ~isempty(dir(eegRootDirMarcc)), rootDir = eegRootDirMarcc;
    elseif ~isempty(dir(eegRootDirHD)), rootDir = eegRootDirHD;
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

    %% DEFINE OUTPUT DIRS AND CLINICAL ANNOTATIONS
    %- Edit this file if new patients are added.
    [included_channels, ezone_labels, earlyspread_labels,...
        latespread_labels, resection_labels, fs, ...
        center] ...
                = determineClinicalAnnotations(patient_id, seizure_id);
    patient_id = buffpatid;

    % set directory to save computed data
    if FILTER_RAW == 1
        spectDir = fullfile(rootDir, strcat('/serverdata/spectral_analysis/', typeTransform, '/notchharmonics_win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
    elseif FILTER_RAW == 2
        spectDir = fullfile(rootDir, strcat('/serverdata/spectral_analysis/', typeTransform, '/adaptivefilter/win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
    else 
        spectDir = fullfile(rootDir, strcat('/serverdata/spectral_analysis/', typeTransform, '/nofilter_', 'win', num2str(winSize), ...
            '_step', num2str(stepSize), '_freq', num2str(fs)), patient); % at lab
    end

    % get all the spectral power files for this patient
    elecFile = fullfile(spectDir, strcat(patient, '_', typeTransform));

    % load in the electrode file
    data = load(elecFile);
    data = data.data;

    chanStrs = data.chanStr;
    winSize = data.winSize;
    stepSize = data.stepSize;
    seizureStart = data.seizure_start;
    seizureEnd = data.seizure_end;
    timePoints = data.waveT;
    freqs = data.freqs;
    powerMatZ = data.powerMatZ;

    % get seizure marks in window
    seizureStartMark = seizureStart / stepSize - (winSize/stepSize - 1);
    seizureEndMark = seizureEnd / stepSize - (winSize/stepSize - 1);

    [numChans, numFreqs, numTimes] = size(powerMatZ);
    lowperctile = 1;
    highperctile = 99;
    perctiles = zeros(numFreqs, 2);

    %- channels to find
    noiseindices = find(~cellfun(@isempty, cellfun(@(x)strfind(x, 'POLG25'), chanStrs, 'uniform', 0)));
    FONTSIZE = 16;    
    reject_cell = zeros(length(thresholds), 1);

    %%- Loop through all thresholds to get figure on rate of data loss
    for iThresh=1:length(thresholds)
        threshold = thresholds(iThresh);

        thresholdindices = [];
        
        %% Loop Through Channels and Apply Broadband Filter
        %%- Loop through frequencies for this transform
        for iChan=1:numChans
        % for i=1:length(noiseindices)
        %     iChan = noiseindices(i);
            chan = chanStrs{iChan};

            %- get channel power matrix
            chanPowerMat = squeeze(powerMatZ(iChan, :, 1:seizureStartMark));
            mask = zeros(size(chanPowerMat));

            %-  compute low and high percentiles
            perctiles(:, 1) = prctile(chanPowerMat, lowperctile, 2);
            perctiles(:, 2) = prctile(chanPowerMat, highperctile, 2);

            %- apply mask of {-1,0,1} to each frequency in the power matrix
            for i=1:numFreqs
                indices = chanPowerMat(i, :) > perctiles(i, 2);
                mask(i, indices) = 1;

                indices = chanPowerMat(i, :) < perctiles(i, 1);
                mask(i, indices) = -1;
            end

            %- create matrix on the mask of only high powers
            highmask = zeros(size(mask));
            highmask(mask == 1) = 1;
            highinteg = trapz(freqs, highmask, 1) ./ trapz(freqs, ones(size(highmask)), 1);

           %- log indices greater then a certain threshold
            rejectindices = find(highinteg >= threshold);
            thresholdindices = union(thresholdindices, rejectindices);

    %         figure;
    %         subplot(2,1,1);
    %         imagesc(chanPowerMat);
    %         colorbar(); set(gca, 'Box', 'off');
    %         colormap('jet');
    %          set(gca, 'ytick', 1:10:length(freqs), 'yticklabel', freqs(1:10:length(freqs)));
    %         ylabel('Freq (Hz)', 'FontSize', FONTSIZE);
    %         set(gca,'tickdir','out','YDir','normal'); % spectrogram should have low freq on the bottom
    %         ax = gca;
    %         title([patient, ' at electrode: ', chan], 'FontSize', FONTSIZE);
    %         xlabel('Time (sec)', 'FontSize', FONTSIZE);
    % 
    %         subplot(2, 1, 2);
    %         imagesc(highinteg);
    %         colorbar(); hold on;
    %         plot([seizureStartMark seizureStartMark], [1 41], 'k');
    % 
    %         timeStart = timePoints(1, 2) / fs - seizureStartMark * stepSize/fs;
    %         timeEnd = timePoints(end, 2) / fs - seizureStartMark * stepSize/fs;
    %         XLim = get(gca, 'XLim');
    %         XLowerLim = XLim(1);
    %         XUpperLim = XLim(2);
    %         xTickStep = (XUpperLim) / 10;
    %         xTicks = round(timeStart : (abs(timeEnd - timeStart)) / 10 : timeEnd);
    %         set(gca, 'XTick', (XLowerLim+0.5 : xTickStep : XUpperLim+0.5)); set(gca, 'XTickLabel', xTicks); % set xticks and their labels
        end % end of loop through channels
        reject_cell(iThresh) = length(thresholdindices) / numTimes; % store the ratio of data rejected
    %     reject_cell{iThresh} = thresholdindices;
<<<<<<< HEAD
    end % end of loop through filter thresholds
    % toc
=======
    end
    % toc`
>>>>>>> 67d73ba487e0b9785d928ad0d32cd0df99f5b51c

    thresh_sense(iPat, :) = reject_cell;
end

figure;
shadedErrorBar(thresholds, mean(thresh_sense), std(thresh_sense)); hold on;
xlabel('Thresholds');
ylabel('% of time Window Loss');
plot(get(gca, 'XLim'), [0.1, 0.1], 'k--');
ylim([0 1]);
title('Data Loss vs Threshold For NIH 6-16 patients');



