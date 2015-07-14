# DtdAnalyzer Release Notes

## DtdAnalyzer v0.5-dev

### Features

### Enhancements

### Bug fixes

### Performance

### Other

## DtdAnalyzer v0.5 - 2015-07-14

### Enhancements

* Added dtdflatten utility



## DtdAnalyzer v0.4 - 2013-10-21

### Changes

* dtddocumentor now uses the [jatsdoc](https://github.com/Klortho/jatsdoc)
  documentation library
* Miscellaneous bug fixes

## DtdAnalyzer v0.3 - 2013-1-1

### Features

* New dtd2xml2json utility for auto-generating stylesheets that convert
  XML documents into JSON.

### Other

* Test release just to test the release automation scripts.

## DtdAnalyzer v0.2.1 - 2012-12-19

### Features

* Integrated dtdcompare feature, creating new shell scripts, and some documentation
  See GitHub issue #5.

### Enhancements

* Fixed up the command line options so they are simpler.  Now it's possible, for
  example, to just type `dtddocumentor mydtd.dtd`, without having to remember
  "-s".

## DtdAnalyzer v0.2 - 2012-12-18

### Features

* Added auto-generating XML-to-JSON conversion XSLT

### Enhancements

* Cleaned up the regular expressions that match the annotations, so now
  annotations can be leaner.
* Moved binaries into the gh-pages branch, since GitHub deprecated downloads
  feature.

## DtdAnalyzer v0.1.2 - 2012-10-18

### Enhancements

* Add count of number of elements changed, removed, and added to comparison report.
* Several enhancements to the schematron generator stylesheet

### Bug fixes

* Fixed link to home page in documentor output

## DtdAnalyzer v0.1.1 - 2012-10-15

### Enhancements

* Indent output from dtdanalyzer

### Other

* Lots of tweaks to documentation and release procedure

## DtdAnalyzer v0.1 - 2012-10-13

Initial release.
