#!/usr/bin/perl
# This script does the following
#   * Modifies the version number in the following files:
#       * build.xml
#       * ReleaseNotes.md
#   * If the argument is a new release version number:
#       * README.md - links to the latest release
#   * Removes any left over DtdAnalyzer-*{.zip|.tar.gz} files (in order to
#     make sure these don't get stuffed into the next .zip|tar.gz set).
#   * Removes left over lib/DtdAnalyzer-*.jar
# If the version given is 'dev', then this also:
#   * Creates a new template section at the top of ReleaseNotes.md.

use strict;

my $arg = $ARGV[0];
if (!$arg) {
    die "Need a version number or 'dev', please.\n";
}
if ($arg ne "dev" && $arg !~ /^\d+(\.\d+)+$/) {
    die "That doesn't look like a version number to me.\n";
}
my $switchToDev = ($arg eq "dev");

# Fix files
my ($old, $new);

# Fix build.xml
print "Fixing build.xml\n";
$old = "build.xml";
$new = "$old.tmp";
open(OLD, "< $old") or die "Can't open $old: $!";
open(NEW, "> $new") or die "Can't open $new for writing: $!";

my $oldVersion;
my $newVersion;
while (<OLD>) {
    if (/(\<property name="version" value=\")(.*?)(\"\/\>)/) {
        $oldVersion = $2;
        if ($switchToDev && $oldVersion !~ /^\d+(\.\d+)+$/) {
            die "Old version '$oldVersion' doesn't look like a release version number.\n" .
                "Are you sure you meant to use 'dev'?\n";
        }
        if (!$switchToDev && $oldVersion !~ /-dev$/) {
            die "Old version doesn't look like a dev version to me.  Something's not right.\n";
        }
        $newVersion = $switchToDev ? $oldVersion . "-dev" : $arg;
        print "Changing version number from $oldVersion -> $newVersion.\n";
        s/(\<property name="version" value=\")(.*?)(\"\/\>)/$1$newVersion$3/;
    }
    (print NEW $_) or die "Can't write to $new: $!";
}
close(OLD) or die "Can't close $old: $!";
close(NEW) or die "Can't close $new: $!";
#unlink $old or die "Can't remove $old: $!";
#rename($new, $old) or die "can't rename $new to $old: $!";

if (!$oldVersion) {
    die "Couldn't find a valid version number in build.xml.\n";
}

# Fix README.md
my $lastReleaseVer;
if (!$switchToDev) {
    print "Fixing README.\n";
    $old = "README.md";
    $new = "$old.tmp";
    open(OLD, "< $old") or die "Can't open $old: $!";
    open(NEW, "> $new") or die "Can't open $new for writing: $!";

    while (<OLD>) {
        #print $_;
        if (/(DtdAnalyzer-)(\d+(\.\d+)+)(\.zip|\.tar\.gz)/) {
            $lastReleaseVer = $1;
        }
        if (!$switchToDev) {
            s/(DtdAnalyzer-)(\d+(\.\d+)+)(\.zip|\.tar\.gz)/$1$newVersion$4/g;
        }
        (print NEW $_) or die "Can't write to $new: $!";
    }
    close(OLD) or die "Can't close $old: $!";
    close(NEW) or die "Can't close $new: $!";
    #unlink $old or die "Can't remove $old: $!";
    #rename($new, $old) or die "can't rename $new to $old: $!";
}

# Fix ReleaseNotes.md
# If switching to dev, then write a new template at the top; otherwise,
# just change the version number from old -> new
my $relNotesTemplate = <<RELTEMPL;

## DtdAnalyzer v$newVersion

### Features

### Enhancements

### Bug fixes

### Performance

### Other
RELTEMPL

print "Fixing ReleaseNotes.md.\n";
$old = "ReleaseNotes.md";
$new = "$old.tmp";
open(OLD, "< $old") or die "Can't open $old: $!";
open(NEW, "> $new") or die "Can't open $new for writing: $!";

while (<OLD>) {
    if ($switchToDev) {
        if (/\# DtdAnalyzer Release Notes/) {
            (print NEW $_) or die "Can't write to $new: $!";
            (print NEW $relNotesTemplate) or die "Can't write to $new: $!";
        }
        else {
            (print NEW $_) or die "Can't write to $new: $!";
        }
    }
    else {
        s/\bv$oldVersion\b/v$newVersion/;
        (print NEW $_) or die "Can't write to $new: $!";
    }
}
close(OLD) or die "Can't close $old: $!";
close(NEW) or die "Can't close $new: $!";
#unlink $old or die "Can't remove $old: $!";
#rename($new, $old) or die "can't rename $new to $old: $!";

# Get rid of old DtdAnalyzer-*.zip etc. files
unlink glob "DtdAnalyzer-*.zip";
unlink glob "DtdAnalyzer-*.tar.gz";
unlink glob "lib/DtdAnalyzer-*.jar";

