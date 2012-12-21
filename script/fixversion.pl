#!/usr/bin/perl

# This script does the following
#   * Modifies the version number in the following files:
#       * build.xml
#       * README.md - in various hyperlinks
#       * ReleaseNotes.md
#   * Removes any left over DtdAnalyzer-*{.zip|.tar.gz} files (in order to
#     make sure these don't get stuffed into the next .zip|tar.gz set).
#   * Removes left over lib/DtdAnalyzer-*.jar
# If the version given is 'dev', then this also:
#   * Creates a new template section at the top of ReleaseNotes.md.


