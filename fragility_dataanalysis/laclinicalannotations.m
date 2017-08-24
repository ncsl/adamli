if strcmp(patient_id, 'LA01')
    included_channels = [1:4 7:19 21:29 32:37 42:43 46:108 110:128];
    onset_electrodes = {'Y''1', 'X''4'};
    earlyspread_labels = {};
    latespread_labels = {};
    resection_labels = {};
    
    success_or_failure = 1;
    center = 'laserablation';
elseif strcmp(patient_id, 'LA02')
    included_channels = [1:4 7:19 21:37 46:47 50:101];
    onset_electrodes = {'L''2', 'L''3', 'L''4'};
    earlyspread_labels = {};
    latespread_labels = {};
    resection_labels = {};
    
    success_or_failure = 1;
    center = 'laserablation';
elseif strcmp(patient_id, 'LA03')
    included_channels = [1:3 6:33 36:68 77:163];
    onset_electrodes = {'L7'};
    earlyspread_labels = {};
    latespread_labels = {};
    resection_labels = {};
    
    success_or_failure = 1;
    center = 'laserablation';
elseif strcmp(patient_id, 'LA04')
    included_channels = [1:4 7:19 21:33 44:129];
    onset_electrodes = {'L''4', 'G''1'};
    earlyspread_labels = {};
    latespread_labels = {};
    resection_labels = {};
    
    success_or_failure = 1;
    center = 'laserablation';
elseif strcmp(patient_id, 'LA05')
    included_channels = [1:4 7:19 21:39 42:191];
    onset_electrodes = {'T''1', 'T''2', 'D''1', 'D''2'};
    earlyspread_labels = {};
    latespread_labels = {};
    resection_labels = {};
    
    success_or_failure = 1;
    center = 'laserablation';
elseif strcmp(patient_id, 'LA06')
    included_channels = [1:4 7:19 21:37 30:37 46:47 50:121];
    onset_electrodes = {'Q''3', 'Q''4', 'R''3', 'R''4'};
    earlyspread_labels = {};
    latespread_labels = {};
    resection_labels = {};
    
    success_or_failure = 1;
    center = 'laserablation';
elseif strcmp(patient_id, 'LA07')
    included_channels = [];
    onset_electrodes = {'T1', 'T3', 'R''8', 'R''9'};
    earlyspread_labels = {};
    latespread_labels = {};
    resection_labels = {};
    
    success_or_failure = 1;
    center = 'laserablation';
elseif strcmp(patient_id, 'LA08')
    included_channels = [1:4 7:19 21:37 42:43 46:149];
    onset_electrodes = {'Q2'};
    earlyspread_labels = {};
    latespread_labels = {};
    resection_labels = {};
    
    success_or_failure = 0;
    center = 'laserablation';
elseif strcmp(patient_id, 'LA09')
    included_channels = [1:4 7:19 21:39 42:191];
    onset_electrodes = {'P''1', 'P''2'};
    earlyspread_labels = {};
    latespread_labels = {};
    resection_labels = {};
    
    success_or_failure = 0;
    center = 'laserablation';
elseif strcmp(patient_id, 'LA10')
    included_channels = [1:4 7:19 21:37 46:47 50:185];
    onset_electrodes = {'S1', 'S2', 'R2', 'R3'};
    earlyspread_labels = {};
    latespread_labels = {};
    resection_labels = {};
    
    success_or_failure = 0;
    center = 'laserablation';
elseif strcmp(patient_id, 'LA11')
    included_channels = [1:4 7:19 21:39 42:191];
    onset_electrodes = {'D6', 'Z10'};
    earlyspread_labels = {};
    latespread_labels = {};
    resection_labels = {};
    
    success_or_failure = 0;
    center = 'laserablation';
elseif strcmp(patient_id, 'LA12')
    included_channels = [];
    onset_electrodes = {'S1', 'S2', 'R2', 'R3'};
    earlyspread_labels = {};
    latespread_labels = {};
    resection_labels = {};
    
    success_or_failure = 0;
    center = 'laserablation';
elseif strcmp(patient_id, 'LA13')
    included_channels = [];
    onset_electrodes = {'Y13', 'Y14'};
    earlyspread_labels = {};
    latespread_labels = {};
    resection_labels = {};
    
    success_or_failure = 0;
    center = 'laserablation';
elseif strcmp(patient_id, 'LA14')
    included_channels = [];
    onset_electrodes = {'X''1', 'X''2'};
    earlyspread_labels = {};
    latespread_labels = {};
    resection_labels = {};
    
    success_or_failure = 0;
    center = 'laserablation';
elseif strcmp(patient_id, 'LA15')
    included_channels = [];
    onset_electrodes = {'R1', 'R2', 'R3'};
    earlyspread_labels = {};
    latespread_labels = {};
    resection_labels = {};
    
    success_or_failure = 0;
    center = 'laserablation';
elseif strcmp(patient_id, 'LA16')
    included_channels = [1:4 7:19 21:39 42:189];
    onset_electrodes = {'Q7', 'Q8'};
    earlyspread_labels = {};
    latespread_labels = {};
    resection_labels = {};
    
    success_or_failure = 0;
    center = 'laserablation';
elseif strcmp(patient_id, 'LA17')
    included_channels = [];
    onset_electrodes = {'X''1', 'Y''1'};
    earlyspread_labels = {};
    latespread_labels = {};
    resection_labels = {};
    
    success_or_failure = 0;
    center = 'laserablation';
elseif strcmp(patient_id, 'Pat2')
    included_channels = [1:4 7:19 21:37 46:47 50:100];

    %- took out supposed gray matter received from Zach April 2017
    included_channels = [1:4 7 9 11:12 15:18 21:28 30:34 47 50:62 64:67 70:73 79:87 90 95:99];
    onset_electrodes = {'POL L''2', 'POL L''3', 'POL L''4'};
    earlyspread_labels = {};
    latespread_labels = {};

    resection_labels = {};

    center = 'laserablation';
elseif strcmp(patient_id, 'Pat16')
    included_channels = [1:4 7:19 21:39 42:121 124:157 178:189];

    %- took out supposed gray matter received from Zach
    included_channels = [1:3 10:16 23:24 28 31:35 37:39 42:44 46:47 49:54 58:62 64:65 68:70 76:89 93:98 ...
        100:101 105:121 124 126 128:130 132:134 136:140 142:144 149:156 178:181 183:189];

    onset_electrodes = {'POL Q7', 'POL Q8'};
    earlyspread_labels = {};
    latespread_labels = {};

    resection_labels = {};

    center = 'laserablation';
end