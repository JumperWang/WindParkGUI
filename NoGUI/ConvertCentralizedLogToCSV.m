%Add folders to search path
addpath(genpath('C:\Users\thomas\Documents\MATLAB\WindParkGUI'));

%Convert log file .mat to .csv
load('centralizedLog.mat');

headers = {'sig4:DDS time seconds','sig:4DDS time nanoseconds','sig1:Simulation time','sig1:Turbine Id','sig1:Setpoint','sig3:TurbineId','sig3:Current production','sig3:Max production','sig2:MS since last write'};
data = [centralizedLog.signal4.sec.Data centralizedLog.signal4.nanosec.Data centralizedLog.signal1.turbineId.Time centralizedLog.signal1.turbineId.data centralizedLog.signal1.setPoint.data centralizedLog.signal3.turbineId.data centralizedLog.signal3.currentProduction.data centralizedLog.signal3.maxProduction.data centralizedLog.signal2.msSinceLastWrite.data];

fileBase = 'CentralizedLog';
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