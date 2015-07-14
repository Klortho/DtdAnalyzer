#DtdAnalyzer

DtdAnalyzer provides a set of tools:

* **dtdanalyzer** - creates an XML representation (using elements and attributes)
  of an XML DTD
* **dtddocumentor** - generates pretty HTML documentation, including annotations (if
  present) from specially-formatted comments of the DTD
* **dtdflatten** - flattens a multi-file DTD into one big file
* **dtdcompare** - compares two DTDs and generate a report of differences
* **dtd2xml2json** - generates XSLT to convert instance documents into JSON format.
* **dtdschematron** - generates a schematron file from the DTD, including extra
  schematron rules (if present) from specially-formatted comments of the DTD
* **scaffold.xsl** - generates XSLT scaffolding that can be used as a starting point
  for writing a transform from one schema to another

## Home page and documentation

The home page for this project is at http://dtd.nlm.nih.gov/ncbi/dtdanalyzer.

Detailed documentation is available on the [GitHub
wiki](https://github.com/NCBITools/DtdAnalyzer/wiki).

##Quick start

* Download the latest release, either as a zip file:
  [DtdAnalyzer-0.5.zip](http://dtd.nlm.nih.gov/ncbi/dtdanalyzer/downloads/DtdAnalyzer-0.5.zip);
  or as a gzipped tar:
  [DtdAnalyzer-0.5.tar.gz](http://dtd.nlm.nih.gov/ncbi/dtdanalyzer/downloads/DtdAnalyzer-0.5.tar.gz).

  _**Note:**  Do not use the "Zip" download button on the main GitHub page!
  That button downloads the *source files*, not the pre-built packages.
  They are different!_

* Unzip that file on your machine.

* Open up a Windows command or a bash shell window.  Add the path to the package root
  to your PATH environment variable.

  On Windows:

  ```
  set PATH=%PATH%;-path-to-dtdanalyzer-package-
  ```

  On Unix:

  ```
  export PATH=$PATH:-path-to-dtdanalyzer-package-
  ```

* Try the following command (which analyzes the
  [Journal Archiving and Interchange](http://jats.nlm.nih.gov/archiving/1.0/dtd.html)
  flavor of the [NLM/NISO Journal Article Tag Suite](http://jats.nlm.nih.gov/), and
  writes the output to a file):

  ```
  dtdanalyzer http://jats.nlm.nih.gov/archiving/1.0/JATS-archivearticle1.dtd out.daz.xml
  ```

* Check that you have sensible results in the output file, `out.daz.xml`.

* As another example, the next command produces HTML documentation for that DTD.  It should
  run for a little while and then announce that it's done, and that the documentation is in
  the `doc` subdirectory. (Enter all on one line).

  ```
  dtddocumentor http://jats.nlm.nih.gov/archiving/1.0/JATS-archivearticle1.dtd
    --exclude mml: --exclude-except mml:math
  ```

* Open the `doc/index.html` file in a browser, and check that it looks good.

* Run `--help` with any of the tools for more complete usage information,
  or continue by visiting the documentation pages on the [GitHub
  wiki](https://github.com/NCBITools/DtdAnalyzer/wiki).

##Discussion forum / mailing list

This software is in beta stage.

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

