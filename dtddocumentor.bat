@echo off

rem Figure out DTDANALYZER_HOME, which is the directory in which this script
rem resides.  It will not include the trailing backslash.
set SCRIPTDIR=%~dp0
set DTDANALYZER_HOME=%SCRIPTDIR:~0,-1%

rem Add the build directory to the classpath.  This script is used both by
rem developers and users.  For developers, the .class files in the build
rem directory will be found first.  Users don't have a build directory.
set CP="%DTDANALYZER_HOME%\build"

rem Add all the .jar files in the lib subdirectory to the classpath
call :findjars "%DTDANALYZER_HOME%\lib"

rem We're not using log4j yet, but we might in the future.  Until then, this
rem shouldn't do any harm.
set LOGCONFIG=file:%DTDANALYZER_HOME%/etc/log4j.properties

rem And, execute!  Setting the DTDANALYZER_HOME system property so that 
rem the utility can find supplementary files like XSLT, CSS and JS.
java -cp %CP% -Xmx256M "-Dlog4j.configuration=%LOGCONFIG%" ^
     "-DDTDANALYZER_HOME=%DTDANALYZER_HOME%" ^
     gov.ncbi.pmc.dtdanalyzer.DtdDocumentor %* 
exit /B

rem Subroutines used to add jar files to classpath
:findjars
for %%j in (%1\*.jar) do call :addjar "%%j"
for /D %%d in (%1\*) do call :findjars "%%d"
exit /B

:addjar
set CP=%CP%;%1
