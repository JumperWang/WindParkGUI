function varargout = windParkGUI
DDS.import('Turbine.idl');
% This UI hard codes the name of the model that is being controlled
modelName = 'globalMonitor';
% Do some simple error checking on the input
if ~localValidateInputs(modelName)
    estr = sprintf('The model %s.mdl cannot be found.',modelName);
    errordlg(estr,'Model not found error','modal');
    return
end
% Do some simple error checking on varargout
nargoutchk(0,1);

% Create the UI if one does not already exist.
% Bring the UI to the front if one does already exist.
hf = findall(0,'Tag',mfilename);
if isempty(hf)
    % Create a UI
    hf = localCreateUI(modelName);
else
    % Bring it to the front
    figure(hf);
end

% populate the output if required
if nargout > 0
    varargout{1} = hf;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to create the user interface
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function hf = localCreateUI(modelName)

try
    % Create the figure, setting appropriate properties
    hf = figure('Tag',mfilename,...
        'Toolbar','none',...
        'MenuBar','none',...
        'IntegerHandle','off',...
        'Units','normalized',...
        'Resize','on',...
        'NumberTitle','off',...
        'HandleVisibility','callback',...
        'Name',sprintf('%s',modelName),...
        'CloseRequestFcn',@localCloseRequestFcn,...
        'Visible','off');
    
    % Create an axes on the figure
    ha = axes('Parent',hf,...
        'HandleVisibility','callback',...
        'Unit','normalized',...
        'OuterPosition',[0.25 0.1 0.75 0.8],...
        'Xlim',[0 10],...
        'YLim',[0 300],...
        'Tag','plotAxes');
    xlabel(ha,'Time');
    ylabel(ha,'Power Production');
    title(ha,'Power Production v''s Time');
    grid(ha,'on');
    box(ha,'on');
    
    % Create an edit box containing the model name
    hnl = uicontrol('Parent',hf,...
        'Style','text',...
        'Units','normalized',...
        'Position',[0.05 0.9 0.15 0.03],...
        'BackgroundColor',get(hf,'Color'),...
        'String','Model Name',...
        'HandleVisibility','callback',...
        'Tag','modelNameLabel'); %#ok
    hnl = uicontrol('Parent',hf,...
        'Style','edit',...
        'Units','normalized',...
        'Position',[0.02 0.82 0.21 0.06],...
        'String',sprintf('%s.mdl',modelName),...
        'Enable','inactive',...
        'Backgroundcolor',[1 1 1],...
        'HandleVisibility','callback',...
        'Tag','modelNameLabel'); %#ok
    
    % Create a parameter panel
    htp = uipanel('Parent',hf,...
        'Units','normalized',...
        'Position',[0.02 0.45 0.21 0.3],...
        'Title','Parameters',...
        'BackgroundColor',get(hf,'Color'),...
        'HandleVisibility','callback',...
        'Tag','tunePanel');
    
    % Create number of turbines edit box and label
    htt = uicontrol('Parent',htp,...
        'Style','text',...
        'Units','normalized',...
        'Position',[0.15 0.85 0.7 0.1],...
        'BackgroundColor',get(hf,'Color'),...
        'String','Num. turbines:',...
        'HorizontalAlignment','left',...
        'HandleVisibility','callback',...
        'Tag','modelNameLabel'); %#ok
    hte = uicontrol('Parent',htp,...
        'Style','edit',...
        'Units','normalized',...
        'Position',[0.15 0.6 0.7 0.2],...
        'String','2',...
        'Backgroundcolor',[1 1 1],...
        'Enable','on',...
        'Callback',@localNumberOfTurbinesChanged,...
        'HandleVisibility','callback',...
        'Tag','numberOfTurbines');
    
    % Create visible turbines edit box and label
    htt1 = uicontrol('Parent',htp,...
        'Style','text',...
        'Units','normalized',...
        'Position',[0.15 0.30 0.7 0.2],...
        'BackgroundColor',get(hf,'Color'),...
        'String','Vis. turbines:',...
        'HorizontalAlignment','left',...
        'HandleVisibility','callback',...
        'Tag','modelNameLabel'); %#ok
    hte2 = uicontrol('Parent',htp,...
        'Style','edit',...
        'Units','normalized',...
        'Position',[0.15 0.18 0.7 0.2],...
        'String','',...
        'Backgroundcolor',[1 1 1],...
        'Enable','on',...
        'Callback',@visibleTurbinesChanged,...
        'HandleVisibility','callback',...
        'Tag','visibleTurbines');
    
    % Create a panel for operations that can be performed
    hop = uipanel('Parent',hf,...
        'Units','normalized',...
        'Position',[0.02 0.2 0.21 0.2],...
        'Title','Operations',...
        'BackgroundColor',get(hf,'Color'),...
        'HandleVisibility','callback',...
        'Tag','tunePanel');
    strings = {'Start','Stop'};
    positions = [0.6 0.2];
    tags = {'startpb','stoppb'};
    callbacks = {@localStartPressed, @localStopPressed};
    enabled ={'on','off'};
    for idx = 1:length(strings)
        uicontrol('Parent',hop,...
            'Style','pushbutton',...
            'Units','normalized',...
            'Position',[0.15 positions(idx) 0.7 0.3],...
            'BackgroundColor',get(hf,'Color'),...
            'String',strings{idx},...
            'Enable',enabled{idx},...
            'Callback',callbacks{idx},...
            'HandleVisibility','callback',...
            'Tag',tags{idx});
    end
    
    % Create some application data storing the UI handles and various
    % pieces of information about the model's original state.
    
    % Load the simulink model
    ad = localLoadModel(modelName);

    % Put an empty line on the axes for each signal that will be
    % monitored
    % Save the line handles, which will be useful to have in an
    % array during the graphics updating routine.
    str = get(hte,'String');
    nlines = str2double(str);
    
    hl = nan(1,nlines);
    colourOrder = get(ha,'ColorOrder');
    for idx = 1:nlines
        hl(idx) = line('Parent',ha,...
            'XData',[],...
            'YData',[],...
            'Color',colourOrder(mod(idx-1,size(colourOrder,1))+1,:),...
            'EraseMode','xor',...
            'Tag',sprintf('signalLine%d',idx));
    end
    
    ad.lineHandles = hl;
    
    %Add line for global production
    gpLineHandle = line('Parent',ha,...
            'XData',[],...
            'YData',[],...
            'Color', 'black',...
            'EraseMode','xor',...
            'Tag',sprintf('Overall production'));
    
    ad.globalProductionLineHandle = gpLineHandle;
    
    %Add line for global setpoint
    spLineHandle = line('Parent',ha,...
            'XData',[],...
            'YData',[],...
            'Color', 'r',...
            'EraseMode','xor',...
            'Tag',sprintf('Global setpoint'));
        
    ad.globalSetPointLineHandle = spLineHandle;

    % Create the handles structure
    ad.handles = guihandles(hf);
    
    %Save model name
    ad.modelName = modelName;
    
    % Save the application data
    guidata(hf,ad);
    
    % Position the UI in the centre of the screen
    movegui(hf,'center')
    % Make the UI visible
    set(hf,'Visible','on');
catch ME
    % Get rid of the figure if it was created
    if exist('hf','var') && ~isempty(hf) && ishandle(hf)
        delete(hf);
    end
    % Get rid of the model if it was loaded
    close_system('simpleModel',0)   
    % throw up an error dialog
    estr = sprintf('%s\n%s\n\n',...
        'The UI could not be created.',...
        'The specific error was:',...
        ME.message);
    errordlg(estr,'UI creation error','modal');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to ensure that the model actually exists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function modelExists = localValidateInputs(modelName)

num = exist(modelName,'file');
if num == 4
    modelExists = true;
else
    modelExists = false;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callback Function for Start button
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localStartPressed(hObject,eventdata) %#ok

% get the application data
ad = guidata(hObject);

% Load the model if required (it may have been closed manually).
if ~modelIsLoaded(ad.modelName)
    load_system(ad.modelName);
end

% toggle the buttons
% Turn off the Start button
set(ad.handles.startpb,'Enable','off');
% Turn on the Stop button
set(ad.handles.stoppb,'Enable','on');

% reset the line(s)
for idx = 1:length(ad.lineHandles)
    set(ad.lineHandles(idx),...
        'XData',[],...
        'YData',[]);
end

set(ad.globalProductionLineHandle,...
    'XData', [],...
    'YData', []);

set(ad.globalSetPointLineHandle,...
    'XData', [],...
    'YData', []);

% set the stop time to inf
set_param(ad.modelName,'StopTime','inf');
% set the simulation mode to normal
set_param(ad.modelName,'SimulationMode','normal');
% Set a listener
set_param(ad.modelName,'StartFcn','localAddEventListener');
% start the model
set_param(ad.modelName,'SimulationCommand','start');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callback Function for Stop button
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localStopPressed(hObject,eventdata) %#ok

% get the application data
ad = guidata(hObject);

% stop the model
set_param(ad.modelName,'SimulationCommand','stop');
        
% set model properties back to their original values
set_param(ad.modelName,'Stoptime',ad.originalStopTime);
set_param(ad.modelName,'SimulationMode',ad.originalMode);

% toggle the buttons
% Turn on the Start button
set(ad.handles.startpb,'Enable','on');
% Turn off the Stop button
set(ad.handles.stoppb,'Enable','off');

% Remove the listener
localRemoveEventListener;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callback Function for number of turbines edit box
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localNumberOfTurbinesChanged(hObject, eventdata)
% Create some application data storing the UI handles and various
% pieces of information about the model's original state.

% get the application data
ad = guidata(hObject);

% reset the line(s)
for idx = 1:length(ad.lineHandles)
    set(ad.lineHandles(idx),...
        'XData',[],...
        'YData',[]);
end

set(ad.globalProductionLineHandle,...
    'XData', [],...
    'YData', []);

set(ad.globalSetPointLineHandle,...
    'XData', [],...
    'YData', []);

% Check that a valid value has been entered
str = get(hObject,'String');
newValue = str2double(str);

% Do the change if it's valid
if ~isnan(newValue)   
    % Put an empty line on the axes for each signal that will be
    % monitored
    % Save the line handles, which will be useful to have in an
    % array during the graphics updating routine.
    nlines = newValue; %Number of turbines
    hl = nan(1,nlines);
    colourOrder = get(ad.handles.plotAxes,'ColorOrder');
    for idx = 1:nlines
        hl(idx) = line('Parent',ad.handles.plotAxes,...
            'XData',[],...
            'YData',[],...
            'Color',colourOrder(mod(idx-1,size(colourOrder,1))+1,:),...
            'EraseMode','xor',...
            'Tag',sprintf('signalLine%d',idx));
    end
    
    ad.lineHandles = hl;
    guidata(hObject,ad);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callback Function for visible turbines edit box
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function visibleTurbinesChanged(hObject, eventdata)

% get the application data
ad = guidata(hObject);

str = get(hObject, 'String');
str = strcat('[', str, ']');

visibleTurbineIdList = str2num(str);

for idx = 1:length(ad.lineHandles)
    lHandle = ad.lineHandles(idx);
    
    if isempty(visibleTurbineIdList)
        set(lHandle, 'Visible', 'on')
    else
        if ismember(idx, visibleTurbineIdList)        
            set(lHandle, 'Visible', 'on')
        else
            set(lHandle, 'Visible', 'off') 
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callback Function for deleting the UI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localCloseRequestFcn(hObject,eventdata) %#ok

% get the application data
ad = guidata(hObject);

% Can only close the UI if the model has been stopped
% Can only stop the model is it hasn't already been unloaded (perhaps
% manually).
if modelIsLoaded(ad.modelName)
    switch get_param(ad.modelName,'SimulationStatus');
        case 'stopped'
            % close the Simulink model
            close_system(ad.modelName,0);
            % destroy the window
            delete(gcbo);
        otherwise
            errordlg('The model must be stopped before the UI is closed',...
                'UI Close error','modal');
    end
else
    % destroy the window
    delete(gcbo);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callback Function for adding an event listener
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localAddEventListener

% get the application data
ad = guidata(gcbo);

% execute any original startFcn that the model may have had
if ~isempty(ad.originalStartFcn)
    evalin('Base',ad.originalStartFcn);
end

% Add the listener(s)
% For this example all events call into the same function
ad.eventHandle = cell(1,length(ad.viewing));
for idx = 1:length(ad.viewing)
    ad.eventHandle{idx} = ...
        add_exec_event_listener(ad.viewing(idx).blockName,...
        ad.viewing(idx).blockEvent, ad.viewing(idx).blockFcn);
end

% store the changed app data
guidata(gcbo,ad);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callback Function for executing the event listener
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localEventListener(block, eventdata) %#ok

% get the application data
hf = findall(0,'tag',mfilename);
ad = guidata(hf);
turbineId = block.InputPort(1).Data.turbineId;

% Get the handle to the line that currently needs updating
thisLineHandle = ...
    ad.lineHandles(turbineId);

% Get the data currently being displayed on the axis
xdata = get(thisLineHandle,'XData');
ydata = get(thisLineHandle,'YData');

% Get the simulation time and the block data
sTime = block.CurrentTime;
currentProduction = block.InputPort(1).Data.currentProduction;

newXData = [xdata sTime];
newYData = [ydata currentProduction];

% Display the new data set
set(thisLineHandle,...
    'XData',newXData,...
    'YData',newYData);

%Update global setpoint line
spLineHandle = ...
    ad.globalSetPointLineHandle;

spYData = get(spLineHandle, 'YData');

if length(spYData) < length(newYData)
    setPoint = block.InputPort(1).Data.setPoint;
    newSPData = [spYData setPoint];
    
    set(spLineHandle,...
        'XData',newXData,...
        'YData', newSPData);
end

%Update global production line
gpLineHandle = ...
     ad.globalProductionLineHandle;

gpYData = get(gpLineHandle,'YData');

globalProduction = 0;

if length(gpYData) < length(newYData)
    for idx=1:length(ad.lineHandles)
        lineHandle = ...
            ad.lineHandles(idx);
        data = get(lineHandle,'YData');
        if ~isempty(data)
            globalProduction = globalProduction + data(length(data));
        end
    end

    newgpYData = [gpYData globalProduction];

    set(gpLineHandle,...
        'XData',newXData,...
        'YData', newgpYData);
end

% The axes limits may also need changing
newXLim = [max(0,sTime-10) max(10,sTime)];
newYLim = [0 globalProduction];
set(ad.handles.plotAxes,'Xlim',newXLim);

currentYLim = get(ad.handles.plotAxes, 'YLim');

if currentYLim(2) < globalProduction
    set(ad.handles.plotAxes, 'YLim', newYLim);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callback Function for removing the event listeners
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localRemoveEventListener

% get the application data
ad = guidata(gcbo);

% return the startFcn to its original value
set_param(ad.modelName,'StartFcn',ad.originalStartFcn);

% delete the listener(s)
for idx = 1:length(ad.eventHandle)
    if ishandle(ad.eventHandle{idx})
        delete(ad.eventHandle{idx});
    end
end
% remove this field from the app data structure
ad = rmfield(ad,'eventHandle');
%save the changes
guidata(gcbo,ad);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to check that model is still loaded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function modelLoaded = modelIsLoaded(modelName)

try
    modelLoaded = ...
        ~isempty(find_system('Type','block_diagram','Name',modelName));
catch ME %#ok
    % Return false if the model can't be found
    modelLoaded = false;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to load model and get certain of its parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ad = localLoadModel(modelName)

% Load the simulink model
if ~modelIsLoaded(modelName)
    load_system(modelName);
end
% Create some application data storing various
% pieces of information about the model's original state.
% These will be used to "reset" the model to its original state when
% the UI is closed.
ad.modelName = modelName;

% List the blocks that are to have listeners applied
ad.viewing = struct(...
    'blockName','',...
    'blockHandle',[],...
    'blockEvent','',...
    'blockFcn',[]);

% Every block has a name
ad.viewing(1).blockName = sprintf('%s/Bus Selector', ad.modelName);


% That block has a handle
% (This will be used in the graphics drawing callback, and is done here
% as it should speed things up rather than searching for the handle
% during every event callback.)
ad.viewing(1).blockHandle = get_param(ad.viewing(1).blockName,'Handle');

% List the block event to be listened for
ad.viewing(1).blockEvent = 'PostOutputs';

% List the function to be called
% (These must be subfunctions within this mfile).
ad.viewing(1).blockFcn = @localEventListener;

% Save some of the models original info that this UI may change
% (and needs to change back again when the simulation stops)
ad.originalStopTime = get_param(ad.modelName,'Stoptime');
ad.originalMode =  get_param(ad.modelName,'SimulationMode');
ad.originalStartFcn = get_param(ad.modelName,'StartFcn');

% We'll also have a flag saying if the model has been previously built
ad.modelAlreadyBuilt = false;





