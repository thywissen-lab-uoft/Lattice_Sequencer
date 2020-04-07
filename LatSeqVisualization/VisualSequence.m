function varargout = VisualSequence(varargin)
% VISUALSEQUENCE MATLAB code for VisualSequence.fig
%      VISUALSEQUENCE, by itself, creates a new VISUALSEQUENCE or raises the existing
%      singleton*.
%
%      H = VISUALSEQUENCE returns the handle to a new VISUALSEQUENCE or the handle to
%      the existing singleton*.
%
%      VISUALSEQUENCE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VISUALSEQUENCE.M with the given input arguments.
%
%      VISUALSEQUENCE('Property','Value',...) creates a new VISUALSEQUENCE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before VisualSequence_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to VisualSequence_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help VisualSequence

% Last Modified by GUIDE v2.5 13-May-2013 19:11:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @VisualSequence_OpeningFcn, ...
                   'gui_OutputFcn',  @VisualSequence_OutputFcn, ...
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


% --- Ideas and bug section -----------------------------------------
% * Zooming out still doesn't work right.
% * Could add check boxes to remove certain channels.
% * Could add history of zoom areas to quickly switch between them
% * Could add a trigger function, where one trigger channel is "monitored"
% * Add a scale to the color sliders.
% -------------------------------------------------------------------


% --- Executes just before VisualSequence is made visible.
function VisualSequence_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to VisualSequence (see VARARGIN)

% Choose default command line output for VisualSequence
handles.output = hObject;

handles.timerRedraw = timer('Period',0.1,...    timer object to check for
    'ExecutionMode','fixedRate',...             redraw after zoom.
    'StartDelay',0.5,...
    'Tag','timerRedraw',...
    'UserData',[[0 10];[0.5 14.5]],...
    'TimerFcn',{@timer_Callback, handles});

handles.timerUpdate = timer('Period',1,...      timer object to check for
    'ExecutionMode','fixedRate',...             updated seqdata structure.
    'StartDelay',1,...
    'Tag','timerUpdate',...
    'UserData',-1,...
    'TimerFcn',{@timer_Callback, handles});


handles.channels = [1 3 7:17 20:24 18 27 28 19 2 34 35 36 26 5 25 29 ...
    30 5 33 40 38 41 45 44 43 39 46 42 37];
handles.firstChannelIndex = 1;

handles.checkChannel = [];

DrawSequence(handles.axesMain, 0, 1,...
    handles.channels, ...
    eval(get(handles.edittimes,'string')), handles, 1);

DrawColorscale(handles.axesColorscale);

% Update handles structure
guidata(hObject, handles);






% UIWAIT makes VisualSequence wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = VisualSequence_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --------------------------------------------------------------------
function uitoolzoom_Callback(hObject, eventdata, handles)
% hObject    handle to uitoolzoom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ( strcmp(get(hObject,'state') , 'on') )
    zoom on;
    start(handles.timerRedraw);
else
    zoom off;
    pause(0.1);
    stop(handles.timerRedraw);
end

% --- Timer Callback.
function timer_Callback(hObject, eventdata, handles)
% hObject    handle to the timer
% eventdata  information about the timer
% handles    structure with handles and user data (see GUIDATA)

stop(hObject); % stop timer for what follows

switch hObject.Tag
    case 'timerRedraw' % redraw sequence after zooming
        
        xLimits = get(handles.axesMain,'xlim'); % get current limits of axes
        yLimits = get(handles.axesMain,'ylim');
        
        if (sum(sum(hObject.UserData == [xLimits;yLimits]))~=4 ) % check whether limits have changed
            
            handles = guidata(handles.figure1);
       
            if ( ((yLimits(2)-yLimits(1)) == length(handles.channels)) ) % double-click to zoom out
                xLimits = eval(get(handles.edittimes,'string'));
                xLimits = [min(xLimits) max(xLimits)]; % all times (can be overwritten below if time axes is locked)
                yLimits = [1 length(handles.channels)]; % all channels
            else
                yLimits = round(get(handles.axesMain,'ylim') + [0.05 -0.05]) ... a little bit of user friendly margin
                         + handles.firstChannelIndex - 1; % shift by index channels displayed in lowest row
                yLimits = [max(yLimits(1),1) min(yLimits(2),length(handles.channels))];
            end
            
            if ( get(handles.checklocktime, 'Value') ) % check whether time axis is locked
                xLimits = get(hObject,'UserData');
                xLimits = xLimits(1,:);
            end
            
            channels = handles.channels(yLimits(1):yLimits(2));
                    
            DrawSequence(handles.axesMain, 0, 1, channels, xLimits, handles, 1);
        end
        
        
    case 'timerUpdate' % redraw sequence after it has been updated
        lastSeq = evalin('base','seqdata.seqstart');
        
        if ( hObject.UserData ~= lastSeq ) % check whether sequence has been drawn already
            
            disp('Redrawing sequence.')
            xLimits = get(handles.axesMain,'xlim'); % get current limits of axes
            
            handles = guidata(handles.figure1); % for some reason have to do this, since handles does not seem to be updated correctly at first
            
            yLimits = round(get(handles.axesMain,'ylim') + [0.05 -0.05]) ... a little bit of user friendly margin
                      + handles.firstChannelIndex - 1; % shift by index channels displayed in lowest row
            yLimits = [max(yLimits(1),1) min(yLimits(2),length(handles.channels))];
            channels = handles.channels(yLimits(1):yLimits(2));
                        
            DrawSequence(handles.axesMain, 0, 1, channels, xLimits, handles, 1);
            
            hObject.UserData = lastSeq;
        end
end

start(hObject); % restart timer (start/stop makes StartDelay be the effective Period)


% --- Executes on slider movement.
function slider_Callback(hObject, eventdata, handles)
% hObject    handle to slidermax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

values = [get(handles.slidermax,'Value') get(handles.slidermin,'Value')];

set(handles.textmax,'string',sprintf('%4.2f',max(values)));
set(handles.textmin,'string',sprintf('%4.2f',min(values)));

if ( values(1) ~= values(2) );
    set(handles.axesMain,'CLim',sort(values));
    set(handles.axesColorscale,'CLim',sort(values));
end





% --- Executes during object creation, after setting all properties.
function slidermin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slidermin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on mouse press over axes background.
function axesMain_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axesMain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




function editchannels_Callback(hObject, eventdata, handles)
% hObject    handle to editchannels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editchannels as text
%        str2double(get(hObject,'String')) returns contents of editchannels as a double


% --- Executes during object creation, after setting all properties.
function editchannels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editchannels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edittimes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edittimes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function axesMain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axesMain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axesMain


% --- Executes during object creation, after setting all properties.
function slidermax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slidermax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edittimes_Callback(hObject, eventdata, handles)
% hObject    handle to edittimes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edittimes as text
%        str2double(get(hObject,'String')) returns contents of edittimes as a double


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

disp('Goodbye!');

stop(handles.timerRedraw);
stop(handles.timerUpdate);

delete(handles.timerRedraw);
delete(handles.timerUpdate);

pause(0.5);

delete(hObject);


% --- Executes on button press in pushredraw.
function pushredraw_Callback(hObject, eventdata, handles)
% hObject    handle to pushredraw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.channels = eval(get(handles.editchannels,'string'));
disp('Redrawing sequence.')
DrawSequence(handles.axesMain, 0, 1,...
    eval(get(handles.editchannels,'string')),...
    eval(get(handles.edittimes,'string')), handles, 1);


% --- Executes on button press in checklocktime.
function checklocktime_Callback(hObject, eventdata, handles)
% hObject    handle to checklocktime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checklocktime


% --- Executes on button press in checkupdate.
function checkupdate_Callback(hObject, eventdata, handles)
% hObject    handle to checkupdate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

status = get(hObject,'Value');

if ( status );
    start(handles.timerUpdate);
else
    stop(handles.timerUpdate);
end


function DrawColorscale(hObject)
% hObject   axes handle; where to draw color map

x = -1:1;
y = -10:0.1:10;
[x,y] = meshgrid(x,y);
h = pcolor(hObject, x, y, y);
set(h, 'EdgeColor', 'none');

set(hObject,'YAxisLocation','right');
set(hObject,'XTick',[]);
set(hObject,'YTick',-10:10);
