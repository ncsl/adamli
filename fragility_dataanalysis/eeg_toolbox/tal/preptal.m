function preptal(dirname,fid,subject)
% FUNCTION preptal(dirname,fid,subject)
%
% preptal('.')
%

closeFile = 0;
if ~exist('fid','var')
  fid = fopen('allTalLocs.txt','w');
  closeFile = 1;
end

% some prefixes
prefixes = {'TJ','NI','DB','UP'};% changed by Srikanth Damera so that all prefixes are the same character length

% save starting dir
startdir = pwd;

% get the list of the directory
lst = dir(dirname);

% loop over each item in the list
for i = 1:length(lst)
  
  % see if it's a directory
  if lst(i).isdir & ~strcmp(lst(i).name,'.') & ~strcmp(lst(i).name,'..')
    % see if is new subject name
    tname = lst(i).name;
    if length(tname) > 2
      for p = 1:length(prefixes)
        if strcmp(prefixes{p},tname(1:2))
          subject = tname;
        end
      end
    end
    % recurse into that directory
    preptal(fullfile(dirname,lst(i).name),fid,subject)

  % see if it matches one of our tal files
  elseif strcmp(lst(i).name,'raw_coords.txt') | strcmp(lst(i).name,'RAW_coords.txt')
    % process it
    fprintf('Processing %s...',fullfile(dirname,lst(i).name));
    cd(dirname)
    
    % get the coords
    leads = get_tal_coords(lst(i).name); % changed by Sri Damera 9/25/13 to remove rounding of coordinates

    % take out spurious leads
    leads = leads(leads(:,1)<200,:);

    % get good leads if there
    if exist('good_leads.txt','file')
      gl = getleads('good_leads.txt');
      isgl = ismember(leads(:,1),gl);
    else
      % just set all to good
      isgl = ones(size(leads,1),1);
    end
    
    % get montage info for current directory
    mont = loadMontageInfo();
    
    % write to file
    %fid = fopen('tal_locs.txt','w');
    for l = 1:size(leads,1)
      % see what montage it is in
      tmontage = '';
      for f = 1:length(mont)
        if ismember(leads(l,1),mont(f).channels)
          % found the montage
          tmontage = mont(f).name;
          break;
        end
      end
      fprintf(fid,'%s\t%d\t%d\t%d\t%d\t%d\t%s\n',subject,leads(l,:),isgl(l),tmontage);
    end
    %fclose(fid);
    
    cd(startdir)
    fprintf('Done\n')
  end
end


if closeFile
  fclose(fid);
end


function mont = loadMontageInfo()
%
%

% get the montage files from current dir
files = dir('*.montage');
mont = [];
for f = 1:length(files)
  % strip off the name
  [d,mont(f).name] = fileparts(files(f).name);
  
  % Load in the channels
  mont(f).channels = getleads(files(f).name);
end
