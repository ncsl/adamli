function addresses = nknih_anon(nk_dir);
% This function anonymizes a Nihon Kohden file.  It does three things removes the patient's name from the EEG file


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% .EEG: print and write over name
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
d=dir([nk_dir '/*.EEG']);  EEG_file=fullfile(nk_dir,d.name);
assert(length(d)==1,'Expected 1 .EEG file, found %d',length(d));
fid     = fopen(EEG_file,'r+');

%-read patient ID and overwrite with XXX's
fseek(fid,48,'bof'); 
patID  = fread(fid,16,'*char')';
%XXid  = repmat('X',1,16); 
XXid   = [' ' repmat('X',1,14) ' ']; %add space at begining and end of string
fseek(fid,48,'bof');
fwrite(fid,XXid,'char'); %overwrite the patient ID in the device block

%-read patient name and overwrite with XXX's
fseek(fid,79,'bof'); 
patName = fread(fid,32,'*char')';
%XXname = repmat('X',1,32); 
XXname  = [' ' repmat('X',1,30) ' ']; %add space at begining and end of string
fseek(fid,79,'bof');
fwrite(fid,XXname,'char'); %overwrite the name in the device block
fclose(fid);

if ~strcmp(patID,XXid) | ~strcmp(patName,XXname),
    fprintf('  anonymizing raw .EEG file: removed NAME=%s and ID=%s.\n',patName,patID);
else
    fprintf('  anonymizing raw .EEG file: file already clean.\n');
end
    

%%%%%%%%%%%%%%%%%%
%Completion status
%%%%%%%%%%%%%%%%%%
OUTPUT_STATUS = 0;
if OUTPUT_STATUS,
    d=dir([nk_dir '/*.21E']);  REF_file=fullfile(nk_dir,d.name);
    fprintf('\nDone anonymizing. Run again to make sure names are gone.\n')
    fprintf('OK to copy %s and %s to server.\n\n',EEG_file,REF_file);
end