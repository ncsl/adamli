function varargout = EDFCreator(varargin)
% EDFCREATOR MATLAB code for EDFCreator.fig
%      EDFCREATOR, by itself, creates a new EDFCREATOR or raises the existing
%      singleton*.
%
%      H = EDFCREATOR returns the handle to a new EDFCREATOR or the handle to
%      the existing singleton*.
%
%      EDFCREATOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EDFCREATOR.M with the given input arguments.
%
%      EDFCREATOR('Property','Value',...) creates a new EDFCREATOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before EDFCreator_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to EDFCreator_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help EDFCreator

% Last Modified by GUIDE v2.5 25-Apr-2013 20:14:17

% Begin initialization code - DO NOT EDIT
warning off MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame;
warning off;

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @EDFCreator_OpeningFcn, ...
                   'gui_OutputFcn',  @EDFCreator_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before EDFCreator is made visible.
function EDFCreator_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to EDFCreator (see VARARGIN)

% Choose default command line output for EDFCreator
handles.output = hObject;
movegui(gcf,'center'); 
% Set default parameters
set(gcf,'Name','EDF Creator [ver 0.0.2]');
set(handles.gFilename,'String', ' Type full path or browse signal file');
set(handles.tSampleRate,'String', 'Sampling Rate (Hz)');
% set(handles.MarkEventCheckBox,'Value', 0);

FileType = { '*.MAT';};
handles.FileType = FileType;
handles.fileName = '';
handles.Fs = '';
handles.NumChan = '';

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes EDFCreator wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = EDFCreator_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function gFilename_Callback(hObject, eventdata, handles)
% hObject    handle to gFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of gFilename as text
%        str2double(get(hObject,'String')) returns contents of gFilename as a double
fileName = get(handles.gFilename, 'String');
if isempty(fileName)
    set(handles.tSampleRate, 'Enable', 'off');
    set(handles.pbCreate, 'Enable', 'off');
     handles.fileName = '';
else
    handles.fileName = fileName;
    set(handles.tSampleRate, 'Enable', 'on');
    set(handles.pbCreate, 'Enable', 'off');
end
guidata(hObject, handles);
% --- Executes during object creation, after setting all properties.
function gFilename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pbBrowse.
function pbBrowse_Callback(hObject, eventdata, handles)
% hObject    handle to pbBrowse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
FileType = handles.FileType;
[fileName, pathName] = uigetfile(FileType, 'Browse MAT Signal File');
if fileName ~= 0
    fileName = [pathName,  fileName];
    handles.fileName = fileName;
    set(handles.tSampleRate, 'Enable', 'on');
    set(handles.pbCreate, 'Enable', 'off');
else
    set(handles.tSampleRate, 'Enable', 'off');
    set(handles.pbCreate, 'Enable', 'off');
    
end
set(handles.gFilename, 'String', handles.fileName);
guidata(hObject, handles);

function tSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to tSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tSampleRate as text
%        str2double(get(hObject,'String')) returns contents of tSampleRate as a double
Fs = str2num(get(handles.tSampleRate, 'String'));
if Fs > 0
    handles.Fs = Fs;
    set(handles.pbCreate, 'Enable', 'on');
    set(handles.tSampleRate, 'String', num2str(Fs));
else
    handles.Fs = 0;
    set(handles.pbCreate, 'Enable', 'on');
    set(handles.tSampleRate, 'String', num2str(Fs));
end
guidata(hObject, handles);
% --- Executes during object creation, after setting all properties.
function tSampleRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pbCreate.
function pbCreate_Callback(hObject, eventdata, handles)
% hObject    handle to pbCreate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% try
 [P, F, E] = fileparts(handles.fileName);
 sFilename = [P,'\', F,'.edf']

 
 % loading in the data
 load(handles.fileName);
 [m, n] = size(EEG);
 if m < n
     EEG = EEG';
     [m, n] = size(EEG);
 end
 warning off;
HDR.TYPE = 'EDF'; 
% HDR.FileName = sFilename;
HDR.Patient.Sex = 'M'; 
HDR.Patient.Age = '0'; 
HDR.T0 = clock; 
HDR.Patient.Birthday = HDR.T0;
HDR.Patient.Birthday(1) = HDR.T0(1) - HDR.Patient.Age;
HDR.FILE.OPEN = 1;
HDR.FILE.POS  = 0;
HDR.NRec = 1;   
HDR.NS = n; % Number of channels
HDR.DigMax  = (2^15-1)*ones(HDR.NS,1); 
HDR.DigMin  = (-2^15)*ones(HDR.NS,1); 
HDR.PhysMax = HDR.DigMax; 
HDR.PhysMin = HDR.DigMin; 
HDR.GDFTYP  = repmat(3,HDR.NS);
HDR.FLAG.UCAL = 1; 
HDR.SampleRate = handles.Fs; 
HDR.Dur = 1/(HDR.SampleRate);
for k = 1:n
    ChLabel(k)=  {strcat('CH', num2str(k))};
end
% ChLabel = ChLabel';

% Adam added 02/8/17
ChLabel = labels;
HDR.FileName = strcat(patient, '.edf');

HDR.Label = ChLabel;%<--------- DEFINE
HDR.Filter.Notch    = NaN; 
HDR.Filter.LowPass  = NaN; 
HDR.Filter.HighPass = NaN; 
HDR.CHANTYP ='SEEG';
HDR.intern.CHANTYP ='SEEG'; 
HDR.NRec = m; 
HDR.SPR = 1; 


HDR = sopen(HDR,'w'); 
HDR = swrite(HDR,EEG); 
HDR = sclose(HDR); 
pause(2)
set(handles.pbCreate, 'Enable', 'off');
% % catch
% %     errordlg('Error creating EDF file','Error');
% %     close all;
% % end
set(handles.gFilename,'String', ' Type full path or browse signal file');
set(handles.tSampleRate,'String', 'Enter Sampling Rate (Hz)');
guidata(hObject, handles);
