all: clean build doc t

clean:
	-rm -r doc
	-rm -r build

build:
	-mkdir build
	javac -d build src/gov/ncbi/pmc/dtdanalyzer/*.java
	javac -d build src/gov/ncbi/pmc/xml/*.java

doc:
	javadoc -d doc src/gov/ncbi/pmc/dtdanalyzer/*.java src/gov/ncbi/pmc/xml/*.java

# This only works on Unix.  We will move away from makefile soon, and maybe start
# using junit.
t:
	cd test; dtdanalyzer --doc archiving-3.0.xml out.xml

