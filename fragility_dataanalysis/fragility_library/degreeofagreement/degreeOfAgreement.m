function [ D ] = degreeOfAgreement(EEZ, CEZ, ALL, metric, args)
% #########################################################################
% Function Summary: Computes statistic (DOA = Degree of Agreement) indicat-
% ing how well EEZ (from EpiMap) and CEZ (clinical ezone) agree. 
% 
% Inputs:
%   EEZ: cell with EpiMap's predicted ezone labels
%   CEZ: cell with clinically predicted ezone labels 
%   ALL: cell with all electrode labels
%   metric: (optional) string argument of
%       - Jaccard index
%       - Sorensen's coefficient
%       - DOA (default) from R01 grant
%   
% Output: 
%   DOA: (#CEZ intersect EEZ / #CEZ) / (#NOTCEZ intersect EEZ / #NOTCEZ)
%   Value between -1 and 1, Computes how well CEZ and EEZ match. 
%   < 0 indicates poor match.
% 
% Author: Kriti Jindal, NCSL 
% - Edited by: Adam Li
% Last Updated: 02.22.17
%   
% #########################################################################
    %% Argument Management
    if nargin==0
        EEZ = {'TG3', 'TG4', 'TG5', 'IH6', 'MFP3', 'MFP4', 'MFP5', 'MFP6'}
        CEZ = {'TG4', 'TG6', 'IH6', 'FG31'}
        ALL = {'TG3', 'TG4', 'TG5', 'TG6', 'TG7', 'TG8', 'TG11', 'TG13', 'TG15', 'TG16', 'TG20', 'TG22', 'TG24', 'TG26', 'TG27', 'TG28', 'TG29', 'TG30', 'TG31', 'TG32', 'TT1', 'TG18', 'TG19', 'TT2', 'TT3', 'TT4', 'TT5', 'TT6', 'AST1', 'AST2', 'AST3', 'AST4', 'MST1', 'MST2', 'MST3', 'MST4', 'PST1', 'PST2', 'PST3', 'PST4', 'OF1', 'OF2', 'OF3', 'OF4', 'IFP1', 'IFP2', 'IFP3', 'IFP4', 'MFP1', 'MFP2', 'MFP3', 'MFP4', 'MFP5', 'MFP6', 'SFP1', 'SFP2', 'SFP3', 'SFP4', 'SFP5', 'SFP6', 'SFP7', 'SFP8', 'RD1', 'FG1', 'FG2', 'FG3', 'FG4', 'FG5', 'FG6', 'FG7', 'FG8', 'FG9', 'FG10', 'FG12', 'FG14', 'FG16', 'FG17', 'FG19', 'FG21', 'FG23', 'FG24', 'FG25', 'FG26', 'FG27', 'FG28', 'FG29', 'FG30', 'FG31', 'FG32', 'ILF1', 'ILF3', 'ILF5', 'ILF7', 'IH1', 'IH2', 'IH3', 'IH4', 'IH5', 'IH6'};
    end
    
    % arg 4 is optional
    if nargin < 4
        metric = 'default';
        metric = 'jaccard';
    elseif nargin == 4
        if ~(strcmp(lower(metric), 'default') || strcmp(metric, 'jaccard') || ...
                strcmp(metric, 'sorensen') || strcmp(metric, 'tversky'))
            errormsg = 'Metric is incorrect.\n Enter "default", or "jaccard".';
            error('DOA:incorrectInput', errormsg);
        end
    end
    
    % if tversky index, make sure alpha and beta are defined
    if strcmp(metric, 'tversky') 
        if isfield(args, 'alpha') && isfield(args, 'beta')
            alpha = args.alpha;
            beta = args.beta;
        else
            errormsg = 'Must define alpha and beta constants >= 0 for Tversky Index.';
            error('DOA:provideParameters', errormsg);
        end
    end

    %% Compute Degree of Agreement
    % finds appropriate set intersections to plug into DOA formula 
    if strcmp(lower(metric), 'default')
        NotCEZ = setdiff(ALL, CEZ);
        CEZ_EEZ = intersect(CEZ, EEZ);
        NotCEZ_EEZ = intersect(NotCEZ, EEZ);

        term1 = length(CEZ_EEZ) / length(CEZ);
        term2 = length(NotCEZ_EEZ) / length(NotCEZ);

        D = term1 - term2;
    elseif strcmp(metric, 'jaccard')
        CEZ_EEZ = intersect(CEZ, EEZ); % set in intersection
        CEZandEEZ = union(CEZ, EEZ);   % set in union

        % find Jaccard index
        D = length(CEZ_EEZ) / length(CEZandEEZ);
    elseif strcmp(metric, 'sorensen')
        CEZ_EEZ = intersect(CEZ, EEZ);
        
        % find Sorensen coefficient
        D = 2*length(CEZ_EEZ) / (length(CEZ) + length(EEZ));
    elseif strcmp(metric, 'tversky')
        CEZ_EEZ = intersect(CEZ, EEZ);
        CEZEEZ_C = setdiff(CEZ, EEZ);
        EEZCEZ_C = setdiff(EEZ, CEZ);
        
        a = min(length(CEZEEZ_C), length(EEZCEZ_C));
        b = max(length(CEZEEZ_C), length(EEZCEZ_C));
        
        % compute tversky index
%         D = length(CEZ_EEZ) / (length(CEZ_EEZ) + alpha*length(CEZEEZ_C) + beta*length(EEZCEZ_C));
        D = length(CEZ_EEZ) / (length(CEZ_EEZ) + beta*(alpha*a + (1-alpha)*b));
    end
end