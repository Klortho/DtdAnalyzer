all: clean build

clean:
  -rm -r doc
  -rm -r build

build:
  -mkdir build
  javac -d build src/gov/ncbi/pmc/dtdanalyzer/*.java
  javac -d build src/gov/ncbi/pmc/xml/*.java

doc:
  javadoc -d doc src/gov/ncbi/pmc/dtdanalyzer/*.java src/gov/ncbi/pmc/xml/*.java


