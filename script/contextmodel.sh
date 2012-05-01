#!/bin/sh

# Dorky script to run the pmctools.ElementContextApplication class, which is a dorky
# class to extract element and context info from an XML DTD.
# Pass in two arguments: URI to an xml instance that calls the
# DTD; location of xml catalog to resolve PUBLIC and SYSTEM IDs.
# If second argument not present, then just use a default.
if [ ! $1 ]
   then echo "Usage: contextmodel.sh xmlinstance {catalog}"
   exit 1
fi

if [ ! $2 ]
   then cat=/pmc/load/catalog/pmc3-catalog.xml
   else cat=$2
fi

java -Dorg.xml.sax.driver=org.apache.xerces.parsers.SAXParser \
  gov.ncbi.pmc.dtdanalyzer.ElementContextApplication $1 $cat

#java -classpath /pmc/JAVA/pmctools/pmctools.jar:$CLASSPATH \
#  -Dorg.xml.sax.driver=org.apache.xerces.parsers.SAXParser pmctools.ElementContextApplication $1 $cat
