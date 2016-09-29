function f = fullfileEEG(varargin)
%FULLFILE Build full file name from parts.
%   F = fullfileEEG(FOLDERNAME1, FOLDERNAME2, ..., FILENAME) builds a full
%   file specification F from the folders and file name specified. Input
%   arguments FOLDERNAME1, FOLDERNAME2, etc. and FILENAME can be strings,
%   a scalar cell string, or same-sized cell arrays of strings. The output
%   of fullfile is conceptually equivalent to
%
%   fullfileEEG differs from matlab's built-in fullfile in that forward slash is ALWAYS used
%       as file seperator... important for aligning on MACs and PCS (JHW 12/2013)
%
%      F = [FOLDERNAME1 filesep FOLDERNAME2 filesep ... filesep FILENAME]
%
%   except that care is taken to handle the cases when the folders begin or
%   end with a file separator.
%
%   Examples
%     % To build platform dependent paths to files:
%        fullfile(matlabroot,'toolbox','matlab','general','Contents.m')
%
%     % To build platform dependent paths to a folder:
%        fullfile(matlabroot,'toolbox','matlab',filesep)
%
%     % To build a collection of platform dependent paths to files:
%        fullfile(toolboxdir('matlab'),'iofun',{'filesep.m';'fullfile.m'})
%
%   See also FILESEP, PATHSEP, FILEPARTS.

%   Copyright 1984-2012 The MathWorks, Inc.
%   $Revision: 1.19.4.9 $ $Date: 2012/09/05 07:24:47 $
    
    narginchk(1, Inf);
    %fileSeparator = filesep;
    fileSeparator = '/';  % this is the one line changed in fullfileEEG... important so eegPrepAndAlign has same outputs on MAC or PC
    
    argIsACell = cellfun('isclass', varargin, 'cell');
    theInputs = varargin;
    f = theInputs{1};
    try
        if nargin == 1
            f = refinePath(f);
            return;
        elseif any(argIsACell)
            theInputs(cellfun(@(x)~iscell(x)&&isempty(x), theInputs)) = [];
        else
            theInputs(cellfun('isempty', theInputs)) = '';
        end
        
        if length(theInputs)>1
            theInputs{1} = ensureTrailingFilesep(theInputs{1});
        end
        if ~isempty(theInputs)
            theInputs(2,:) = {fileSeparator};
            theInputs{2,1} = '';
            theInputs(end) = '';
            if any(argIsACell)
                f = strcat(theInputs{:});
            else
                f = [theInputs{:}];
            end
        end
        f = refinePath(f);
    catch exc
        locHandleError(exc, theInputs(1,:));
    end   
end


function f = ensureTrailingFilesep(f)
    if iscell(f)
        for i=1:numel(f)
            f{i} = addTrailingFileSep(f{i});
        end
    else
        f = addTrailingFileSep(f);
    end
end

function str = addTrailingFileSep(str)
    %fileSeparator = filesep;
    %bIsPC = ispc;
    fileSeparator = '/';
    bIsPC = 0;
    if ~isempty(str) && (str(end) ~= fileSeparator && ~(bIsPC && str(end) == '/'))
        str = [str, fileSeparator];
    end
end
function f = refinePath(f)
    %fs = filesep;
    fs = '/';
    f = strrep(f, '/', fs);
    singleDotPattern = [fs, '.', fs]; 
    f = strrep(f, singleDotPattern, fs);
    multipleFileSepPattern = [fs, fs];
    if ~isempty(strfind(f, multipleFileSepPattern))
        f = replaceMultipleFileSeps(f);
    end
    doubleDotPattern = [fs, '..', fs];
    if ~isempty(strfind(f, doubleDotPattern))
        f = replaceDoubleDots(f);
    end
end

function f = replaceMultipleFileSeps(f)
    %fsEscape = ['\', filesep];
    %multipleFileSepRegexpPattern = ['(?<!^(\w+:)?' fsEscape '*)', fsEscape, fsEscape '+'];
    %f = regexprep(f, multipleFileSepRegexpPattern, filesep);
    fsEscape = ['\', '/'];
    multipleFileSepRegexpPattern = ['(?<!^(\w+:)?' fsEscape '*)', fsEscape, fsEscape '+'];
    f = regexprep(f, multipleFileSepRegexpPattern, '/');
end

function f = replaceDoubleDots(f)
    %fsEscape = ['\', filesep];
    fsEscape = ['\', '/'];
    currentFormat = '';
    doubleDotRegexpPattern = ['(', fsEscape,'|^)(?!(\.\.?|^\w+:)', fsEscape,')[^', fsEscape,']+', fsEscape,'\.\.(\1)?(?(2)|', fsEscape,'|$)'];
    while ~strcmp(currentFormat, f)
        currentFormat = f;
        f = regexprep(f,doubleDotRegexpPattern,'$2');
    end
end

function locHandleError(theException, theInputs)
    msgToThrow = message('MATLAB:fullfile:UnknownError');
    switch theException.identifier
    case {'MATLAB:catenate:dimensionMismatch', ...
            'MATLAB:strcat:InvalidInputSize', 'MATLAB:strrep:MultiRowInput', 'MATLAB:strcat:NumberOfInputRows', 'MATLAB:UnableToConvert'}
        % Verify that all char inputs have only one row and that the sizes
        % of all nonscalar cell inputs match.
        firstNonscalarCellArg = struct('idx', 0, 'size', 0);
        for argIdx = 1:numel(theInputs)
            currentArg = theInputs{argIdx};
            if isscalar(currentArg)
                continue;
            elseif ischar(currentArg) && ~isrow(currentArg)
                msgToThrow = message('MATLAB:fullfile:NumCharRowsExceeded');
            elseif iscell(currentArg)
                currentArgSize = size(currentArg);
                if firstNonscalarCellArg.idx == 0
                    firstNonscalarCellArg.idx = argIdx;
                    firstNonscalarCellArg.size = currentArgSize;
                elseif ~isequal(currentArgSize, firstNonscalarCellArg.size)
                    msgToThrow = message('MATLAB:fullfile:CellstrSizeMismatch');
                end
            end
        end
    otherwise
        % Verify that correct input types were specified.
        argIsInvalidType = ~cellfun(@(arg)isnumeric(arg)&&isreal(arg)||ischar(arg)||iscellstr(arg), theInputs);
        if any(argIsInvalidType)
            msgToThrow = message('MATLAB:fullfile:InvalidInputType');
        end
    end
    excToThrow = MException(msgToThrow.Identifier, msgToThrow.getString);
    excToThrow.addCause(theException);
    throwAsCaller(excToThrow);
    
end



