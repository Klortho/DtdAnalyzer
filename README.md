#DtdAnalyzer

DtdAnalyzer provides a set of tools:

* **dtdanalyzer** - creates an XML representation (using elements and attributes) 
  of an XML DTD
* **dtddocumentor** - generates pretty HTML documentation, including annotations (if 
  present) from specially-formatted comments of the DTD
* **compare-dtds.xsl** - compares two DTDs and generate a report of differences
* **scaffold.xsl** - generates XSLT scaffolding that can be used as a starting point 
  for writing a transform from one schema to another
* **dtdschematron.xsl** - generates a schematron file from the DTD, including extra 
  schematron rules (if present) from specially-formatted comments of the DTD

##Quick start

* From the [downloads page](https://github.com/NCBITools/DtdAnalyzer/downloads), grab
  the latest released version in zip or .tar.gz format, and unzip it to a directory on
  your machine (either Windows or Unix).  Let's call that directory **_DAZ_**.
  *Note:  don't use the "Zip" download button on the
  main GitHub page!  Make sure that you grab one of the distribution files from the 
  [downloads page](https://github.com/NCBITools/DtdAnalyzer/downloads).  They are 
  different!*

* Open a command/shell window, then try this command (which analyzers the [Journal 
  Archiving and Interchange](http://jats.nlm.nih.gov/archiving/1.0/dtd.html) flavor 
  of the [NLM/NISO Journal Article Tag Suite](http://jats.nlm.nih.gov/), and writes 
  the output to a file:

  On Windows:

      **_%DAZ%_**\dtdanalyzer --system http://jats.nlm.nih.gov/archiving/1.0/JATS-archivearticle1.dtd ^
          JATS-archivearticle1.daz.xml

  On Unix:
  
      **_$DAZ_**/dtdanalyzer --system http://jats.nlm.nih.gov/archiving/1.0/JATS-archivearticle1.dtd \
          JATS-archivearticle1.daz.xml

* Check that you have sensible results in the output file, `JATS-archivearticle1.daz.xml`.

As another example, the next command produces HTML documentation for that DTD.  It should run for a 
little while and then announce that it's done, and that the documentation is in the 
`doc` subdirectory.  Only the Unix version of this command is shown.

    **_$DAZ_**/dtddocumentor -–system http://jats.nlm.nih.gov/archiving/1.0/JATS-archivearticle1.dtd \
        --exclude mml: --exclude-except mml:math

Open the `doc/index.html` file there in a browser, and check that it looks correct.

##Documentation

Detailed documentation is available on the [GitHub 
wiki](https://github.com/NCBITools/DtdAnalyzer/wiki).

##Discussion forum / mailing list

This software is in alpha stage. 

Join the [DtdAnalyzer Google group](https://groups.google.com/d/forum/dtdanalyzer) 
for discussions.

File bug reports at the [GitHub issues page](https://github.com/NCBITools/DtdAnalyzer/issues).

##Public domain

This work is in the public domain and may be reproduced, published or otherwise
used without permission of the National Library of Medicine (NLM).
 
Although all reasonable efforts have been taken to ensure the accuracy
and reliability of the software and data, the NLM and the U.S.
Government do not and cannot warrant the performance or results that
may be obtained by using this software or data. The NLM and the U.S.
Government disclaim all warranties, express or implied, including
warranties of performance, merchantability or fitness for any
particular purpose.

