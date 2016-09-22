% function parsave
% Description: To be used to save data in a parfor loop
% Reference: https://www.mathworks.com/matlabcentral/answers/135285-how-do-i-use-save-with-a-parfor-loop-using-parallel-computing-toolbox 
% 
% Input:
% - filepath = the filename to use to save the data into
% - args = all other variables to be saved and put it into a struct
%
% Output:
% - Doesn't return anything, but saves all the data passed in as one
function parsave(varargin)
    savefile = varargin{1}; % first input argument filename
    for i=2:nargin
        savevar.(inputname(i)) = varargin{i}; % other input arguments
    end
    save(savefile,'-struct','savevar')
end