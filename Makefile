all: clean bin doc t

clean:
	-rm -r doc
	-rm -r build

bin:
	-mkdir build
	javac -d build src/gov/ncbi/pmc/dtdanalyzer/*.java
	javac -d build src/gov/ncbi/pmc/xml/*.java

doc:
	javadoc -d doc src/gov/ncbi/pmc/dtdanalyzer/*.java src/gov/ncbi/pmc/xml/*.java

t:
	cd test; dtdanalyzer.sh jats-auth-2.3.xml ../xslt/identity.xsl jats-auth-2.3.daz.xml

