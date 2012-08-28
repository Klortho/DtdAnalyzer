# This script should be sourced while the current working directory is
# the directory in which this resides.


set CLASSPATH=%DTDANALYZER_HOME%\bin
set CLASSPATH=%CLASSPATH%;%DTDANALYZER_HOME%\src
set CLASSPATH=%CLASSPATH%;%DTDANALYZER_HOME%\..\lib\resolver.jar
set CLASSPATH=%CLASSPATH%;%DTDANALYZER_HOME%\..\lib\saxon.jar
set CLASSPATH=%CLASSPATH%;%DTDANALYZER_HOME%\..\lib\xercesImpl.jar
set CLASSPATH=%CLASSPATH%;%DTDANALYZER_HOME%\..\lib\xml-apis.jar

set PATH=%DTDANALYZER_HOME%\script;%path%


