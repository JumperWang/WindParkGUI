function DecentralizedWindParkNoGUI(timeout)
%Add folders to search path
addpath(genpath('C:\Users\thomas\Documents\MATLAB\WindParkGUI'))

%Model name
modelName = 'DecentralizedWindParkModel';

%Load IDL
DDS.import('TurbineMessage.idl');

%Load Model
load_system(modelName);

% set the stop time to inf
set_param(modelName,'StopTime','inf');

% set the simulation mode to normal
set_param(modelName,'SimulationMode','normal');

% start the model
set_param(modelName,'SimulationCommand','start');

t = timer('TimerFcn', 'stopDecentralizedModel',... 
                 'StartDelay',timeout);
start(t)