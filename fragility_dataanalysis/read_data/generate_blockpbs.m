%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% m-file: generate_blockpbs.m
%
% Description: It uses a template of *.pbs (portable batch system) file and
%              customizes it to make a *.pbs file for subject in the data
%              set. Each *.pbs file includes commands for every *.rec file
%              of the subject. Note that it is assumed a two-level folder
%              organization of the *.rec files.
%
%
%
% Author: S. Santaniello
%
% Ver.: 1.0 - Date: 11/21/2011
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
clc

% root directory of the source files on the local machine
path0 = '/home/WIN/ali39/Documents/adamli/fragility_dataanalysis/data/';

% root directory of the source files on the cluster
path1 = pwd;

% extract the list of subjects
tmp = dir(path0); tmp = tmp(3:end);
patients = {};
for i=1:length(tmp)
    if (~isempty(strfind(tmp(i).name,'PY')))
        patients = [patients, tmp(i).name];
    end
end
clear tmp

% for each subject...
for i=1:length(patients)
    
    % set the header of the pbs file
    fid = fopen(sprintf('%s.pbs',patients{i}),'w');
    fprintf(fid,'#PBS -S /bin/bash\n');
    fprintf(fid,'#PBS -V\n');
    fprintf(fid,'#PBS -N %s\n',patients{i});
    fprintf(fid,'#PBS -m abe\n');
    fprintf(fid,'#PBS -M ssantan5@jhu.edu\n');
    fprintf(fid,'#PBS -l nodes=1:ppn=2\n');
    fprintf(fid,'#PBS -l mem=1gb\n');
    fprintf(fid,'#PBS -q dque\n');
    fprintf(fid,'#PBS -l walltime=200:00:00\n');
    fprintf(fid,'\ncd %s/software\n',path1);
    fprintf(fid,'sleep 5\n');
    fprintf(fid,'module load matlab/matlab2012a\n');
    fprintf(fid,'sleep 5\n');

    % extract the list of the objects
    tmp = dir(sprintf('%s/%s',path0,patients{i})); tmp = tmp(3:end);
    
    % for each object...
    for j=1:length(tmp)        
        nameval = sprintf('%s/%s/%s',path0,patients{i},tmp(j).name);
        
        % case 1: the object is a sub-directory: explore it
        if (isdir(nameval))
            
            % it is assumed no level-two sub-directory...
            tmp2 = dir(nameval); tmp2 = tmp2(3:end);
            for k=1:length(tmp2)
                namesub = sprintf('%s/%s',nameval,tmp2(k).name);
                if (~isempty(strfind(namesub(end-3:end),'.rec')))

                    % add a line for the current *.rec file in the *.pbs
                    % file
                    fprintf(fid,'\n%s/software/run_shellns_svdeeg.sh /apps/MATLAB/R2012a %s/%s/%s %s\n',path1,path1,patients{i},tmp(j).name,tmp2(k).name(1:end-4));
                else
                    fprintf('file %s processed - no action taken\n',namesub);
                end
                clear namesub
            end
            clear tmp2
        else
            % case 2: the object is a *.rec file
            if (~isempty(strfind(nameval(end-3:end),'.rec')))

                % add the line for the current *.rec file in the *.pbs file
                fprintf(fid,'\n%s/software/run_shellns_svdeeg.sh /apps/MATLAB/R2012a %s/%s %s\n',path1,path1,patients{i},tmp(j).name(1:end-4));
            else
                % case 3: no valid object - do nothing
                fprintf('file %s processed - no action taken\n',nameval);
            end
        end
        clear nameval
    end
    
    % close the *.pbs file
    fclose(fid);
    clear fid tmp
end

fprintf('The End\n');
