# This script grabs the library prerequisites, and unpacks them.

if [ "x$DTDANALYZER_HOME" = "x" ] ; then
  echo Please set the DTDANALYZER_HOME environment variable to the project home, and try again.
  exit 1
fi

cd $DTDANALYZER_HOME
mkdir lib
cd lib

# Apache Commons CLI, version 1.2
wget http://www.apache.org/dist/commons/cli/binaries/commons-cli-1.2-bin.zip
unzip commons-cli-1.2-bin.zip commons-cli-1.2/commons-cli-1.2.jar
cp commons-cli-1.2/commons-cli-1.2.jar .

# Apache Commons IO, version 2.4
wget http://www.apache.org/dist/commons/io/binaries/commons-io-2.4-bin.zip
unzip commons-io-2.4-bin.zip commons-io-2.4/commons-io-2.4.jar
cp commons-io-2.4/commons-io-2.4.jar .

# Apache XML commons resolver, version 1.2
wget http://www.apache.org/dist/xerces/xml-commons/xml-commons-resolver-1.2.zip
unzip xml-commons-resolver-1.2.zip xml-commons-resolver-1.2/resolver.jar
cp xml-commons-resolver-1.2/resolver.jar .

# Saxon Home Edition, version 9.4.0.6
wget http://sourceforge.net/projects/saxon/files/Saxon-HE/9.4/SaxonHE9-4-0-6J.zip/download
unzip SaxonHE9-4-0-6J.zip saxon9he.jar

# Apache Xerces2 Java parser, version 2.11.0
wget http://www.apache.org/dist/xerces/j/Xerces-J-bin.2.11.0.zip
unzip Xerces-J-bin.2.11.0.zip xerces-2_11_0/xercesImpl.jar xerces-2_11_0/xml-apis.jar
cp xerces-2_11_0/*.jar .

