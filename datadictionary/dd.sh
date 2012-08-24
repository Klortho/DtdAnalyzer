#!/bin/bash

export DDDIR=/home/maloneyc/Projects/DtdAnalyzer/FromDemian/datadictionary
CP=$DDDIR/datadictionaryapplication.jar
CP=$CP:/pmc/JAVA/xmlsh_1_1_7/lib/resolver.jar
CP=$CP:/pmc/JAVA/saxon6/saxon.jar
CP=$CP:/pmc/JAVA/xmlsh_1_1_7/lib/xercesImpl.jar
CP=$CP:/pmc/JAVA/jing-20030619/bin/xml-apis.jar

java -cp $CP gov.pubmedcentral.dtd.documentation.Application $*
