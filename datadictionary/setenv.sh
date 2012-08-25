# This script should be sourced while the current working directory is
# the directory in which this resides.

PROJ_HOME=`pwd`

CLASSPATH=$PROJ_HOME/bin
CLASSPATH=$CLASSPATH:$PROJ_HOME/../lib/resolver.jar
CLASSPATH=$CLASSPATH:$PROJ_HOME/../lib/saxon.jar
CLASSPATH=$CLASSPATH:$PROJ_HOME/../lib/xercesImpl.jar
CLASSPATH=$CLASSPATH:$PROJ_HOME/../lib/xml-apis.jar
export CLASSPATH

export PATH=$PROJ_HOME/script:$PATH


