<h1>DtdAnalyzer</h1>

<h2>Overview</h2>

This tool will create an XML representation (using elements and attributes)
of an XML DTD.

<h2>Usage</h2>

Unix:

    dtdanalyzer.sh [xml] [xsl] [output] {optional: catalog}

Windows:

    dtdanalyzer [xml] [xsl] [output] {optional: catalog}

Or using Java directly:

    java gov.ncbi.pmc.dtdanalyzer.Application  [xml] [xsl] [output] {optional: catalog}


Where:
* xml     = xml instance filename
* xsl     = xsl instance
* output  = file to which output will be written
* catalog = OASIS catalog for entity resolution

This generates an XML representation of the DTD specified in the DOCTYPE declaration
in the XML instance file.

<h2>Development environment / getting started</h2>

The development environment for this project is very rudimentary at present,
and uses make.  To use the scripts that come with the package, first set the
environment variable $DTDANALYZER_HOME to the root of the git repository.
For example (Unix):

    git clone git://github.com/Klortho/DtdAnalyzer.git
    cd DtdAnalyzer
    export DTDANALZER_HOME=`pwd`

Next, set up your environment using either the
setenv.sh or setenv.bat scripts in the scripts directory.  On Unix,

    . script/setenv.sh

On Windows,

    script\setenv

Next, you'll want to download all the dependencies into the lib directory.  This
script is only available for Unix.  On Windows, you'll have to do it manually.

    getlibs.sh

See below for a list of the dependencies.

To build the project, use make.  The Makefile targets are:

* all - default target, everything below.
* clean - deletes intermediate files
* bin - compiles all .java → .class; results go into 'class' directory
* doc - builds javadocs; puts results into 'doc'
* t - runs the script over the test file in the 'test' directory

To run, from the test directory, for example,

    dtdanalyzer.sh archiving-3.0.xml ../xslt/identity.xsl out.xml

<h2>Output format</h2>

The format of the output of this tool is defined in etc/dtd-information.dtd, and summarized
here:  [Question:  why not document this DTD using the tool reflexively?]

    declarations
        elements
            element+
                @name
                @dtdOrder
                @model
                declaredIn
                context?
                    parent+
                        @name
        attributes?
            attribute+
                @name
                attributeDeclaration
                    @element
                    @mode
                    @type
                    @defaultValue
                    declaredIn
                        @systemId
                        @publidId
                        @lineNumber
        parameterEntities?
            entity+
                @name
                @systemId
                @publicId
                declaredIn - [see above]
                value?
        generalEntities?
            entity+ - [see above]


<h2>Dependencies</h2>

The following jar files are required.  You can use the script getlibs.sh to download and
unpack these, if you like.

* Apache XML commons resolver, version 1.2
  * resolver.jar
* Apache Xerces2 Java parser, version 2.11.0
  * xml-apis.jar
  * xercesImpl.jar
* Saxon Home Edition, version 6.5.5
  * saxon.jar

<h2>Discussion forum / mailing list</h2>

Please join the <a href='https://groups.google.com/d/forum/dtdanalyzer'>DtdAnalyzer Google group</a>
for discussions.

<h2>Public domain</h2>

This work is in the public domain and may be used and reproduced without special permission.
