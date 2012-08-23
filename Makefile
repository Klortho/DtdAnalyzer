all: clean bin doc t

clean:
	-rm -r doc
	-rm -r bin
	-rm test/*.model.xml

bin:
	-mkdir bin
	javac -d bin src/gov/ncbi/pmc/dtdanalyzer/*.java

doc:
	javadoc -d doc src/gov/ncbi/pmc/dtdanalyzer/*.java

t:
	cd test; contextmodel.sh jats-auth-2.3.xml > jats-auth-2.3.model.xml

