function stopCentralizedModel()
    set_param('CentralizedWindParkModel','SimulationCommand','stop');
    close_system('CentralizedWindParkModel')
    
    if (exist('centralizedLog.mat', 'file') == 2)
        %Convert log file .mat to .csv
        load('centralizedLog.mat');

        headers = {'sig4:DDS time seconds','sig:4DDS time nanoseconds','sig2:MS since last write'};
        data = [centralizedLog.signal2.sec.Data centralizedLog.signal2.nanosec.Data centralizedLog.signal1.msSinceLastWrite.data];

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
    end
    
    exit