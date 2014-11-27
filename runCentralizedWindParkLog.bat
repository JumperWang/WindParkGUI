@echo off
set RUNTIME=%1

IF "%RUNTIME%"=="" set RUNTIME=40

matlab -nodesktop -nosplash -r "CentralizedWindParkNoGUI(%RUNTIME%)"