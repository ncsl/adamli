function [included_channels, ezone_labels, ...
    earlyspread_labels, latespread_labels, ...
    resection_labels, frequency_sampling, center] ...
                = determineClinicalAnnotations(patient_id, seizure_id)
    frequency_sampling = 1000; % general default sampling frequency
    resection_labels = {};     % initialize resection labels
    
    if strcmp(patient_id, 'EZT007')
        included_channels = [1:16 18:53 55:71 74:78 81:94];
        ezone_labels = {'O7', 'E8', 'E7', 'I5', 'E9', 'I6', 'E3', 'E2',...
            'O4', 'O5', 'I8', 'I7', 'E10', 'E1', 'O6', 'I1', 'I9', 'E6',...
            'I4', 'O3', 'O2', 'I10', 'E4', 'Y1', 'O1', 'I3', 'I2'}; %pt1
        earlyspread_labels = {};
        latespread_labels = {};
        center = 'cc';
    elseif strcmp(patient_id, 'EZT004')
        included_channels = [1:7 9:10 12:22 24:49 51:60 62:73];
        
        if strcmp(seizure_id, 'seiz002')
            included_channels = [1:7 9:10 12:22 24:49 51:60 63:70 72];
        end
        
        ezone_labels = {'C2', 'C3', 'B2', 'B3', 'E1', 'E2', 'E3',...
                        'U2', 'U3', 'W1', 'Z1', 'O7', 'O8', 'X1', 'X2', ...
                        'X3', 'Y1', 'Y2', 'Y3'};
        earlyspread_labels = {};
        latespread_labels = {};
        resection_labels = {};
        
        center = 'cc';
    elseif strcmp(patient_id, 'EZT005')
        included_channels = [1:21 23:60 63:88];
        ezone_labels = {'U3', 'U4','U5', 'U6', 'U7', 'U8'}; 
        earlyspread_labels = {'L4', 'L5', 'C6', 'C9', 'S1', 'S2', ...
            'S3', 'S4', 'S5', 'S6', 'S7', 'S8', 'P1', 'P2', 'P3', ...
            'P4', 'P5', 'P6', 'P7', 'P8', 'W5', 'W6', 'W7', 'H5', 'H6', 'H7', ...
            'Y5', 'Y6', 'Y7', 'Y8','X6', 'X7', 'X8', 'M2', 'M3', 'M4', 'M5',...
            'N2', 'N3', 'N4', 'N5', 'N6'};
         latespread_labels = {};
         center = 'cc';
    elseif strcmp(patient_id, 'EZT006')
        included_channels = [1:14 17:35 38:42 45:76];
        ezone_labels = {'N1','N2', 'Y2'};
        earlyspread_labels = {};
        latespread_labels = {};
        resection_labels = {};
        
        center = 'cc';
        
    elseif strcmp(patient_id, 'EZT008')
        included_channels = [1:3 5 7:9 11:93 95 97:98 100 102:105];
        ezone_labels = {};
        earlyspread_labels = {};
        latespread_labels = {};
        resection_labels = {};
        
        center = 'cc';
    elseif strcmp(patient_id, 'EZT009')
        included_channels = [1:32 34:43 45:85];
        ezone_labels = {'Q5', 'Q6', 'O4', 'O6', 'O7', 'Y1', 'Y2', 'Y3',...
            'X1', 'X2', 'X3', 'X4', 'X5'};
        earlyspread_labels = {'B5', 'B6', 'B7', 'B8', 'B9', 'C5', 'C6', ...
            'C7', 'C8', 'C9','E4', 'E5', 'E6', 'E7', 'E8', ...
            'B1', 'B2', 'C1', 'C2', 'E1', 'E2', 'E3'};
        latespread_labels = {};
        resection_labels = {};
        
        center = 'cc';
    elseif strcmp(patient_id, 'EZT011')
        included_channels = [1:23 25:81];
        
        if strcmp(seizure_id, 'seiz001') % second removal
            included_channels = [1:23 25:63 65:81];
        end
        
        ezone_labels = {'B1', 'B2'};
        earlyspread_labels = {};
        latespread_labels = {};
        resection_labels = {};
        
        center = 'cc';
        
    elseif strcmp(patient_id, 'EZT013')
        included_channels = [1:28 31:51 53 55:110];
        ezone_labels = {'X5', 'X6', 'X7', 'L1', 'L2', 'S1', 'S2', ...
            'L3','L4', 'S3', 'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'F1', 'F2', 'F3', 'F4'};
        earlyspread_labels = {};
        latespread_labels = {};
        resection_labels = {};
        
        center = 'cc';
        
    elseif strcmp(patient_id, 'EZT019')
        % resections: A,B,C,E,I AND likely T
        included_channels = [1:5 7:22 24:79];
%         ezone_labels = {'I5', 'I6', 'B9', 'I9', 'T10', 'I10', 'B6', 'I4', ...
%             'T9', 'I7', 'B3', 'B5', 'B4', 'I8', 'T6', 'B10', 'T3', ...
%             'B1', 'T8', 'T7', 'B7', 'I3', 'B2', 'I2', 'T4', 'T2'}; 
        ezone_labels = {'B2', 'B3', 'B4', 'C1', 'C2'};
%         ezone_labels = {'B3', 'B4', 'C2'}; % to run estimation alg win size testing
        earlyspread_labels = {'E1', 'E2', 'C3', 'X1', 'X2'};
        latespread_labels = {}; 
        resection_labels = {'A', 'B', 'C', 'E', 'I', 'X'}
        center = 'cc';
        
    elseif strcmp(patient_id, 'EZT020')
        included_channels = [1:18 20:40 42:49 55:60 63:79 81 83:86 88:124];
        ezone_labels = {'B1', 'B2', 'B3', 'C1', 'C2', 'C3', ...
            'O2','O3'};
        earlyspread_labels = {};
        latespread_labels = {};
        resection_labels = {};
        
        center = 'cc';
        
    elseif strcmp(patient_id, 'EZT025')
        included_channels = [1:28 30:38 43:98];
        ezone_labels = {};
        earlyspread_labels = {};
        latespread_labels = {};
        resection_labels = {};
        
        center = 'cc';
        
    elseif strcmp(patient_id, 'EZT026')
        included_channels = [];
        ezone_labels = {'C1', 'C2', 'C3', 'E1', 'E2', 'E3', 'E4', ...
            'B1', 'B2','B3', 'V1', 'W1', 'O1', 'O2', ...
            'X1', 'X2', 'X3', 'X4'};
        earlyspread_labels = {};
        latespread_labels = {};
        resection_labels = {};
        
        center = 'cc';
    elseif strcmp(patient_id, 'EZT028')
        included_channels = [];
        ezone_labels = {'P1','P2','P3','P4','P5','P6','P7',...
            'W1','W2'};
        earlyspread_labels = {'R4','R5','R6','R7','R8','X5','X6','X7',...
            'S3','S4','S5','S6','S7','S8'};
        latespread_labels = {'M2','M3','M4','M5','M6', 'Y8', 'Y9'};

        center = 'cc';
    elseif strcmp(patient_id, 'EZT030') % general seizures
        included_channels = [];
        ezone_labels = {'Q11', 'L6', 'M9', 'N9', 'W9'};
        earlyspread_labels = {};
        latespread_labels = {};
        
        center = 'cc';
    elseif strcmp(patient_id, 'EZT037')
        % resections: A,B,C
        included_channels = [];
%         ezone_labels = {'C1', 'C2', 'I1', 'I2', 'I3', 'I4', 'I5', 'B1', 'B2', 'E1', 'E2', 'E3', 'E4', ...
%             'E5', 'E6', 'E7', 'E8', 'E9', 'E10'};
        ezone_labels = {'A1', 'B1', 'B2'}; % clinical notes of onset
        earlyspread_labels = {};
        latespread_labels = {};
        resection_labels = {'A', 'B', 'C'};
        
        center = 'cc';
     elseif strcmp(patient_id, 'EZT045') % FAILURES 2 EZONE LABELS?
        included_channels = [1 3:14 16:20 24:28 30:65];
        ezone_labels = {'X2', 'X1'}; %pt2
        earlyspread_labels = {};
         latespread_labels = {}; 
         
         center = 'cc';
     elseif strcmp(patient_id, 'EZT070')
        included_channels = [1:82 84:94];
        ezone_labels = {'B8', 'B9', 'B10', 'T4', 'T5', 'T6', 'T7'};
        earlyspread_labels = {'B4', 'B5', 'B6', 'C1', 'C2', 'C3', 'C4'};
        latespread_labels = {'E4', 'U5', 'U6', 'U7', 'W5', 'W6', 'F7', 'F8', ...
            'F9', 'F10', 'X8', 'X9', 'S3', 'S4', 'S5', 'S6', 'R1', 'R2'};
        
        center = 'cc';
      elseif strcmp(patient_id, 'EZT090') % FAILURES
        included_channels = [1:25 27:42 44:49 51:73 75:90 95:111];
        ezone_labels = {'N2', 'N1', 'N3', 'N8', 'N9', 'N6', 'N7', 'N5'}; 
        earlyspread_labels = {};
         latespread_labels = {};
         
         center = 'cc';
    elseif strcmp(patient_id, 'EZT108')
        included_channels = [];
        ezone_labels = {'F2', 'V7', 'O3', 'O4'}; % marked ictal onset areas
        earlyspread_labels = {};
        latespread_labels = {};
        center = 'cc';
    elseif strcmp(patient_id, 'EZT120')
        included_channels = [];
        ezone_labels = {'C7', 'C8', 'C9', 'C6', 'C2', 'C10', 'C1'};
        earlyspread_labels = {};
        latespread_labels = {};
        center = 'cc';
    elseif strcmp(patient_id, 'Pat2')
        included_channels = [];
        ezone_labels = {};
        earlyspread_labels = {};
        latespread_labels = {};
        
        center = 'cc';
    elseif strcmp(patient_id, 'Pat16')
        included_channels = [];
        ezone_labels = {};
        earlyspread_labels = {};
        latespread_labels = {};
        
        center = 'cc';
    elseif strcmp(patient_id, 'pt1')
        included_channels = [1:36 42 43 46:69 72:95];
        
        if strcmp(seizure_id, 'aslp1')
            included_channels = [1:36 42 43 46:54 56:60 62:69 72:95];
        end
        
%         included_channels = [1:36 42:69 72:95]; % to test automatic rejection
        
        ezone_labels = {'POLATT1', 'POLATT2', 'POLAD1', 'POLAD2', 'POLAD3', ...
            'POLAD4', 'POLPD1', 'POLPD2', 'POLPD3', 'POLPD4'}; %pt1
        earlyspread_labels = {'POLATT3', 'POLAST1', 'POLAST2'};
        latespread_labels = {'POLATT4', 'POLATT5', 'POLATT6', ...
                            'POLSLT2', 'POLSLT3', 'POLSLT4', ...
                            'POLMLT2', 'POLMLT3', 'POLMLT4', 'POLG8', 'POLG16'};
        resection_labels = {'POLATT', 'POLAST', 'POLPST', 'POLAD', 'POLPD', 'POLPLT5', 'POLPLT6', 'POLSLT1'};
        
        
        resection_labels = {'ATT', 'AST', 'PST', 'AD', 'PD', 'PLT', 'POLSLT'};
        center = 'nih';
    elseif strcmp(patient_id, 'pt2')
        included_channels = [1:14 16:19 21:25 27:37 43 44 47:74];
        
        if strcmp(seizure_id, 'aslp2')
            included_channels = [1:14 16:19 21:25 27:37 43 44 47:68];
        end
        if strcmp(seizure_id, 'aw2')
            included_channels = [1:14 16:19 21:25 27:37 43 44 47:68 70:74];
        end
%         included_channels = [1:19 21:37 43:74]; % to test automatic rejection
        
        ezone_labels = {'POLMST1', 'POLPST1', 'POLTT1'}; %pt2
        earlyspread_labels = {'POLTT2', 'POLAST2', 'POLMST2', 'POLPST2', 'POLALEX1', 'POLALEX5'};
        latespread_labels = {};
        resection_labels = {'POLTT', 'POLMST', 'POLAST', 'POLG1-4', 'POLG9-12', 'POLG18-20', 'POLG26', 'POLG27'};
        resection_labels = {'TT1', 'TT2', 'TT3', 'TT4', 'TT5', 'TT6', ...
                        'G1', 'G2', 'G3', 'G4', 'G9', 'G10', 'G11', 'G12', 'G18', 'G19', 'G20', 'G26', 'G27',...
                        'AST1', 'AST2', 'AST3', 'AST4',...
                        'MST1', 'MST2', 'MST3', 'MST4'};
        
        center = 'nih';
    elseif strcmp(patient_id, 'pt3')
        included_channels = [1:19 21:37 42 43 46:69 71:133 135];
        included_channels = [1:19 21:37 42:43 46:69 71:107]; % removing left hemisphere electrodes
        
%         included_channels = [1:37 42:69 71:107]; % testing test automatic rejection
        
        ezone_labels = {'POLSFP2', 'POLSFP3', 'POLOF4'}; % 'POLOF1', 'POLOF2', 'POLOF3'
        earlyspread_labels = {'POLSFP5', 'POLSFP6', 'POLIFP1', 'POLIFP2', 'POLIFP3'};
        latespread_labels = {};
        resection_labels = {'POLSFP', 'POLMFP', 'POLIFP', 'POLOF3', 'POLOF4', ...
                'POLFG1', 'POLFG2', 'POLFG9', 'POLFG10', 'POLFG17', 'POLFG18', 'POLFG25'};
        resection_labels = {'FG1', 'FG2', 'FG9', 'FG10', 'FG17', 'FG18', 'FG25', ...
            'SFP1', 'SFP2', 'SFP3', 'SFP4', 'SFP5', 'SFP6', 'SFP7', 'SFP8',...
            'MFP1', 'MFP2', 'MFP3', 'MFP4', 'MFP5', 'MFP6', ...
            'IFP1', 'IFP2', 'IFP3', 'IFP4', ...
            'OF3', 'OF4'};
            
        center = 'nih';
    elseif strcmp(patient_id, 'pt6')
        included_channels = [1:36 42:43 46 52:56 58:71 73:95];
        ezone_labels = {'POLLA1', 'POLLA2', 'POLLA3', 'POLLA4', 'POLLAH1', ...
            'POLLAH2', 'POLLAH3', 'POLLAH4', 'POLLPH1', 'POLLPH2', 'POLLPH3', 'POLLPH4'};
        earlyspread_labels = {};
        latespread_labels = {};
        
        center = 'nih';
     elseif strcmp(patient_id, 'pt7')
        included_channels = [1:17 19:35 37:38 41:62 67:109];
        ezone_labels = {};
        earlyspread_labels = {};
        latespread_labels = {};
        
        center = 'nih';
    elseif strcmp(patient_id, 'pt8')
        included_channels = [1:19 21 23 30:37 39:40 43:64 71:76];
        ezone_labels = {'POLG22','POLG23', 'POLG29', 'POLG30', 'POLG31', 'POLTO6', 'POLTO5', ...
                        'POLMST3', 'POLMST4'};
        earlyspread_labels = {};
         latespread_labels = {};
         
         center = 'nih';
    elseif strcmp(patient_id, 'pt10')
        included_channels = [1:3 5:10 12:19 21:22 24:35 48:85];
        included_channels = [1:3 5:10 12:19 21:22 24:35 48:69]; %w/o p ELECTRODES hfreq noise electrodes
        ezone_labels = {'POLTT4', 'POLTT6', 'POLTT1', 'POLTT2', 'POLMST1'};
        earlyspread_labels = {'POLMST2', 'POLAST2', 'POLTT3', 'POLTT5'};
        latespread_labels = {'POLPST1', 'POLPST2', 'POLPST3', 'POLPST4', ...
            'POLMST3', 'POLMST4', 'POLAST3', 'POLAST4', 'POLOF1', 'POLOF2', 'POLOF3', 'POLOF4', ...
            'POLG3', 'POLG4', 'POLG5', 'POLG6', 'POLG11', 'POLG12', 'POLG13', ...
            'POLG14', 'POLG15', 'POLG16', 'POLG20', 'POLG21', 'POLG22', 'POLG23', ...
            'POLG25', 'POLG28', 'POLG29', 'POLG30', 'POLG31', 'POLG32'};

        center = 'nih';
    elseif strcmp(patient_id, 'pt11')
        included_channels = [1:19 21:37 39 40 43:74 76:81 83:87 89:94 101:130];
        
        % removed G25, B2, B1, RIM, RIPI
        included_channels = [1:19 21:35 37 39 40 43:74 76:81 83:84 101:128];
        
%         if REGION_ONLY of microgrid electrodes
%             included_channels = [11:19 21:37 39:40 43:62];
%         end
        ezone_labels = {'POLRG24', 'POLRG32', 'POLRG40', 'POLRG39'};
        earlyspread_labels = {'POLRPG5', 'POLRPG6', 'POLRPG11', 'POLRPG12'};
         latespread_labels = {};
         
         center = 'nih';
         
    elseif strcmp(patient_id, 'pt12')
        included_channels = [1:15 17:33 38:39 42:61];
        
        ezone_labels = {};
        earlyspread_labels = {};
        latespread_labels = {};
        
        center = 'nih';
    elseif strcmp(patient_id, 'pt13')
        included_channels = [1:36 39:40 43:66 69:74 77 79:94 96:103 105:130];
        
        ezone_labels = {};
        earlyspread_labels = {};
        latespread_labels = {};
        
        center = 'nih';
        
    elseif strcmp(patient_id, 'pt14')
        included_channels = [1:19 21:37 41:42 45:61 68:78];
        
        if strcmp(seizure_id, 'sz3')
            included_channels = [1:17 19 21:37 41:42 45:61 68:78];
        end
        
        % removed G23, 15, G6, 7 (6 and 7 are not on clinical annotations -
        % 02/2/17)
        included_channels = [1:4 7:10 12:17 19 21:37 41:42 45:61 68:78];
        
        ezone_labels = {'POLMST1', 'POLMST2', 'POLTT1', 'POLTT2', 'POLTT3', ...
                        'POLAST1', 'POLAST2'};
        earlyspread_labels = {'POLOF1', 'POLOF2', 'POLOF3', 'POLOF4', 'POLPT4', 'POLPT5', ...
                            'POLG29', 'gitPOLG30', 'POLG31', 'POLG32'};
        latespread_labels = {};
        
        center = 'nih';
    elseif strcmp(patient_id, 'pt15')
        included_channels = [2:7 9:30 32:36 41:42 45:69 71:86 88:89];
        
        % excludes LSF8 and PST2 due to red strip and no R electrodes
        included_channels = [2:7 9:30 32:36 41:42 45:47 49:66 69 71:85]; 
        
        % 
        
        ezone_labels = {'POLTT1', 'POLTT2', 'POLTT3', 'POLTT4', ...
            'POLMST1', 'POLMST2', 'POLAST1', 'POLAST2', 'POLAST3'};
        if strcmp(seizure_id, 'sz1') % getting rid of TT5, which isn't in clinical EZ
            included_channels = [2:7 9:30 32:36 41:42 45:69 71:86 88:89];
            ezone_labels = {'POLTT1', 'POLTT2', 'POLTT3', 'POLTT4', 'POLTT5', ...
                        'POLMST1', 'POLMST2', 'POLAST1', 'POLAST2', 'POLAST3'};
        end
        earlyspread_labels = {'POLMST3', 'POLMST4', 'POLPST1', 'POLPST2', 'POLMST5'};
        latespread_labels = {'POLTO5', 'POLTO6', 'POLOF2', 'POLOF3', 'POLG22'};
        
        center = 'nih';
    elseif strcmp(patient_id, 'pt16')
        included_channels = [1:19 21:37 42:43 46:53 56:60];
        if strcmp(seizure_id, 'sz2')
            included_channels = [1:19 21:37 42:43 46:53 56:57]; % get rid of R3,R4,R5 with high freq noise
        end
        
        % remove R1 and R2 and entire R strip -> Ref electrodes
        included_channels = [1:19 21:37 42:43 46:53];
        
        ezone_labels = {'POLTT5', 'POLTT3', 'POLTT2', 'POLAST1'};
        earlyspread_labels = {'POLTT6', 'POLTT4', 'POLOF4', 'POLAST2', 'POLAST3', 'POLAST4',...
            'POLTT1', 'POLMST3', 'POLMST4', 'POLG18', 'POLG19', 'POLG20', 'POLG26', 'POLG27', 'POLG28'};
        latespread_labels = {};
        
        center = 'nih';
    elseif strcmp(patient_id, 'pt17')
        included_channels = [1:19 21:37 42:43 46:51 53];
        
        if strcmp(seizure_id, 'sz2') % get rid of G7,6,4 with high frequency noises
            included_channels = [1:19 21 23:25 28:37 42:43 46:51 53];
        end
        
        
        ezone_labels = {'POLTT', 'POLTT2'};
        earlyspread_labels = {'POLPST1', 'POLPST2', 'POLPST3', 'POLTT3'};
        latespread_labels = {'POLMST1', 'POLMST2', 'POLAST1'};
        frequency_sampling = 2000;
        
        center = 'nih';
    elseif strcmp(patient_id, 'JH101')
        included_channels = [1:4 7:19 21:37 42:43 46 48:63 72 75:86 90:119 122:135];
        
        included_channels = [1:4 7:19 21:37 42:43 46 48:63]; % w/o LTG electrodes
        ezone_labels = {'POLLAD1', 'POLLAD2', 'POLLAD3', 'POLLAD4', 'POLLAD5', 'POLLAD6'};
        earlyspread_labels = {};
        latespread_labels = {};
        
        center = 'jhu';
    elseif strcmp(patient_id, 'JH102') % strip dual seizure patient
        included_channels = [1:12 14:36 41:42 45:62 66:123];
        ezone_labels = {'POLRAT1', 'POLRAT2'};
        if strcmp(seizure_id, 'sz3') || strcmp(seizure_id, 'sz6')
            ezone_labels = {'POLLBT1', 'POLLBT2', 'POLLBT3', ...
                'POLLAT1', 'POLLAT2', 'POLLAT3'}; % uncertain still on lat/lbts
        end
        earlyspread_labels = {};
        latespread_labels = {};
        
        center = 'jhu';
    elseif strcmp(patient_id, 'JH103')
        included_channels = [1:4 7:12 15:23 25:33 47:63 65:66 69:71 73:110];
        
        
        ezone_labels = {};
        earlyspread_labels = {'POLRTG48', 'POLRTG40'};
        latespread_labels = {};
        
        center = 'jhu';
    elseif strcmp(patient_id, 'JH104') % strip patient
        included_channels = [1:12 14:19 21:37 42:43 46:69 72:74];
        ezone_labels = {'POLLAT1', 'POLLAT2', 'POLMBT5', 'POLMBT6', 'POLPBT4'};
        earlyspread_labels = {'POLLPF5', 'POLLPF6', 'POLLFP2', 'POLLFP3', 'POLLFP4'};
        latespread_labels = {};
        
        center = 'jhu';
    elseif strcmp(patient_id, 'JH105')
        included_channels = [1:4 7:12 14:19 21:37 42 43 46:49 51:53 55:75 78:99]; % JH105
        ezone_labels = {'POLRPG4', 'POLRPG5', 'POLRPG6', 'POLRPG12', 'POLRPG13', 'POLG14',...
            'POLAPD1', 'POLAPD2', 'POLAPD3', 'POLAPD4', 'POLAPD5', 'POLAPD6', 'POLAPD7', 'POLAPD8', ...
            'POLPPD1', 'POLPPD2', 'POLPPD3', 'POLPPD4', 'POLPPD5', 'POLPPD6', 'POLPPD7', 'POLPPD8', ...
            'POLASI3', 'POLPSI5', 'POLPSI6', 'POLPDI2'}; % JH105
        earlyspread_labels = {'POLLAT1' 'POLLAT2', 'POLLAT6', 'POLLAT7', 'POLLAT8'};
         latespread_labels = {};
         
         center = 'jhu';
    elseif strcmp(patient_id, 'JH106')
        included_channels = [1:4 7:12 14:19 21:37 42:75 77:80 82:102 104:133 138:147 150:181 184:196 198:213];
        
        % w/o LPT
        included_channels = [1:4 7:12 14:19 21:37 42:69 198:213];
        
        ezone_labels = {};
        earlyspread_labels = {};
        latespread_labels = {};
        
        center = 'jhu';
    elseif strcmp(patient_id, 'JH107')
        included_channels = [1:7 9:19 21:31 34:37 42:43 45 47:83];
        
%         find(included_channels==5)
%         find(included_channels==6)
%         find(included_channels==43)
%         find(included_channels==45)
        included_channels = [1:4 7 9:19 21:31 34:37 42 47:83]; % removal of noise electrodes 1/27/17
        ezone_labels = {};
        earlyspread_labels = {};
        latespread_labels = {};
        
        center = 'jhu';
    elseif strcmp(patient_id, 'JH108')
        included_channels = [1:4 7:12 14:16 18:19 21:37 42:43 46:47 51:69 72:147];
        
        included_channels = [1:4 7:12 14:16 18:19 21:37 42:43 46:47 51:69 72:82]; % w/o left hemisphere electrodes
        
        included_channels = [1:4 7:12 14:16 18:19 21:33 37 42:43 46:47 51:69 72:82]; % w/o left hemisphere electrodes & RPP electrodes
        ezone_labels = {'POLRDI1', 'POLRDI2', 'POLRDI3', 'POLRDI4', 'POLRSI1', 'POLRSI2', 'POLRSI3', 'POLRSI4'};
        earlyspread_labels = {'POLRPP1', 'POLRPP2'};
        latespread_labels = {};
        
        center = 'jhu';
    end
    
end