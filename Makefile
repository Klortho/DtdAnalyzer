all: clean build doc t

clean:
	-rm -r doc
	-rm -r class

build:
	-mkdir class
	javac -d class src/pmctools/*.java

doc:
	javadoc -d doc src/pmctools/*.java

t:
	cd test; contextmodel.sh jats-auth-2.3.xml > jats-auth-2.3.model.xml
