all: clean bin doc t

clean:
	-rm -r doc
	-rm -r bin

bin:
	-mkdir bin
	javac -d bin src/gov/pubmedcentral/dtd/documentation/*.java
	javac -d bin src/gov/pubmedcentral/xml/parser/*.java

doc:
	javadoc -d doc src/gov/pubmedcentral/dtd/documentation/*.java
	javadoc -d doc src/gov/pubmedcentral/xml/parser/*.java

t:
#	cd test; contextmodel.sh jats-auth-2.3.xml > jats-auth-2.3.model.xml

