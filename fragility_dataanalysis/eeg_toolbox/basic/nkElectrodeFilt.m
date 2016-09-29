function [elecLabels,gl,bl,lBp,glBp,blBp] = nkElectrodeFilt(eegDir,subj,filestem)
% Function [filestem,elecLabels,lBp,glBp,blBp] = nkElectrodeFilt(eegDir,subj,filestem)
%
%   Description: Given a filestem, this function looks at the relevant
%   jacksheet and identifies those electrodes that were actually recorded
%   from for it. The function then returns those electrodes that were
%   actually recorded from as well as the different bipolar pairs for that
%   filestem. 
%
%   INPUT:
%         --eegDir=directory where data is held
%                  (ex. '/Users/damerasr/Sri/data/eeg/')
%         --subj=subject name (ex. 'NIH001')
%         --filestem = 'NIH001_121211_0933'
%
%   OUTPUT: 
%           --elecLabels: list of recording electrodes (from electrodes.m)
%    
%           --new leads_Bipolar.txt files and bipolar rerefrenced files
%               --lbp:  contains only those lead_bipolar pairs
%               --glBp: contains only those good_lead_bipolar 
%                       pairs that contain recording electrodes
%               --blBp: contains only those bad_lead_bipolar 
%                       pairs that contain recording electrodes



subjDir    = fullfile(eegDir,subj); % where subject data is located
taldir     = fullfile(subjDir,'tal'); % where tailrach info is located
noRerefDir = fullfile(subjDir,'eeg.noreref'); % where no-reref data is located
docsDir = fullfile(subjDir,'docs'); % subject's docs directory
masterJackFile = fullfile(docsDir,'jacksheetMaster.txt');
masterJack = textscan(fopen(masterJackFile),'%d%s%s');
chanExist = ~cellfun(@isempty,strfind(masterJack{1,3},'MISSING'));
elecLabels = [];
gl = [];
bl = [];
lBp = [];
glBp = [];
blBp = [];

if sum(chanExist) == 0
    disp('ALL CHANNELES ARE RECORDED IN ALL SESSIONS')
else

    % reads in jacksheet
    jackFile = fullfile(noRerefDir,[filestem '.jacksheet.txt']);
    jackSheet = textscan(fopen(jackFile),'%d%s');
    elecLabels = jackSheet{1};
    names = jackSheet{2};
    %idx = cellfun(@isempty,strfind(names,'<'))&cellfun(@isempty,strfind(names,'R'))&cellfun(@isempty,strfind(names,'EKG')); % gets those electrodes that are recorded for this particular raw file.
    idx = cellfun(@isempty,strfind(names,'<'))&cellfun(@isempty,strfind(names,'EKG')); % gets those electrodes that are recorded for this particular raw file.   2/2015 -- modify to allow for eCog channel names that start with 'R' 
    elecLabels = elecLabels(idx); % only use these electrodes for re-referencing


    % reads in good electrodes
    chanFile = fullfile(taldir,'good_leads.txt');
    if exist(chanFile,'file')
        gl=textscan(fopen(chanFile),'%d'); %only gets the good leads
        gl = [gl{1}];
        % outputs relevant leads bipolar
        idx2 = ismember(gl,elecLabels);
        gl = gl(idx2,:);
    else
        error('WARNING: good_leads.txt does not exist!');
    end

    % reads in bad electrodes
    chanFile = fullfile(taldir,'bad_leads.txt');
    if exist(chanFile,'file')
        bl=textscan(fopen(chanFile),'%d'); %only gets the good leads
        bl = [bl{1}];
        % outputs relevant leads bipolar
        idx2 = ismember(bl,elecLabels);
        bl = bl(idx2,:);
    else
        disp('WARNING: good_leads.txt does not exist!');
    end

    % reads in all bipolar pairs
    chanFile = fullfile(taldir,'leads_bp.txt');
    if exist(chanFile,'file')
        lBp=textscan(fopen(chanFile),'%d%*c%d'); %only gets the good leads
        lBp = [lBp{1} lBp{2}];

        % outputs relevant leads bipolar
        idx2 = ismember(lBp(:,1),elecLabels);
        idx3= ismember(lBp(:,2),elecLabels);
        idx4 = idx2&idx3;
        lBp = lBp(idx4,:);
    else
        error('WARNING: leads_bp.txt does not exist!');

    end

    % outputs relevant good_leads_bipolar
    chanFile = fullfile(taldir,'good_leads_bp.txt');
    if exist(chanFile,'file')
        glBp=textscan(fopen(chanFile),'%d%*c%d'); %only gets the good leads
        glBp = [glBp{1} glBp{2}];

        % outputs relevant leads bipolar
        idx2 = ismember(glBp(:,1),elecLabels);
        idx3= ismember(glBp(:,2),elecLabels);
        idx4 = idx2&idx3;
        glBp = glBp(idx4,:);
    else
        error('WARNING: good_leads_bp.txt does not exist!');
    end


    %outputs relevant bad_leads_bipolar
    chanFile = fullfile(taldir,'bad_leads_bp.txt');
    if exist(chanFile,'file')
        blBp=textscan(fopen(chanFile),'%d%*c%d'); %only gets the good leads
        blBp = [blBp{1} blBp{2}];

        % outputs relevant leads bipolar
        idx2 = ismember(blBp(:,1),elecLabels);
        idx3= ismember(blBp(:,2),elecLabels);
        idx4 = idx2&idx3;
        blBp = blBp(idx4,:);
    else
        disp('WARNING: bad_leads_bp.txt does not exist!');
    end
end