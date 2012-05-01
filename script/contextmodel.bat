:: Windows version of contextmodel.sh

rem if [ ! $1 ]
rem    then echo "Usage: contextmodel.sh xmlinstance {catalog}"
rem    exit 1
rem fi

rem if [ ! $2 ]
rem    then cat=/pmc/load/catalog/pmc3-catalog.xml
rem    else cat=$2
rem fi

rem Catalog not working under Windows yet.
set CAT=M:\JATS\Sourceforge-nlm-jats\trunk\jatspacks\catalog.xml

java -Dorg.xml.sax.driver=org.apache.xerces.parsers.SAXParser gov.ncbi.pmc.dtdanalyzer.ElementContextApplication %1 %CAT%

