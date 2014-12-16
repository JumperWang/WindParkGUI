function varargout = windParkGUI

%Load IDL
DDS.import('TurbineMessage.idl');

% This UI hard codes the name of the model that is being controlled
modelName = 'DecentralizedWindParkModel';

%Log file is hard coded too
logFile = 'log.csv';

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
    hf = localCreateUI(modelName, logFile);
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
function hf = localCreateUI(modelName, logFile)

try
    % Create the figure, setting appropriate properties
    hf = figure('Tag',mfilename,...
        'Toolbar','none',...
        'MenuBar','none',...
        'IntegerHandle','off',...
        'Units','normalized',...
        'outerposition',[0 0 1 1],...
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
        'YLim',[0 15000],...
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
        'Position',[0.15 0.8 0.7 0.1],...
        'BackgroundColor',get(hf,'Color'),...
        'String','Number of turbines:',...
        'HorizontalAlignment','left',...
        'HandleVisibility','callback',...
        'Tag','modelNameLabel'); %#ok
    hte = uicontrol('Parent',htp,...
        'Style','edit',...
        'Units','normalized',...
        'Position',[0.15 0.7 0.7 0.15],...
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
        'Position',[0.15 0.5 0.7 0.1],...
        'BackgroundColor',get(hf,'Color'),...
        'String','Visible turbines:',...
        'HorizontalAlignment','left',...
        'HandleVisibility','callback',...
        'Tag','modelNameLabel'); %#ok
    hte1 = uicontrol('Parent',htp,...
        'Style','edit',...
        'Units','normalized',...
        'Position',[0.15 0.4 0.7 0.15],...
        'String','',...
        'Backgroundcolor',[1 1 1],...
        'Enable','on',...
        'Callback',@visibleTurbinesChanged,...
        'HandleVisibility','callback',...
        'Tag','visibleTurbines');
    
    % Create log to file edit box and label
    htt2 = uicontrol('Parent',htp,...
        'Style','text',...
        'Units','normalized',...
        'Position',[0.15 0.2 0.7 0.1],...
        'BackgroundColor',get(hf,'Color'),...
        'String','Log to file:',...
        'HorizontalAlignment','left',...
        'HandleVisibility','callback',...
        'Tag','modelNameLabel'); %#ok
    hte2 = uicontrol('Parent',htp,...
        'Style','edit',...
        'Units','normalized',...
        'Position',[0.15 0.1 0.7 0.15],...
        'String', logFile,...
        'Backgroundcolor',[1 1 1],...
        'Enable','on',...
        'Callback',@logFileChanged,...
        'HandleVisibility','callback',...
        'Tag','visibleTurbines');
    
    % Create a panel for operations that can be performed
    hop = uipanel('Parent',hf,...
        'Units','normalized',...
        'Position',[0.02 0.1 0.21 0.3],...
        'Title','Operations',...
        'BackgroundColor',get(hf,'Color'),...
        'HandleVisibility','callback',...
        'Tag','tunePanel');
    strings = {'Start','Stop','Cache count','Cycletime'};
    positions = [0.7 0.5 0.3 0.1];
    tags = {'startpb','stoppb','cachecountpb','cycletimepb'};
    callbacks = {@localStartPressed, @localStopPressed, @localCacheCountPressed, @localCycleTimePressed};
    enabled ={'on','off','off','off'};
    for idx = 1:length(strings)
        uicontrol('Parent',hop,...
            'Style','pushbutton',...
            'Units','normalized',...
            'Position',[0.15 positions(idx) 0.7 0.17],...
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
            'LineWidth',2,...
            'Tag',sprintf('signalLine%d',idx));
    end
    
    ad.lineHandles = hl;
    
    %Add line for global production
    gpLineHandle = line('Parent',ha,...
            'XData',[],...
            'YData',[],...
            'Color', 'black',...
            'EraseMode','xor',...
            'LineWidth',2,...
            'Tag',sprintf('Overall production'));
    
    ad.globalProductionLineHandle = gpLineHandle;
    
    %Add array to save individual production
    str = get(hte,'String');
    nlines = str2double(str);
    ad.individualProduction = zeros(1,nlines);
    
    %Add line for global setpoint
    spLineHandle = line('Parent',ha,...
            'XData',[],...
            'YData',[],...
            'Color', 'r',...
            'EraseMode','xor',...
            'LineWidth',2,...
            'Tag',sprintf('Global setpoint'));
        
    ad.globalSetPointLineHandle = spLineHandle;
    
    %Add array to save individual setpoints
    str = get(hte,'String');
    nlines = str2double(str);
    ad.individualSetpoints = zeros(1,nlines);
    
    %Add line for global max production
    gmLineHandle = line('Parent',ha,...
            'XData',[],...
            'YData',[],...
            'Color', 'blue',...
            'EraseMode','xor',...
            'LineWidth',2,...
            'Tag',sprintf('Global max production'));
        
    ad.globalMaxProductionLineHandle = gmLineHandle;
    
    %Add legend for interesting lines
    legend([gmLineHandle, spLineHandle, gpLineHandle],'Global max power production', 'Global setpoint', 'Global power production');
    
    %Add array to save individual max production
    ad.individualMaxProduction = zeros(1,nlines);
    
    %Add array to save timestamps for last turbine update
    ad.individualTimeStamps = nan(1, nlines);

    % Create the handles structure
    ad.handles = guihandles(hf);
    
    %Save model name
    ad.modelName = modelName;
    
    %Save log file
    ad.logFile = logFile;
    
    %Add time variables
    ad.currentTime = 0;
    ad.startTime = 0;
    
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

set(ad.globalMaxProductionLineHandle,...
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

%Convert log file .mat to .csv
load('decentralizedLog.mat')

headers = {'Simulation time','DDS time seconds','DDS time nanoseconds','Turbine Id','Setpoint','Current production','Max production','MS since last write','Cache count'};
data = [decentralizedLog.signal1.turbineId.Time decentralizedLog.signal2.sec.Data decentralizedLog.signal2.nanosec.Data decentralizedLog.signal1.turbineId.data decentralizedLog.signal1.setPoint.data decentralizedLog.signal1.currentProduction.data decentralizedLog.signal1.maxProduction.data decentralizedLog.signal1.msSinceLastWrite.data decentralizedLog.signal1.cacheCount.data];

csvwrite_with_headers(ad.logFile,data,headers);

%Reset time
ad.currentTime = 0;
ad.startTime = 0;

guidata(hObject, ad);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callback Function for Cache count button
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localCacheCountPressed(hObject, eventData)
% get the application data
ad = guidata(hObject);

% Load figure
cacheCountFigure = cacheCountGUI(hObject);

% Save new figure in application data
ad.cacheCountFigure = cacheCountFigure;
guidata(hObject,ad);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callback Function for Cycle time button
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localCycleTimePressed(hObject, eventData)
% get the application data
ad = guidata(hObject);

% Load figure
cycleTimeFigure = cycleTimeGUI(hObject);

% Save new figure in application data
ad.cycleTimeFigure = cycleTimeFigure;
guidata(hObject,ad);

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

set(ad.globalMaxProductionLineHandle,...
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
    ad.individualSetpoints = zeros(1,newValue);
    ad.individualMaxProduction = zeros(1, newValue);
    ad.individualTimeStamps = nan(1, newValue);
    
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
% Callback Function for visible turbines edit box
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function logFileChanged(hObject, eventdata)
% get the application data
ad = guidata(hObject);

ad.logFile = get(hObject, 'String');

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
function localAddEventListener()

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
block.InputPort(1).Data;

% Get the handle to the line that currently needs updating
if turbineId ~= 0
    thisLineHandle = ...
        ad.lineHandles(turbineId);
    
    %timeBlock = get_param(gcb,'globalMonitor/Bus Selector1')
    %sec = get(timeBlock, 'sec')  
    
    % Get the data currently being displayed on the axis
    xdata = get(thisLineHandle,'XData');
    ydata = get(thisLineHandle,'YData');

    % Get the simulation time and the block data
    %sTime = block.CurrentTime;
    sTime = ad.currentTime;

    currentProduction = block.InputPort(1).Data.currentProduction;
    
    newXData = [xdata sTime];
    newYData = [ydata currentProduction];

    % Display the new data set
    set(thisLineHandle,...
        'XData',newXData,...
        'YData',newYData);

    %Set timestamp
    ad.individualTimeStamps(turbineId) = sTime;
    
    %Check for dead turbines
    checkForDeadTurbines(ad, hf, block, turbineId);
    
    %Update global lines
    updateGlobalLines(ad, hf, block, turbineId, newYData, newXData);
    
    %Update cycle time figure if it exists
    updateCycleTimeFigure(hf, block, newYData, newXData);

    % The axes limits may also need changing
    newXLim = [max(0,sTime-10) max(10,sTime)];
    set(ad.handles.plotAxes,'Xlim',newXLim);

    % currentYLim = get(ad.handles.plotAxes, 'YLim');
    % 
    % if currentYLim(2) < globalProduction
    %     newYLim = [0 globalProduction + 50];
    %     set(ad.handles.plotAxes, 'YLim', newYLim);
    % end
    % 
    % if currentYLim(2) > globalProduction + 50 && globalProduction ~= 0
    %      newYLim = [0 globalProduction + 50];
    %      set(ad.handles.plotAxes, 'YLim', newYLim);
    % end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callback Function for executing the time event listener
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localTimeEventListener(block, eventdata) %#ok

% get the application data
hf = findall(0,'tag',mfilename);
ad = guidata(hf);

% Set current time
sec = block.InputPort(1).Data.sec;
nanosec = block.InputPort(1).Data.nanosec;

if ad.startTime == 0
    ad.startTime = str2num(sprintf('%d.%09d',sec,nanosec));
    ad.currentTime = 0;
else
    ad.currentTime = str2num(sprintf('%d.%09d',sec,nanosec)) - ad.startTime;
end

%Save back to application data
guidata(hf,ad);

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
ad.viewing(2).blockName = sprintf('%s/Bus Selector1', ad.modelName);


% That block has a handle
% (This will be used in the graphics drawing callback, and is done here
% as it should speed things up rather than searching for the handle
% during every event callback.)
ad.viewing(1).blockHandle = get_param(ad.viewing(1).blockName,'Handle');
ad.viewing(2).blockHandle = get_param(ad.viewing(2).blockName,'Handle');

% List the block event to be listened for
ad.viewing(1).blockEvent = 'PostOutputs';
ad.viewing(2).blockEvent = 'PostOutputs';

% List the function to be called
% (These must be subfunctions within this mfile).
ad.viewing(1).blockFcn = @localEventListener;
ad.viewing(2).blockFcn = @localTimeEventListener;

% Save some of the models original info that this UI may change
% (and needs to change back again when the simulation stops)
ad.originalStopTime = get_param(ad.modelName,'Stoptime');
ad.originalMode =  get_param(ad.modelName,'SimulationMode');
ad.originalStartFcn = get_param(ad.modelName,'StartFcn');

% We'll also have a flag saying if the model has been previously built
ad.modelAlreadyBuilt = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to calculate global outputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function globalOutput = calculateGlobalOutput(individualOutputArray)
globalOutput = 0;

for idx=1:length(individualOutputArray)
    globalOutput = globalOutput + individualOutputArray(idx);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function set globalLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setGlobalLine(lineHandle, nextPoint, newYData, newXData)
gpYData = get(lineHandle, 'YData');

if length(gpYData) < length(newYData)
    newYData = [gpYData nextPoint];

    set(lineHandle,...
        'XData', newXData,...
        'YData', newYData);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function update global lines (setpoint, production, max production)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updateGlobalLines(ad, hf, block, turbineId, newYData, newXData)
%Update global setpoint line
globalSetpoint = calculateGlobalOutput(ad.individualSetpoints);

setGlobalLine(ad.globalSetPointLineHandle, globalSetpoint, newYData, newXData)

%Update global max production line
globalMax = calculateGlobalOutput(ad.individualMaxProduction);

setGlobalLine(ad.globalMaxProductionLineHandle, globalMax, newYData, newXData)

%Update global production line
globalProduction = calculateGlobalOutput(ad.individualProduction);

setGlobalLine(ad.globalProductionLineHandle, globalProduction, newYData, newXData);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function checks for dead turbines and resets relevant values
% if one or more is found
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function checkForDeadTurbines(ad, hf, block, turbineId)
lastUpdatedArray = ad.individualTimeStamps;
currentTime = ad.currentTime;

%Initialize timestamp array if values are nan
if isnan(lastUpdatedArray(1))
    for idx=1:length(ad.lineHandles)
        lastUpdatedArray(idx) = currentTime;
    end
end

%Identify old timestamps and reset relevant values
for idx=1:length(ad.lineHandles)
    lastUpdated = lastUpdatedArray(idx);
    timeDiff = currentTime - lastUpdated;
    
    if timeDiff > maxTimeDiff() || isnan(timeDiff)
        %Reset values
        ad.individualSetpoints(idx) = 0;
        ad.individualMaxProduction(idx) = 0;
        ad.individualProduction(idx) = 0;
                
        ydata = get(ad.lineHandles(idx),'YData');
        
        if length(ydata) > 0
            ydata(end) = 0;

            set(ad.lineHandles(idx),...
                'YData', ydata);
        end
    else
        ad.individualSetpoints(turbineId) = block.InputPort(1).Data.setPoint;
        ad.individualMaxProduction(turbineId) = block.InputPort(1).Data.maxProduction;
        ad.individualProduction(turbineId) = block.InputPort(1).Data.currentProduction;    
    end
end

%Save updated values
guidata(hf,ad);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function updates the cycle time figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updateCycleTimeFigure(hf, block, newXData, newYData)
ad = guidata(hf);

if isfield(ad, 'cycleTimeFigure')    
    turbineId = block.InputPort(1).Data.turbineId;
    
    ad.cycleTimeFigure.individualCycleTimes(turbineId) = block.InputPort(1).Data.msSinceLastWrite;
    
    avgCycleTime = mean(ad.cycleTimeFigure.individualCycleTimes);
    
    setGlobalLine(ad.cycleTimeFigure.avgCycleTimeHandle, avgCycleTime, newYData, newXData);
    
    %save the changes
    guidata(hf,ad);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function returns maximum allowed time difference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function maxTimeDiff = maxTimeDiff()
maxTimeDiff = 7;
