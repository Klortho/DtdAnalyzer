# This script should be sourced while the current working directory is
# the directory in which this resides.

PROJ_HOME=`pwd`

CLASSPATH=$PROJ_HOME/bin
CLASSPATH=$CLASSPATH:/pmc/JAVA/xmlsh_1_1_7/lib/resolver.jar
CLASSPATH=$CLASSPATH:/pmc/JAVA/saxon6/saxon.jar
CLASSPATH=$CLASSPATH:/pmc/JAVA/xmlsh_1_1_7/lib/xercesImpl.jar
CLASSPATH=$CLASSPATH:/pmc/JAVA/jing-20030619/bin/xml-apis.jar
export CLASSPATH



