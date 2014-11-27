function CentraliizedWindParkNoGUI(timeout)
%Add folders to search path
addpath(genpath('C:\Users\thomas\Documents\MATLAB\WindParkGUI'))

%Model name
modelName = 'CentralizedWindParkModel';

%Load IDL
DDS.import('TurbineDataMessage.idl');
DDS.import('RequestMessage.idl');
DDS.import('SetpointMessage.idl');

%Load Model
load_system(modelName);

% set the stop time to infinite
set_param(modelName,'StopTime','inf');

% set the simulation mode to normal
set_param(modelName,'SimulationMode','normal');

% start the model
set_param(modelName,'SimulationCommand','start');

t = timer('TimerFcn', 'stopCentralizedModel',... 
                 'StartDelay',timeout);
start(t)