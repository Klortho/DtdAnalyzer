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

* Download the latest release, either as a zip file:
  [DtdAnalyzer-0.1.zip](https://github.com/downloads/NCBITools/DtdAnalyzer/DtdAnalyzer-0.1.zip);
  or as a gzipped tar:
  [DtdAnalyzer-0.1.tar.gz](https://github.com/downloads/NCBITools/DtdAnalyzer/DtdAnalyzer-0.1.tar.gz).
  
  _**Note:**  Do not use the "Zip" download button on the
  main GitHub page, or the "Download as zip" or "Download as tar.gz" buttons on the 
  [downloads page](https://github.com/NCBITools/DtdAnalyzer/downloads)!
  Any of those buttons downloads the *source files*, not the pre-built packages.
  They are different!_

* Unzip that file on your machine.  Let's call the root directory of the unzipped 
  package "**_DAZ_**", and assume that you have an environment variable set to point 
  to that.  Alternatively, you could make sure you include that directory into your 
  **_PATH_**.
  
* Open a command/shell window, then try the following command (which analyzers the 
  [Journal Archiving and Interchange](http://jats.nlm.nih.gov/archiving/1.0/dtd.html) 
  flavor of the [NLM/NISO Journal Article Tag Suite](http://jats.nlm.nih.gov/), and 
  writes the output to a file:

  On Windows:

      %DAZ%\dtdanalyzer --system http://jats.nlm.nih.gov/archiving/1.0/JATS-archivearticle1.dtd ^
          JATS-archivearticle1.daz.xml

  On Unix:
  
      $DAZ/dtdanalyzer --system http://jats.nlm.nih.gov/archiving/1.0/JATS-archivearticle1.dtd \
          JATS-archivearticle1.daz.xml

* Check that you have sensible results in the output file, `JATS-archivearticle1.daz.xml`.

* As another example, the next command produces HTML documentation for that DTD.  It should 
  run for a little while and then announce that it's done, and that the documentation is in 
  the `doc` subdirectory.  Only the Unix version of this command is shown.

      $DAZ/dtddocumentor -–system http://jats.nlm.nih.gov/archiving/1.0/JATS-archivearticle1.dtd \
          --exclude mml: --exclude-except mml:math

* Open the `doc/index.html` file there in a browser, and check that it looks correct.

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

