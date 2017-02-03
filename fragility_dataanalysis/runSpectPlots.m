patients = {,...,
%      'pt1aw1','pt1aw2', ...
%     'pt1aslp1', 'pt1aslp2', ...
%     'pt2aw1', 'pt2aw2', ...
%     'pt2aslp1', 
%     'pt2aslp2', ...
%     'pt3aslp1', 'pt3aslp2', ...
    'pt15sz1' 'pt15sz2' 'pt15sz3' 'pt15sz4',...
    'pt17sz1' 'pt17sz2',...
%     'pt3aw1', ...
%     'pt3aslp1', 'pt3aslp2', ...
%     'pt1sz2', 'pt1sz3', 'pt1sz4',...
%     'pt2sz1' 'pt2sz3' 'pt2sz4', ...
%     'pt3sz2' 'pt3sz4', ...
%     'pt6sz3', 'pt6sz4', 'pt6sz5',...
%     'pt8sz1' 'pt8sz2' 'pt8sz3',...
%     'pt10sz1' 'pt10sz2' 'pt10sz3', ...
%     'pt11sz1' 'pt11sz2' 'pt11sz3' 'pt11sz4', ...
%     'pt14sz1' 'pt14sz2' 'pt14sz3' 
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
%    'EZT037seiz001', 'EZT037seiz002',...
%    'EZT019seiz001', 'EZT019seiz002',...
%    'EZT005seiz001', 'EZT005seiz002', 'EZT007seiz001', 'EZT007seiz002', ...
%    	'EZT070seiz001', 'EZT070seiz002', ...
    };


close all;
% data parameters to find correct directory
winSize = 500;            % 500 milliseconds
stepSize = 250; 
frequency_sampling = 1000; % in Hz
% TEST_DESCRIP = 'noleftandrpp';
TEST_DESCRIP = [];
TYPE_CONNECTIVITY = 'leastsquares';
FONTSIZE = 18;

figDir = './figures/spectralanalysis/';

%% array of frequency bands
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
freqBandYticks  = unique([freqBandAr(1:7).rangeF]);
for iFB=1:length(freqBandYticks), freqBandYtickLabels{iFB} = sprintf('%.0f Hz', freqBandYticks(iFB)); end
freqBandYtickLabels = {freqBandAr.label};

% add libraries of functions
addpath(genpath('./fragility_library/'));
addpath(genpath('/Users/adam2392/Dropbox/eeg_toolbox'));
addpath(genpath('/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/eeg_toolbox/'));

% data directories to save data into - choose one
eegRootDirWork = '/Users/liaj/Documents/MATLAB/paremap';     % work
% eegRootDirHome = '/Users/adam2392/Documents/MATLAB/Johns Hopkins/NINDS_Rotation';  % home
eegRootDirHome = '/Volumes/NIL_PASS';
eegRootDirJhu = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/data';
% Determine which directory we're working with automatically
if     ~isempty(dir(eegRootDirWork)), eegRootDir = eegRootDirWork;
elseif ~isempty(dir(eegRootDirHome)), eegRootDir = eegRootDirHome;
elseif ~isempty(dir(eegRootDirJhu)), eegRootDir = eegRootDirJhu;
else   error('Neither Work nor Home EEG directories exist! Exiting'); end

% define cell function to search for the EZ labels
cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));

%%- Begin Loop Through Different Patients Here
for p=1:length(patients)
    patient = patients{p};

    % set patientID and seizureID
    patient_id = patient(1:strfind(patient, 'seiz')-1);
    seizure_id = strcat('_', patient(strfind(patient, 'seiz'):end));
    seeg = 1;
    interictal = 0;
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'sz')-1);
        seizure_id = patient(strfind(patient, 'sz'):end);
        seeg = 0;
    end
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'aslp')-1);
        seizure_id = patient(strfind(patient, 'aslp'):end);
        seeg = 0;
        interictal = 1;
    end
    if isempty(patient_id)
        patient_id = patient(1:strfind(patient, 'aw')-1);
        seizure_id = patient(strfind(patient, 'aw'):end);
        seeg = 0;
        interictal = 1;
    end
    
    if strcmp(patient_id, 'pt2')
        elecs_to_plot = {'POLLF1', 'POLG27'};
    elseif strcmp(patient_id, 'pt3')
        elecs_to_plot = {'POLFG30', 'POLFG31', 'POLFG32'};
    elseif strcmp(patient_id, 'pt15')
        elecs_to_plot = {'POLLSF8', 'POLPST2'};
    elseif strcmp(patient_id, 'pt17')
        elecs_to_plot = {'POLG6', 'POLG7'};
    end

    [included_channels, ezone_labels, earlyspread_labels, latespread_labels, ...
        resection_labels, frequency_sampling, center] ...
            = determineClinicalAnnotations(patient_id, seizure_id);
     
    % add random channel in ezone_label
    elecs_to_plot{end+1} = ezone_labels{1};
        
    %%- Define the raw data struct and extract it's contents
    if seeg
        patient = strcat(patient_id, seizure_id);
        eegDir = fullfile(eegRootDir, center);
        data_struct = load(fullfile(eegDir, patient_id, patient));
    else
        eegDir = fullfile(eegRootDir, center);
        data_struct = load(fullfile(eegDir, patient, patient));
    end
    

    [numChannels, eventDurationMS] = size(data_struct.data);
    elec_labels = data_struct.elec_labels;
    seizure_start = data_struct.seiz_start_mark;
    seizure_end = data_struct.seiz_end_mark;
    data = data_struct.data;
     
    %%- Define the spectral directory to extract the morlet wavelet
    %%- computed data
    serverDir = './serverdata/';
    
    %%- Extract an example
    spectDir = fullfile(serverDir, 'spectral_analysis', strcat('win', num2str(winSize), ...
        '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), patient);
    
    if ~isempty(TEST_DESCRIP)
        spectDir = fullfile(spectDir, TEST_DESCRIP);
    end

    elecFiles = dir(fullfile(spectDir, '*.mat'));
    elecFiles = natsortfiles({elecFiles.name});

    figure;
    for iChan=1:length(elecs_to_plot) % loop over every channel in this patient
        chan = elecs_to_plot{iChan};
        indice = cellfun(cellfind(chan), elec_labels, 'UniformOutput', 0);
        indice = [indice{:}];
        
        fileToLoad = fullfile(spectDir, elecFiles{indice});
        data = load(fileToLoad);
        data = data.data;
        seizureStart = data.seizure_start;
        if seizureStart ~= length(data.eegWave)
            seizureStart = seizureStart/data.stepSize;
        end
          
        % extract frequency, time axis for this dataset
        freqs = data.freqs;
        ticks = data.waveT(:,2);
        ticks = ticks(1:length(ticks)/5:end);
        [~,idx] = intersect(data.waveT(:,2), ticks);

        % perform plotting of data
        fig{iChan} = subplot(length(elecs_to_plot), 1, iChan);
        imagesc(data.powerMat); set(gca, 'Box', 'off'); hold on;
        cbar = colorbar(); colormap('jet');
        clim = get(gca, 'CLim');
        if iChan==1
            minclim = clim(1);
            maxclim = clim(2);
        else
            minclim = min(clim(1), minclim);
            maxclim = max(clim(2), maxclim);
        end
        % set the heat map settings
%         set(gca,'ytick',[1:7],'yticklabel',freqBandYtickLabels)
        set(gca,'ytick',[1:4:41], 'yticklabel', freqs(1:4:41), 'FontSize', FONTSIZE)
        ylabel('Freq (Hz)', 'FontSize', FONTSIZE);
        set(gca,'tickdir','out','YDir','normal'); % spectrogram should have low freq on the bottom
        ax = gca;
        title(['Spectral Power for ', patient, ' at electrode: ', chan], 'FontSize', FONTSIZE);
        xlabel('Time (sec)', 'FontSize', FONTSIZE);
        
        if interictal
            ax.XTick = idx;
            ax.XTickLabel = ticks/frequency_sampling;
        else
            ax.XTick = idx;
            seizmark = data.seizure_start / data.stepSize - 1;
            seiztime = data.waveT(seizmark,2);
            ticks = ticks - data.waveT(seizmark,2);
            ax.XTickLabel = ticks/frequency_sampling;
            
            plot([seizmark seizmark], get(gca, 'YLim'), 'k-', 'MarkerSize', 1.5);
        end
    end
    currfig = gcf;
    for iChan=1:length(fig)
        fig{iChan};
        set(fig{iChan}, 'CLim', [minclim, maxclim]);
    end

    % save the figure of spectral power
    currfig.PaperPosition = [-3.7448   -0.3385   15.9896   11.6771];
    currfig.Position = [1986           1        1535        1121];
    patFigDir = fullfile(figDir, patient);
    if ~exist(patFigDir, 'dir')
        mkdir(patFigDir);
    end
    toSaveFigFile = fullfile(figDir, patient, strcat(patient, '_spectral'));
   % save the figure  
    print(toSaveFigFile, '-dpng', '-r0')
    
    close all
end