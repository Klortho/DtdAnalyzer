@echo off
set DTDANALYZER_ROOT=%~dp0
set CP="%DTDANALYZER_ROOT%build"
call :findjars "%DTDANALYZER_ROOT%lib"
set LOGCONFIG=file:%DTDANALYZER_ROOT%etc/log4j.properties

rem Check command-line options
set SOURCEDTD=
set CATOPT=
set TITLEOPT=
set ROOTSOPT=
set DOCPROC=
set DESTDIR=
set CSSSKIN=

if /I (%1) == () goto USAGEHELP

:CHECKOPTS
rem First recapitulate these from dtdanalyzer
if /I (%1) == (-h) goto USAGEHELP
if /I (%1) == (--help) goto USAGEHELP
if /I (%1) == (-s) set SOURCEDTD=-s %2& shift
if /I (%1) == (--system) set SOURCEDTD=--system %2& shift
if /I (%1) == (-d) set SOURCEDTD=-d %2& shift
if /I (%1) == (--doc) set SOURCEDTD=--doc %2& shift
if /I (%1) == (-p) set SOURCEDTD=-p %2& shift
if /I (%1) == (--public) set SOURCEDTD=--public %2& shift
if /I (%1) == (-c) set CATOPT=-c %2& shift
if /I (%1) == (--catalog) set CATOPT=--catalog %2& shift
if /I (%1) == (-t) set TITLEOPT=-t %2& shift
if /I (%1) == (--title) set TITLEOPT=--title %2& shift
if /I (%1) == (-r) set ROOTSOPT=-r %2& shift
if /I (%1) == (--roots) set ROOTSOPT=--roots %2& shift
if /I (%1) == (-m) set DOCPROC=-m
if /I (%1) == (--markdown) set DOCPROC=--markdown
if /I (%1) == (--docproc) set DOCPROC=--docproc %2& shift

rem Now, dtddocumentor-specific options
if /I (%1) == (--css) set CSSSKIN=--param css=%2& shift
if /I (%1) == (--dir) set DESTDIR=--param dir=%2& shift
shift
if not (%1)==() goto CHECKOPTS

rem Run the dtdanalyzer with the dtddocumentor stylesheet, and send the output to nul
java -cp %CP% -Xmx256M "-Dlog4j.configuration=%LOGCONFIG%" ^
     gov.ncbi.pmc.dtdanalyzer.DtdAnalyzer ^
     -x "%DTDANALYZER_ROOT%/xslt/dtddocumentor.xsl" ^
     %SOURCEDTD% %CATOPT% %TITLEOPT% %ROOTSOPT% %DOCPROC% %CSSSKIN% %DESTDIR% 
exit /B

:findjars
for %%j in (%1\*.jar) do call :addjar "%%j"
for /D %%d in (%1\*) do call :findjars "%%d"
exit /B

:addjar
set CP=%CP%;%1
exit /B

:USAGEHELP
echo Usage:  dtdanalyzer [-h] [-d {xml-file}  -s {system-id}  -p {public-id}]
echo                     [-c {catalog}] [-x {xslt}] [-t {title}] [{out}]
echo.
echo This script generates HTML documentation from a DTD.
echo Most command-line arguments are the same as those for dtdanalyzer.  This script takes
echo the following additional optional arguments:
echo.
echo  --css {css-file}   Specify the name of a CSS file which will be used on all the pages.
echo  --dir {dest-dir}   Specify the destination directory.
