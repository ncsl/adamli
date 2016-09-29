function hippleads=gethippleads(subj,printWarning)
% DESCRIPTION:
%  This function reads the tal/hipp_only.txt file and returns the
%  elecs therein as a vector.  If the file doesn't exist it returns
%  an empty vector.
%
% FUNCTION
%    hippleads=gethippleads(subj,printWarning)
%
% INPUT:
%   subj = the subject you want
%   printWarnig = prints a warning if it can't find ther file
%
% OUTPUT:
%  hippleads = the elecs in tal/hipp_only.txt   
%
% NOTE:  
%  it will look for the file hipp_only.txt under
%  /data/eeg/subj/tal/hipp_only.txt.  If there are two montages,
%  enter CH008/CH008b (for example) for the subj inpt.
%
%

if ~exist('printWarning','var')||isempty(printWarning)
  printWarning = true;
end
  
dataroot = '/data/eeg/';
subjDir   = fullfile(dataroot,subj);
hippFile  = fullfile(subjDir,'tal/hipp_only.txt');

if exist(hippFile,'file')
  hippleads=load(hippFile)';
else
  if printWarning
    fprintf('WARNING: %s file not found\n\n',hippFile)
  end
  hippleads = [];
end