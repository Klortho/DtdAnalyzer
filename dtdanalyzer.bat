@echo off
set DTDANALYZER_ROOT=%~dp0
set CP="%DTDANALYZER_ROOT%build"
call :findjars "%DTDANALYZER_ROOT%lib"
set LOGCONFIG=file:%DTDANALYZER_ROOT%etc/log4j.properties
java -cp %CP% -Xmx256M "-Dlog4j.configuration=%LOGCONFIG%" gov.ncbi.pmc.dtdanalyzer.DtdAnalyzer %*
exit /B

:findjars
for %%j in (%1\*.jar) do call :addjar "%%j"
for /D %%d in (%1\*) do call :findjars "%%d"
exit /B

:addjar
set CP=%CP%;%1