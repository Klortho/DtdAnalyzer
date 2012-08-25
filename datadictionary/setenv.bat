# This script should be sourced while the current working directory is
# the directory in which this resides.

set PROJ_HOME=%cd%

set CLASSPATH=%PROJ_HOME%\bin
set CLASSPATH=%CLASSPATH%;%PROJ_HOME%\src
set CLASSPATH=%CLASSPATH%;%PROJ_HOME%\..\lib\resolver.jar
set CLASSPATH=%CLASSPATH%;%PROJ_HOME%\..\lib\saxon.jar
set CLASSPATH=%CLASSPATH%;%PROJ_HOME%\..\lib\xercesImpl.jar
set CLASSPATH=%CLASSPATH%;%PROJ_HOME%\..\lib\xml-apis.jar

set PATH=%PROJ_HOME%\script;%path%


