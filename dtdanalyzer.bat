@echo off
set SCRIPTDIR=%~dp0
rem For DTDANALYZER_HOME, strip off the trailing backslash
set DTDANALYZER_HOME=%SCRIPTDIR:~0,-1%

set CP="%DTDANALYZER_HOME%\build"
call :findjars "%DTDANALYZER_HOME%\lib"
set LOGCONFIG=file:%DTDANALYZER_HOME%/etc/log4j.properties
java -cp %CP% -Xmx256M "-Dlog4j.configuration=%LOGCONFIG%" ^
     "-DDTDANALYZER_HOME=%DTDANALYZER_HOME%" ^
     gov.ncbi.pmc.dtdanalyzer.DtdAnalyzer %*
exit /B

:findjars
for %%j in (%1\*.jar) do call :addjar "%%j"
for /D %%d in (%1\*) do call :findjars "%%d"
exit /B

:addjar
set CP=%CP%;%1