% data directories to save data into - choose one
eegRootDirServer = '/home/ali/adamli/fragility_dataanalysis/';     % work
% eegRootDirHome = '/Users/adam2392/Documents/adamli/fragility_dataanalysis/';  % home
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

dataDir = fullfile(rootDir, 'data');

filename = '/home/WIN/ali39/Dropbox/EZTrack-Prospective-Study/ccsheet.csv';
delimiter = ',';
startRow = 2;

%% Read columns of data as strings:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'HeaderLines' ,startRow-1, 'ReturnOnError', false);

%% Close the text file.
fclose(fileID);

%% Convert the contents of columns containing numeric strings to numbers.
% Replace non-numeric strings with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = dataArray{col};
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[2,9,10,12]
    % Converts strings in the input cell array to numbers. Replaced non-numeric
    % strings with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1);
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData{row}, regexstr, 'names');
            numbers = result.numbers;
            
            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if any(numbers==',');
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(numbers, thousandsRegExp, 'once'));
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric strings to numbers.
            if ~invalidThousandsSeparator;
                numbers = textscan(strrep(numbers, ',', ''), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch me
        end
    end
end

dateFormatIndex = 1;
blankDates = cell(1,size(raw,2));
anyBlankDates = false(size(raw,1),1);
invalidDates = cell(1,size(raw,2));
anyInvalidDates = false(size(raw,1),1);
for col=[4,5,6,7,8]% Convert the contents of columns with dates to MATLAB datetimes using date format string.
    try
        dates{col} = datetime(dataArray{col}, 'Format', 'HH:mm:ss', 'InputFormat', 'HH:mm:ss'); %#ok<SAGROW>
    catch
        try
            % Handle dates surrounded by quotes
            dataArray{col} = cellfun(@(x) x(2:end-1), dataArray{col}, 'UniformOutput', false);
            dates{col} = datetime(dataArray{col}, 'Format', 'HH:mm:ss', 'InputFormat', 'HH:mm:ss'); %%#ok<SAGROW>
        catch
            dates{col} = repmat(datetime([NaN NaN NaN]), size(dataArray{col})); %#ok<SAGROW>
        end
    end
    
    dateFormatIndex = dateFormatIndex + 1;
    blankDates{col} = cellfun(@isempty, dataArray{col});
    anyBlankDates = blankDates{col} | anyBlankDates;
    invalidDates{col} = isnan(dates{col}.Hour) - blankDates{col};
    anyInvalidDates = invalidDates{col} | anyInvalidDates;
end
dates = dates(:,[4,5,6,7,8]);
blankDates = blankDates(:,[4,5,6,7,8]);
invalidDates = invalidDates(:,[4,5,6,7,8]);

%% Split data into numeric and cell columns.
rawNumericColumns = raw(:, [2,9,10,12]);
rawCellColumns = raw(:, [1,3,11]);


%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

%% Allocate imported array to column variable names
Identifier = rawCellColumns(:, 1);
Frequency = cell2mat(rawNumericColumns(:, 1));
DateofSz = rawCellColumns(:, 2);
RecordingStart = dates{:, 1};
EOnset = dates{:, 2};
EOffset = dates{:, 3};
COnset = dates{:, 4};
COffset = dates{:, 5};
channels = cell2mat(rawNumericColumns(:, 2));
RecordingDurations = cell2mat(rawNumericColumns(:, 3));
SuccessFailure = rawCellColumns(:, 3);
EngelScores = cell2mat(rawNumericColumns(:, 4));

clinicaldata = struct();
% for each identifier
for id=1:length(Identifier)
    patient = Identifier{id};
    
    clinicaldata.(patient).frequency = Frequency(id);
    clinicaldata.(patient).date = DateofSz{id};
    clinicaldata.(patient).seizure_eonset_ms = milliseconds(EOnset(id) - RecordingStart(id));
    clinicaldata.(patient).seizure_eoffset_ms = milliseconds(EOffset(id) - RecordingStart(id));
    clinicaldata.(patient).seizure_conset_ms = milliseconds(COnset(id) - RecordingStart(id));
    clinicaldata.(patient).seizure_coffset_ms = milliseconds(COffset(id) - RecordingStart(id));
    clinicaldata.(patient).recording_duration_sec = RecordingDurations(id);
    clinicaldata.(patient).numChans = channels(id);
    clinicaldata.(patient).outcome = SuccessFailure{id};
    clinicaldata.(patient).engelscore = EngelScores(id);
end

save(fullfile(dataDir, 'ccclinicalData.mat'), 'clinicaldata');