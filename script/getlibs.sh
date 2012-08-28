# This script grabs the library prerequisites, and unpacks them.

if [ "x$DTDANALYZER_HOME" = "x" ] ; then
  echo Please set the DTDANALYZER_HOME environment variable to the project home, and try again.
  exit 1
fi

cd $DTDANALYZER_HOME
mkdir lib
cd lib

# Apache XML commons resolver 1.2
wget http://www.apache.org/dist/xerces/xml-commons/xml-commons-resolver-1.2.zip
unzip xml-commons-resolver-1.2.zip xml-commons-resolver-1.2/resolver.jar
cp xml-commons-resolver-1.2/resolver.jar .

# Apache Xerces2 Java 2.11.0
wget http://www.apache.org/dist/xerces/j/Xerces-J-bin.2.11.0.zip
unzip Xerces-J-bin.2.11.0.zip xerces-2_11_0/xercesImpl.jar xerces-2_11_0/xml-apis.jar
cp xerces-2_11_0/*.jar .


# Saxon 6.5.5 Home Edition
wget http://sourceforge.net/projects/saxon/files/saxon6/6.5.5/saxon6-5-5.zip/download
unzip saxon6-5-5.zip saxon.jar
