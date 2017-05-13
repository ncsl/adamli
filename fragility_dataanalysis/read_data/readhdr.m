%%% READHDR : Read header file
%%% Description: Read in data header files from clinicians of EEG
%%% recordings
%%% Ex: readhdr from PY patients from JHU Hospital
%%%
%%% (c) Christophe Jouny. 2001-2011. 

function hdr=readhdr(file)

fid=fopen(file, 'r');
flaglabels=0; flagunits=0; flagcalib=0;

while 1,
   tline = fgetl(fid);
   if ~ischar(tline) || isempty(tline), break, end
   
   %Fix for ill-formatted first line (CR) missing
   idxP=findstr(tline, '%PATIENT_INFO');
   if ~isempty(idxP),
       tline=tline(idxP:end);
   end
    
    if tline(1)=='#',
	    continue;
    end
    
    if tline(1)=='%',
        section=lower(tline(2:end));
        switch tline(2:end),
        case {'CHANNELS'},
            flaglabels=1;
            flagunits=0;
            continue
        case {'CALIBRATION'},
            flagcalib=1;
            continue
        otherwise,
            continue;
        end
    end
    
    [indic, rmd]=strtok(tline, '=');
    if length(rmd)>1,
       value=rmd(2:end);
        if (abs(value(1))>=48 && abs(value(1))<=57) || abs(value(1))==45,
            cmd='str2num(value)';
        else
            cmd='value';
        end
    else
        continue;
    end
    eval(['hdr.' section '.' indic '=' cmd ';']);
    
    if flaglabels,
        nb=str2num(value);
        for ii=1:nb, tline = fgetl(fid); hdr.channels.labels{ii}=tline; end
        flaglabels=0; flagunits=1; continue;
    end
    if flagunits,
        nb=str2num(value);
        for ii=1:nb, tline = fgetl(fid); hdr.channels.units{ii}=tline; end
        flaglabels=0; flagunits=0;
    end
    if flagcalib,
        nb=str2num(value);
        for ii=1:nb, tline = fgetl(fid); hdr.calibration.calib(ii)=str2num(tline); end
        flagcalib=0;
    end
end
fclose(fid);

