all: clean bin doc t

clean:
	-rm -r doc
	-rm -r bin

bin:
	-mkdir bin
	javac -d bin src/gov/ncbi/pmc/dtdanalyzer/*.java
	javac -d bin src/gov/ncbi/pmc/xml/*.java

doc:
	javadoc -d doc src/gov/ncbi/pmc/dtdanalyzer/*.java src/gov/ncbi/pmc/xml/*.java

t:
#	cd test; contextmodel.sh jats-auth-2.3.xml > jats-auth-2.3.model.xml

