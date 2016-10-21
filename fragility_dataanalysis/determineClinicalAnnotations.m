function [included_channels, ezone_labels, earlyspread_labels, latespread_labels] ...
                = determineClinicalAnnotations(patient_id)
    if strcmp(patient_id, 'EZT007')
        included_channels = [1:16 18:53 55:71 74:78 81:94];
        ezone_labels = {'O7', 'E8', 'E7', 'I5', 'E9', 'I6', 'E3', 'E2',...
            'O4', 'O5', 'I8', 'I7', 'E10', 'E1', 'O6', 'I1', 'I9', 'E6',...
            'I4', 'O3', 'O2', 'I10', 'E4', 'Y1', 'O1', 'I3', 'I2'}; %pt1
        earlyspread_labels = {};
        latespread_labels = {};
    elseif strcmp(patient_id, 'EZT005')
        included_channels = [1:21 23:60 63:88];
        ezone_labels = {'U4', 'U3', 'U5', 'U6', 'U8', 'U7'}; 
        earlyspread_labels = {};
         latespread_labels = {};
    elseif strcmp(patient_id, 'EZT019')
        included_channels = [1:5 7:22 24:79];
        ezone_labels = {'I5', 'I6', 'B9', 'I9', 'T10', 'I10', 'B6', 'I4', ...
            'T9', 'I7', 'B3', 'B5', 'B4', 'I8', 'T6', 'B10', 'T3', ...
            'B1', 'T8', 'T7', 'B7', 'I3', 'B2', 'I2', 'T4', 'T2'}; 
        earlyspread_labels = {};
         latespread_labels = {}; 
     elseif strcmp(patient_id, 'EZT045') % FAILURES 2 EZONE LABELS?
        included_channels = [1 3:14 16:20 24:28 30:65];
        ezone_labels = {'X2', 'X1'}; %pt2
        earlyspread_labels = {};
         latespread_labels = {}; 
      elseif strcmp(patient_id, 'EZT090') % FAILURES
        included_channels = [1:25 27:42 44:49 51:73 75:90 95:111];
        ezone_labels = {'N2', 'N1', 'N3', 'N8', 'N9', 'N6', 'N7', 'N5'}; 
        earlyspread_labels = {};
         latespread_labels = {};
    elseif strcmp(patient_id, 'EZT108')
        included_channels = [];
        ezone_labels = {'F2', 'V7', 'O3', 'O4'}; % marked ictal onset areas
        earlyspread_labels = {};
        latespread_labels = {};
    elseif strcmp(patient_id, 'EZT120')
        included_channels = [];
        ezone_labels = {'C7', 'C8', 'C9', 'C6', 'C2', 'C10', 'C1'};
        earlyspread_labels = {};
        latespread_labels = {};
    elseif strcmp(patient_id, 'Pat2')
        included_channels = [];
        ezone_labels = {};
        earlyspread_labels = {};
        latespread_labels = {};
    elseif strcmp(patient_id, 'Pat16')
        included_channels = [];
        ezone_labels = {};
        earlyspread_labels = {};
        latespread_labels = {};
    elseif strcmp(patient_id, 'pt7')
        included_channels = [1:17 19:35 37:38 41:62 67:109];
        ezone_labels = {};
        earlyspread_labels = {};
        latespread_labels = {};
    elseif strcmp(patient_id, 'pt1')
        included_channels = [1:36 42 43 46:69 72:95];
        ezone_labels = {'POLATT1', 'POLATT2', 'POLAD1', 'POLAD2', 'POLAD3'}; %pt1
        earlyspread_labels = {'POLATT3', 'POLAST1', 'POLAST2'};
        latespread_labels = {'POLATT4', 'POLATT5', 'POLATT6', ...
                            'POLSLT2', 'POLSLT3', 'POLSLT4', ...
                            'POLMLT2', 'POLMLT3', 'POLMLT4', 'POLG8', 'POLG16'};
    elseif strcmp(patient_id, 'pt2')
        included_channels = [1:14 16:19 21:25 27:37 43 44 47:74];
        ezone_labels = {'POLMST1', 'POLPST1', 'POLTT1'}; %pt2
        earlyspread_labels = {'POLTT2', 'POLAST2', 'POLMST2', 'POLPST2', 'POLALEX1', 'POLALEX5'};
         latespread_labels = {};
    elseif strcmp(patient_id, 'JH105')
        included_channels = [1:4 7:12 14:19 21:37 42 43 46:49 51:53 55:75 78:99]; % JH105
        ezone_labels = {'POLRPG4', 'POLRPG5', 'POLRPG6', 'POLRPG12', 'POLRPG13', 'POLG14',...
            'POLAPD1', 'POLAPD2', 'POLAPD3', 'POLAPD4', 'POLAPD5', 'POLAPD6', 'POLAPD7', 'POLAPD8', ...
            'POLPPD1', 'POLPPD2', 'POLPPD3', 'POLPPD4', 'POLPPD5', 'POLPPD6', 'POLPPD7', 'POLPPD8', ...
            'POLASI3', 'POLPSI5', 'POLPSI6', 'POLPDI2'}; % JH105
        earlyspread_labels = {};
         latespread_labels = {};
     elseif strcmp(patient_id, 'JH104') % strip patient
        included_channels = [1:12 14:19 21:37 42:43 46:82];
        ezone_labels = {'POLLAT1', 'POLLAT2', 'POLMBT5', 'POLMBT6', 'POLPBT4'};
        earlyspread_labels = {'POLLPF5', 'POLLPF6', 'POLLFP2', 'POLLFP3', 'POLLFP4'};
        latespread_labels = {};
    elseif strcmp(patient_id, 'EZT030')
        included_channels = [];
        ezone_labels = {'Q11', 'L6', 'M9', 'N9', 'W9'};
        earlyspread_labels = {};
        latespread_labels = {};
    elseif strcmp(patient_id, 'EZT037')
        included_channels = [];
        ezone_labels = {'C1', 'C2', 'I1', 'I2', 'I3', 'I4', 'I5', 'B1', 'B2', 'E1', 'E2', 'E3', 'E4', ...
            'E5', 'E6', 'E7', 'E8', 'E9', 'E10'};
        earlyspread_labels = {};
        latespread_labels = {};
    elseif strcmp(patient_id, 'EZT070')
        included_channels = [1:82 84:94];
        ezone_labels = {'B8', 'B9', 'B10', 'T4', 'T5', 'T6', 'T7'};
        earlyspread_labels = {};
        latespread_labels = {};
    end
    
end