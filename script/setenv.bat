@echo off
:: This script sets up the environment for working with the DtdAnalyzer.  
:: It assumes you have set the environment variable DTDANALYZER_HOME.

if (%DTDANALYZER_HOME%)==() goto no_home
goto continue
:no_home
echo Please set the DTDANALYZER_HOME environment variable to the project home, and try again.
goto end

:continue

set CLASSPATH=%DTDANALYZER_HOME%\bin
set CLASSPATH=%CLASSPATH%;%DTDANALYZER_HOME%\src
set CLASSPATH=%CLASSPATH%;%DTDANALYZER_HOME%\lib\resolver.jar
set CLASSPATH=%CLASSPATH%;%DTDANALYZER_HOME%\lib\saxon9he.jar
set CLASSPATH=%CLASSPATH%;%DTDANALYZER_HOME%\lib\xercesImpl.jar
set CLASSPATH=%CLASSPATH%;%DTDANALYZER_HOME%\lib\xml-apis.jar
set CLASSPATH=%CLASSPATH%;%DTDANALYZER_HOME%\lib\commons-cli-1.2.jar
set CLASSPATH=%CLASSPATH%;%DTDANALYZER_HOME%\lib\commons-io-2.4.jar

set PATH=%DTDANALYZER_HOME%;%path%

:end
