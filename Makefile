all: clean bin doc t

clean:
	-rm -r doc
	-rm -r bin

bin:
	-mkdir bin
	javac -d bin src/pmctools/*.java

doc:
	javadoc -d doc src/pmctools/*.java

t:
	cd test; contextmodel.sh jats-auth-2.3.xml > jats-auth-2.3.model.xml
