function varargout = tfAnalyses(varargin)
% GUI MATLAB code for tfAnalyses.fig
%      GUI, by itself, creates a new GUI or raises the existing
%      singleton*.
%
%      H = GUI returns the handle to a new GUI or the handle to
%      the existing singleton*.
%
%      GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI.M with the given input arguments.
%
%      GUI('Property','Value',...) creates a new GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help gui

% Last Modified by GUIDE v2.5 24-Jan-2019 13:29:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gui_OpeningFcn, ...
                   'gui_OutputFcn',  @gui_OutputFcn, ...
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


% --- Executes just before gui is made visible.
function gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to gui (see VARARGIN)

% Choose default command line output for gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in importEEG.
function importEEG_Callback(hObject, eventdata, handles)
[file,path] = uigetfile('*.set',...
   'Select One EEG .set file', ...
   'MultiSelect', 'off');
data = guidata(gcbo);
data.powerName = file;
data.EEG = pop_loadset([path,file]);
guidata(gcbo,data);

% hObject    handle to importEEG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in powerExt.
function powerExt_Callback(hObject, eventdata, handles)
% hObject    handle to powerExt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = guidata(gcbo);
data.Fstart = str2double(get(handles.startFreq,'String'));
data.Fend = str2double(get(handles.endFreq,'String'));
Fnumber = str2double(get(handles.numFreq,'String'));
F = logspace(log10(data.Fstart),log10(data.Fend),Fnumber); 
data.F = F;
data.Fsample = data.EEG.srate;
Fsample = data.Fsample;
data.wavenumber = str2double(get(handles.waveNum,'String'));
wavenumber = data.wavenumber; 
powerMx = zeros([length(F),size(data.EEG.data)]);

data.PhaseExtract = get(handles.extPhase,'Value');
if data.PhaseExtract
phaseMx = zeros([length(F),size(data.EEG.data)]);
end
for iElectrode = 1:63 
    fprintf('Power estimate [%s] [electrode %d] ...\n',data.EEG.filename, iElectrode)
    for iTrial = 1:size(data.EEG.data,3)
        eegsignal = data.EEG.data(iElectrode,:,iTrial);
        [B,P,~,~]=BOSC_tf(eegsignal,F,Fsample,wavenumber);
        powerMx(:,iElectrode,:,iTrial) = B;
        if data.PhaseExtract
        phaseMx(:,iElectrode,:,iTrial) = P;
        end
    end
end
powerMx = squeeze(mean(powerMx,4));
fprintf('power estimate completed. \n')
if data.PhaseExtract
phaseMx = squeeze(mean(phaseMx),4);
fprintf('phase estimate completed. \n')
end
% baseline correction using -500 ~ -200 ms
% cohen book 18.3 Decibel conversion
data.removeBaseline = get(handles.baseline,'Value');
if data.removeBaseline 
    data.eventOnsetValue = str2double(get(handles.eventOnset,'String'));
    eventOnset = data.eventOnsetValue;
    baseline_begin = -0.5;
    baseline_end = -0.2;
    baseline_f= mean(powerMx(:,:,Fsample*(eventOnset+baseline_begin):Fsample*(eventOnset+baseline_end)),3);
    % dB_tf = 10*log10 (activity_tf/ baseline_f)
    dbconverted = zeros(size(powerMx));
    for iElectrode = 1:size(data.EEG.data,1)
        dbconverted(:,iElectrode,:) = 10*log10( bsxfun(@rdivide,squeeze(powerMx(:,iElectrode,:)),baseline_f(:,iElectrode)));
    end
end
data.power = dbconverted;
if data.PhaseExtract
data.phase = phaseMx;
end
fprintf('baseline (-500 ~ -200ms) removal completed. \n')
guidata(gcbo,data);


function waveNum_Callback(hObject, eventdata, handles)
% hObject    handle to waveNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of waveNum as text
%        str2double(get(hObject,'String')) returns contents of waveNum as a double


% --- Executes during object creation, after setting all properties.
function waveNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to waveNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in plot.
function plot_Callback(hObject, eventdata, handles)
% hObject    handle to plot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = guidata(gcbo);
% electrode regions
test = {data.EEG.chanlocs.labels};
indx_frontal  =[];
indx_central =[];
indx_temporal  =[];
indx_occipital =[];
for i = 1:size(data.EEG.data,1)
    switch test{i}(1)
        case  'A'
            indx_frontal = [indx_frontal i];
        case  'F'
            indx_frontal = [indx_frontal i];
        case  'C'
            indx_central = [indx_central i];
        case 'T'
            indx_temporal = [indx_temporal i];
        case 'P'
            indx_occipital = [indx_occipital i];
        case 'O'
            indx_occipital = [indx_occipital i];
    end
end
data.plotRegion = get(handles.plotElectrodePopup,'Value');
switch data.plotRegion
    case 1
        tfMatrix = squeeze(mean(data.power(:,indx_frontal,:),2));
        titleS = 'Frontal cluster power heatmap';
    case 2
        tfMatrix = squeeze(mean(data.power(:,indx_central,:),2));
                titleS = 'Central cluster power heatmap';
    case 3
        tfMatrix = squeeze(mean(data.power(:,indx_temporal,:),2));
                titleS = 'Temporal cluster power heatmap';
    case 4
        tfMatrix = squeeze(mean(data.power(:,indx_occipital,:),2));
                titleS = 'Occipital cluster power heatmap';
    otherwise
        tfMatrix = squeeze(mean(data.power(:,plotRegion-4,:),2));
        test = {EEG.chanlocs.labels};
                titleS = ['Electrode' test{plotRegion-4} 'power heatmap'];
end
figure
imagesc(tfMatrix)
line([data.eventOnsetValue*data.Fsample data.eventOnsetValue*data.Fsample], [1 60],'Color',uisetcolor([0.6 0.8 1],'Select a color for event onset'),'LineWidth',2)
yticks(1:10:60)
F = logspace(log10(data.Fstart),log10(data.Fend),60); 
data.F = F;
yticklabels(round(data.F(1:10:60),2))
xlabel('Time (ms)')
ylabel('Frequency (Hz)')
xticks([1:data.Fsample:size(data.EEG.data,2),size(data.EEG.data,2)])
xticklabels(-data.eventOnsetValue*1000 : 1000 : ((size(data.EEG.data,2)/data.Fsample-data.eventOnsetValue)*1000))
colorbar
colorLimit = inputdlg('Enter a value of color bar limit','Colorbar limit',[1 20],{'4'});
colorLimit = str2num(colorLimit{1});
caxis([-colorLimit colorLimit])
title(titleS)
data.tfMatrix = tfMatrix;
fprintf('figure plot done!\n')
guidata(gcbo,data);


% --- Executes on selection change in plotElectrodePopup.
function plotElectrodePopup_Callback(hObject, eventdata, handles)
% hObject    handle to plotElectrodePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns plotElectrodePopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from plotElectrodePopup


% --- Executes during object creation, after setting all properties.
function plotElectrodePopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to plotElectrodePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in extPhase.
function extPhase_Callback(hObject, eventdata, handles)
% hObject    handle to extPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of extPhase



function sRate_Callback(hObject, eventdata, handles)
% hObject    handle to text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text as text
%        str2double(get(hObject,'String')) returns contents of text as a double


% --- Executes during object creation, after setting all properties.
function text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eventOnset_Callback(hObject, eventdata, handles)
% hObject    handle to eventOnset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eventOnset as text
%        str2double(get(hObject,'String')) returns contents of eventOnset as a double


% --- Executes during object creation, after setting all properties.
function eventOnset_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eventOnset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in baseline.
function baseline_Callback(hObject, eventdata, handles)
% hObject    handle to baseline (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = guidata(gcbo);

% Hint: get(hObject,'Value') returns toggle state of baseline


% --- Executes on button press in loadElec.
function loadElec_Callback(hObject, eventdata, handles)
% hObject    handle to loadElec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = guidata(gcbo);
electrodeList = {data.EEG.chanlocs.labels};
for iElec = 1:size(data.EEG.data,1)
    electrodeList{iElec} = [num2str(iElec) ' ' electrodeList{iElec}];
end
electrodeList = [{'frontal' 'central' 'temporal' 'occipital'} electrodeList];
set(handles.plotElectrodePopup, 'String', electrodeList);



function startFreq_Callback(hObject, eventdata, handles)
% hObject    handle to startFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of startFreq as text
%        str2double(get(hObject,'String')) returns contents of startFreq as a double


% --- Executes during object creation, after setting all properties.
function startFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to startFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function endFreq_Callback(hObject, eventdata, handles)
% hObject    handle to endFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of endFreq as text
%        str2double(get(hObject,'String')) returns contents of endFreq as a double


% --- Executes during object creation, after setting all properties.
function endFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to endFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function numFreq_Callback(hObject, eventdata, handles)
% hObject    handle to numFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numFreq as text
%        str2double(get(hObject,'String')) returns contents of numFreq as a double


% --- Executes during object creation, after setting all properties.
function numFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in saveTF.
function saveTF_Callback(hObject, eventdata, handles)
% hObject    handle to saveTF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = guidata(gcbo);
powerCache = data.power;
uisave('powerCache','time frequency power condition X');
fprintf('***********************\n')
fprintf('power time frequency matrix saved.\n')
fprintf('***********************\n')


% --- Executes on button press in plotContrast.
function plotContrast_Callback(hObject, eventdata, handles)
% hObject    handle to plotContrast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = guidata(gcbo);
% electrode regions
test = {data.EEG.chanlocs.labels};
indx_frontal  =[];
indx_central =[];
indx_temporal  =[];
indx_occipital =[];
for i = 1:size(data.EEG.data,1)
    switch test{i}(1)
        case  'A'
            indx_frontal = [indx_frontal i];
        case  'F'
            indx_frontal = [indx_frontal i];
        case  'C'
            indx_central = [indx_central i];
        case 'T'
            indx_temporal = [indx_temporal i];
        case 'P'
            indx_occipital = [indx_occipital i];
        case 'O'
            indx_occipital = [indx_occipital i];
    end
end
data.plotRegion = get(handles.plotElectrodePopup,'Value');
tfMatrix = data.power - data.otherPower;
switch data.plotRegion
    case 1
        tfMatrix = squeeze(mean(data.power(:,indx_frontal,:),2));
        titleS = ['Frontal cluster power heatmap: ' data.powerName ' > ' data.otherCondName];
    case 2
        tfMatrix = squeeze(mean(data.power(:,indx_central,:),2));
                titleS = ['Central cluster power heatmap: ' data.powerName ' > ' data.otherCondName];
    case 3
        tfMatrix = squeeze(mean(data.power(:,indx_temporal,:),2));
                titleS = ['Temporal cluster power heatmap: ' data.powerName ' > ' data.otherCondName];
    case 4
        tfMatrix = squeeze(mean(data.power(:,indx_occipital,:),2));
                titleS = ['Occipital cluster power heatmap: ' data.powerName ' > ' data.otherCondName];
    otherwise
        tfMatrix = squeeze(mean(data.power(:,plotRegion-4,:),2));
        test = {EEG.chanlocs.labels};
                titleS = ['Electrode' test{plotRegion-4} 'power heatmap: ' data.powerName ' > ' data.otherCondName];
end
figure
imagesc(tfMatrix)
line([data.eventOnsetValue*data.Fsample data.eventOnsetValue*data.Fsample], [1 60],'Color',uisetcolor([0.6 0.8 1],'Select a color for event onset'),'LineWidth',2)
yticks(1:10:60)
F = logspace(log10(data.Fstart),log10(data.Fend),60); 
data.F = F;
yticklabels(round(data.F(1:10:60),2))
xlabel('Time (ms)')
ylabel('Frequency (Hz)')
xticks([1:data.Fsample:size(data.EEG.data,2),size(data.EEG.data,2)])
xticklabels(-data.eventOnsetValue*1000 : 1000 : ((size(data.EEG.data,2)/data.Fsample-data.eventOnsetValue)*1000))
colorbar
colorLimit = inputdlg('Enter a value of color bar limit','Colorbar limit',[1 20],{'4'});
colorLimit = str2num(colorLimit{1});
caxis([-colorLimit colorLimit])
title(titleS)
data.tfMatrix = tfMatrix;
fprintf('figure plot done!\n')
guidata(gcbo,data);


% --- Executes on button press in importPower.
function importPower_Callback(hObject, eventdata, handles)
% hObject    handle to importPower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = guidata(gcbo);
[file,path] = uigetfile('*.mat',...
   'Select the contrast condition file', ...
   'MultiSelect', 'off');
if ischar(file)
    data.otherPower = load([path,file]);
    data.otherPower = data.otherPower.powerCache;
    data.otherCondName = file;
    guidata(gcbo,data);
    fprintf('***********************\n')
    fprintf('power time frequency matrix imported.\n')
    fprintf('***********************\n')
end
