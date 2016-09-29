function masterElectrodeVisualize(task,varargin)
%Function masterElectrodeVisualize(task,varargin)
%   Master function for all scripts necessary for electrode localization 
%   and ROI creation on the cortical surface.
%
%   --Create Dural Surface--
%     Description: Creates a smooth surface along the surface of the brain
%     to project electrodes too. It also serves as the precursor to the
%     ROIs
%     Inputs: 
%             --task = 'dural'
%             --toolboxDir = '/Users/damerasr/Sri/hnl/matlab/eeg_toolbox/'
%             --surface = 'Colin_27'
%             --interval = '.5' (points will be spaced at a given interval)
%     Outputs: 
%             --Figure with dural surface plotted over given cortical
%                surface
%             --Figure with all vertices within a radius (specified by   
%                interval) of a dural surface point shaded (entire brain
%                should be covered).
%             --Outputted .mat file containing the relevant points making
%               up the dural surface
% 
%   --Create ROIs--
%     Description: Creates equally spaced ROIs across the given brain
%                  surface by filtering the dural Surface. The user may 
%                  specify what the distance between ROIs are.  
%     Inputs:
%             --task = 'roi'
%             --toolboxDir = '/Users/damerasr/Sri/hnl/matlab/eeg_toolbox/'
%             --surface = 'Colin_27_dura.mat'
%             --interval = '10'
%     Outputs: 
%             --Figure with ROIs plotted over given cortical surface  
%             --Figure with all vertices within a radius (specified by   
%                interval) of a dural surface point shaded (entire brain
%                should be covered).
%
%   --Project Raw Electrodes--
%     Description: Reads in original electrode coordinates that result from
%                  warping patient's electrodes to standard brain. This
%                  function takes those electrodes and projects them so
%                  that cortical electrodes lie on the 'dural' surface. It
%                  also runs electrodes through tailraich daemon and creates
%                  an events structure in talSurf, which is under the 
%                  master tailraich folder (~/data/eeg/tal).
%
%     Inputs:
%             --task = 'raw_project'
%             --homeDir = '/Users/damerasr/Sri'
%             --subject = 'NIH005'
%             --innerHemiFlag = 1 or 0 depending on whether subject has
%             inner hemispheric electrodes
%     Outputs:
%             --new electrode coordinates
%             --saves RAW_coords_surf.txt in patient's tal directory
%             --saves events containing electrode information in talSurf
%               directory within the master tal directory.
%
%   --Project Bipolar Electrodes--
%     Description: Reads in projected electrode coordinates and calculates
%                  virtual bipolar coordinates. This function takes those 
%                  electrodes and projects them so that cortical electrodes 
%                  lie on the 'dural' surface. It also runs electrodes 
%                  through tailraich daemon and creates an events structure  
%                  in talBipolar, which is under the master tailraich  
%                  folder (~/data/eeg/tal).
%
%     Inputs:
%             --task = 'bipolar_project'
%             --homeDir = '/Users/damerasr/Sri'
%             --subject = 'NIH005'
%             --innerHemiFlag = 1 or 0 depending on whether subject has
%             inner hemispheric electrodes
%     Outputs:
%             --new electrode coordinates
%             --saves Bipolar_coords_surf.txt in patient's tal directory
%             --saves events containing electrode information in talBipolar
%               directory within the master tal directory.

switch task
    
    case 'dural'
        toolboxDir = varargin{1};
        surface = varargin{2};
        interval = varargin{3};
        gridMake(toolboxDir,surface, interval);
    case 'roi'
        toolboxDir = varargin{1};
        surface = varargin{2};
        interval = varargin{3};
        roiMake(toolboxDir,surface, interval);
    case 'raw_project'
        homeDir = varargin{1};
        subj = varargin{2};
        innerHemiFlag = varargin{3};
        elecs2 = monopolarElecOptimize(homeDir,subj,innerHemiFlag);
    case 'bipolar_project'
        homeDir = varargin{1};
        subj = varargin{2};
        innerHemiFlag = varargin{3};
        elecs2 = bipolarElecOptimize(homeDir,subj,innerHemiFlag);
    case 'visualize'
        
end