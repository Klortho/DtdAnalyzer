<h1>DtdAnalyzer</h1>

[Note:  Name was changed from "Context Model".]

<h2>Overview</h2>

This tool will create an XML representation (using elements and attributes)
of an XML DTD. The XML representation can be used to create a Context Table
or to compare versions of a DTD.

<h2>Usage</h2>

    /pmc/bin/contextmodel.sh foo.xml my-catalog.xml > foo-info.xml

Note: catalog is optional; if not specified, defaults to /pmc/load/catalog/pmc3-catalog.xml

This generates an XML representation of the DTD specified in the DOCTYPE declaration
in foo.xml.

<h2>XML Structure</h2>

    elements
        element+
            @name @dtdOrder @model @note @modelNote @group
        attributes?
            attribute+
                @attName @mode @type [content is the attribute value]
        context
            parent*

<h2>Development environment</h2>

The development environment for this project is very rudimentary at present,
and uses make.  Here are the contents:

  - Makefile - targets are:

        * all - default target, everything below.
        * clean - deletes intermediat files
        * build - compiles all .java → .class; results go into 'class' directory
        * doc - builds javadocs; puts results into 'doc'
        * t - runs the script over the test file in the 'test' directory

  - setenv.sh - sets up PATH and CLASSPATH to point to the (hard-coded) development
    directories

  - bin - directory containing the script contextmodel.sh

  - src/pmctools/*.java - the Java source files

  - test/*.xml - a few samples files

<h2>Dependencies</h2>

This utility is dependent on the <a href='http://xerces.apache.org/xerces2-j/'>Apache
Xerces2 Java parser</a>, version 2.4.0 or later.

<h2>Discussion forum / mailing list</h2>

Please join the <a href='http://dtdanalyzer.25130.n6.nabble.com/'>discussion forum / mailing 
list</a> on Nabble.

<h2>Public domain</h2>

This work is in the public domain and may be used and reproduced without special permission.
