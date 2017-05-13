%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% m-file: generate_pbs.m
%
% Description: It uses a template of *.pbs (portable batch system) file and
%              customizes it to make a *.pbs file for every *.rec file of
%              iEEG data that must be processed by the cluster. Note that
%              it is assumed a two-level folder organization of the *.rec
%              files.
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
    
    % extract the list of the objects
    tmp = dir(sprintf('%s/%s',path0,patients{i})); tmp = tmp(3:end);
    
    % for each object...
    for j=1:length(tmp)        
        nameval = sprintf('%s/%s/%s',path0,patients{i},tmp(j).name);
        countfile1 = 0;
        
        % case 1: the object is a sub-directory: explore it
        if (isdir(nameval))
            
            % it is assumed no level-two sub-directory...
            tmp2 = dir(nameval); tmp2 = tmp2(3:end);
            countfile = 0;
            for k=1:length(tmp2)
                namesub = sprintf('%s/%s',nameval,tmp2(k).name);
                if (~isempty(strfind(namesub(end-3:end),'.rec')))

                    % update the counter of selected .rec files
                    countfile = countfile+1;
                    
                    % generate the .pbs file
                    %------------------------------------------------------
                    % header is set once every 10 .rec files
                    if (countfile==1)
                        if (~isdir(sprintf('%s/%s',patients{i},tmp(j).name))), mkdir(sprintf('%s/%s',patients{i},tmp(j).name)); end
                        fid = fopen(sprintf('%s/%s/%s_%s_%s.pbs',patients{i},tmp(j).name,patients{i},tmp(j).name,tmp2(k).name(1:end-4)),'w');
                        fprintf(fid,'#PBS -S /bin/bash\n');
                        fprintf(fid,'#PBS -V\n');
                        fprintf(fid,'#PBS -N %s_%s_%s\n',patients{i},tmp(j).name,tmp2(k).name(1:end-4));
                        fprintf(fid,'#PBS -m abe\n');
                        fprintf(fid,'#PBS -M ssantan5@jhu.edu\n');
                        fprintf(fid,'#PBS -l nodes=1:ppn=2\n');
                        fprintf(fid,'#PBS -l mem=1gb\n');
                        fprintf(fid,'#PBS -q dque\n');
                        fprintf(fid,'#PBS -l walltime=100:00:00\n');
                        fprintf(fid,'\ncd %s/software\n',path1);
                        fprintf(fid,'sleep 5\n');
                        fprintf(fid,'module load matlab/matlab2012a\n');
                        fprintf(fid,'sleep 5\n');
                    end
                    
                    % add the line for the current .rec file
                    fprintf(fid,'\n%s/software/run_shell_svdeeg.sh /apps/MATLAB/R2012a %s/%s/%s %s %d\n',path1,path1,patients{i},tmp(j).name,tmp2(k).name(1:end-4),0);
                    
                    % close the .pbs file and reset the counter
                    if (countfile==10 || k==length(tmp2))
                        fclose(fid);
                        countfile = 0;
                        clear fid
                    end
                    %------------------------------------------------------
                else
                    fprintf('file %s processed - no action taken\n',namesub);
                end
                clear namesub
            end
            clear tmp2
        else
            % case 2: the object is a *.rec file
            if (~isempty(strfind(nameval(end-3:end),'.rec')))

                % update the counter of selected .rec files
                countfile1 = countfile1+1;
                
                % generate the pbs file
                %----------------------------------------------------------
                % header is set once every 10 .rec files
                if (countfile1==1)
                    if (~isdir(patients{i})), mkdir(patients{i}); end
                    fid = fopen(sprintf('%s/%s_%s.pbs',patients{i},patients{i},tmp(j).name(1:end-4)),'w');
                    fprintf(fid,'#PBS -S /bin/bash\n');
                    fprintf(fid,'#PBS -V\n');
                    fprintf(fid,'#PBS -N %s_%s\n',patients{i},tmp(j).name(1:end-4));
                    fprintf(fid,'#PBS -m abe\n');
                    fprintf(fid,'#PBS -M ssantan5@jhu.edu\n');
                    fprintf(fid,'#PBS -l nodes=1:ppn=2\n');
                    fprintf(fid,'#PBS -l mem=1gb\n');
                    fprintf(fid,'#PBS -q dque\n');
                    fprintf(fid,'#PBS -l walltime=100:00:00\n');
                    fprintf(fid,'\ncd %s/software\n',path1);
                    fprintf(fid,'sleep 5\n');
                    fprintf(fid,'module load matlab/matlab2012a\n');
                    fprintf(fid,'sleep 5\n');
                end
                
                % add the line for the current .rec file
                fprintf(fid,'\n%s/software/run_shell_svdeeg.sh /apps/MATLAB/R2012a %s/%s %s %d\n',path1,path1,patients{i},tmp(j).name(1:end-4),0);
                
                % close the .pbs file and reset the counter
                if (countfile1==10 || j==length(tmp))
                    fclose(fid);
                    countfile1 = 0;
                    clear fid
                end
                %----------------------------------------------------------
            else
                % case 3: no valid object - do nothing
                fprintf('file %s processed - no action taken\n',nameval);
            end
        end
        clear nameval
    end
    clear tmp
end

fprintf('The End\n');
