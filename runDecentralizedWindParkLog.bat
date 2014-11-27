@echo off
set RUNTIME=%1

@echo off
set RUNTIME=%1

IF "%RUNTIME%"=="" set RUNTIME=40

IF NOT EXIST USER_QOS_PROFILES.xml (
	echo USER_QOS_PROFILES.xml is missing
    EXIT
)

matlab -nodesktop -nosplash -r "DecentralizedWindParkNoGUI(%RUNTIME%)"