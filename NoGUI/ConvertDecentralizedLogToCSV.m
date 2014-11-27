%Add folders to search path
addpath(genpath('C:\Users\thomas\Documents\MATLAB\WindParkGUI'));

%Convert log file .mat to .csv
load('decentralizedLog.mat');

headers = {'Simulation time','DDS time seconds','DDS time nanoseconds','Turbine Id','Setpoint','Current production','Max production','MS since last write','Cache count'};
data = [decentralizedLog.signal1.turbineId.Time decentralizedLog.signal2.sec.Data decentralizedLog.signal2.nanosec.Data decentralizedLog.signal1.turbineId.data decentralizedLog.signal1.setPoint.data decentralizedLog.signal1.currentProduction.data decentralizedLog.signal1.maxProduction.data decentralizedLog.signal1.msSinceLastWrite.data decentralizedLog.signal1.cacheCount.data];

fileBase = 'DecentralizedLog';
fileNumber = 0;
fileEnding = '.csv';

fileName = strcat(fileBase, num2str(fileNumber));
fileName = strcat(fileName, fileEnding);

while (exist(fileName, 'file') == 2)
    fileName = strcat(fileBase, num2str(fileNumber));
    fileName = strcat(fileName, fileEnding);
    
    fileNumber = fileNumber + 1;
end

csvwrite_with_headers(fileName,data,headers);

exit