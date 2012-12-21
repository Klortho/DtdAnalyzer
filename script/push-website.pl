#!/usr/bin/perl
# This script:
#   * Moves the newly build .zip and .tar.gz files into website/downloads,
#   * Updates website/index.html to point to these
#   * Updates the website/downloads/index.html file to add these binaries to
#     the list.

use strict;
use File::Copy 'move';

my $zipFile;
my $version;
foreach my $f (<DtdAnalyzer-*.zip>) {
    # Do sanity checking to make sure there is only one, and that it's version
    # number looks like a release version number
    if ($zipFile) {
        die "Found more than one zip file.\n";
    }
    if ($f !~ m/DtdAnalyzer-(\d(\.\d)+)\.zip/) {
        die "Zip filename doesn't look like a release binary.\n";
    }
    $zipFile = $f;
    $version = $1;
}
if (!$zipFile) {
    die "Couldn't find any zip file.\n";
}

my $gzFile;
foreach my $f (<DtdAnalyzer-*.tar.gz>) {
    if ($gzFile) {
        die "Found more than one gz file.\n";
    }
    if ($f !~ m/DtdAnalyzer-(\d(\.\d)+)\.tar.gz/) {
        die "GZ filename doesn't look like a release binary.\n";
    }
    if ($version ne $1) {
        die "Tar and GZ version numbers don't match!\n";
    }
    $gzFile = $f;
}
if (!$gzFile) {
    die "Couldn't find any gz file.\n";
}

# Now move them:
print "Found zip and gz version $version, moving to website/downloads.\n";
#move $zipFile, 'website/downloads';
#move $gzFile, 'website/downloads';

# Fix website/index.html
my ($old, $new);
$old = "website/index.html";
print "Fixing $old\n";
$new = "$old.tmp";
open(OLD, "< $old") or die "Can't open $old: $!";
open(NEW, "> $new") or die "Can't open $new for writing: $!";
while (<OLD>) {
    s/DtdAnalyzer-\d(\.\d)+/DtdAnalyzer-$version/g;
    (print NEW $_) or die "Can't write to $new: $!";
}
close(OLD) or die "Can't close $old: $!";
close(NEW) or die "Can't close $new: $!";
#unlink $old or die "Can't remove $old: $!";
#rename($new, $old) or die "can't rename $new to $old: $!";

# Fix website/downloads/index.html
$old = "website/downloads/index.html";
print "Fixing $old\n";
$new = "$old.tmp";
open(OLD, "< $old") or die "Can't open $old: $!";
open(NEW, "> $new") or die "Can't open $new for writing: $!";
while (<OLD>) {
    if (/\<h2\>Latest release\<\/h2\>/) {
        (print NEW $_) or die "Can't write to $new: $!";
        print NEW "    <p>$version</p>\n" .
                  "    <ul>\n" .
                  "      <li><a href='DtdAnalyzer-$version.tar.gz'>DtdAnalyzer-$version.tar.gz</a></li>\n" .
                  "      <li><a href='DtdAnalyzer-$version.zip'>DtdAnalyzer-$version.zip</a></li>\n" .
                  "    </ul>\n" .
                  "    <h2>Old releases</h2>\n";
    }
    elsif (/\<h2\>Old releases\<\/h2\>/) {
        # do nothing
    }
    else {
        (print NEW $_) or die "Can't write to $new: $!";
    }
}
close(OLD) or die "Can't close $old: $!";
close(NEW) or die "Can't close $new: $!";
#unlink $old or die "Can't remove $old: $!";
#rename($new, $old) or die "can't rename $new to $old: $!";
