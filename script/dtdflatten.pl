#!/usr/bin/perl -w
# This is an alternative to the dtdflatten utility, as a concise Perl script
# that uses libxml. It is very fast.
# Thanks to Andrei Kolotev of PMC for this nice script.

use XML::LibXML;
use Getopt::Long;

$XML::LibXML::Error::WARNINGS=2;

my $usage = q(
Usage: ./dtdflatten.pl {[-d] dtd-file | -p public-id}

This generates a flattened version of a DTD.
  -h,--help                 Get help.
  -s,--system-id <system-id>  Use the given system identifier to find the DTD. 
                              This could be a relative or absolute pathname, or a
                              system identifier. HTTP URLs should work fine.
                              If the system identifier is defined in an OASIS
                              catalog file, set XML_CATALOG_FILES to point to that.
                              The '-s' switch is optional.
  -p,--public-id <public-id>  Use the given public identifier to find the DTD.
                              This would be used in conjunction with an OASIS
                              catalog file. The script uses the environment 
                              variable XML_CATALOG_FILES to find it.
);

my $help = 0;
my $system_id = "";
my $public_id = "";
GetOptions(
    "help|?"      => \$help,
    "system-id=s" => \$system_id,
    "public-id=s" => \$public_id,
);
if ($help) {
    print $usage;
    exit 0;
}

if (!$system_id && scalar @ARGV > 0) {
  $system_id = $ARGV[0];
}
if (!$system_id && !$public_id) {
    print "Either system id or public id must be specified.\n";
    print $usage;
    exit 1;
}


my $dtd = XML::LibXML::Dtd->new($public_id, $system_id);

if (! defined $dtd or ref ($@) or $@) {
  die "Failed to parse DTD."
} 

print join "\n", 
  map {$_->toString()} 
    grep {$_->nodeType != XML::LibXML::XML_COMMENT_NODE} 
      $dtd->childNodes()
