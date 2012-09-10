# This script sets up the environment for working with the DtdAnalyzer.
# It assumes you have set the environment variable DTDANALYZER_HOME.

if [ "x$DTDANALYZER_HOME" = "x" ] ; then
  echo Please set the DTDANALYZER_HOME environment variable to the project home, and try again.
  exit 1
fi

CLASSPATH=$DTDANALYZER_HOME/bin
CLASSPATH=$CLASSPATH:$DTDANALYZER_HOME/src
CLASSPATH=$CLASSPATH:$DTDANALYZER_HOME/lib/resolver.jar
CLASSPATH=$CLASSPATH:$DTDANALYZER_HOME/lib/saxon.jar
CLASSPATH=$CLASSPATH:$DTDANALYZER_HOME/lib/xercesImpl.jar
CLASSPATH=$CLASSPATH:$DTDANALYZER_HOME/lib/xml-apis.jar
CLASSPATH=$CLASSPATH:$DTDANALYZER_HOME/lib/commons-cli-1.2.jar
export CLASSPATH

export PATH=$DTDANALYZER_HOME/script:$PATH


