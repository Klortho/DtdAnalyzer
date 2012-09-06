#!/usr/bin/perl

use open qw(:utf8);
use CGI;
my $q = CGI->new;
# Process an HTTP request
$f  = $q->param('f');
# Make sure no one is trying to read our good stuffdie if $f =~ /\//;

print "Content-type: text/xml\n\n" .
      "<preformat>";

open IN, "$f" or die "Can't open input file";
while (my $line = <IN>) {
    $line =~ s/\&/&amp;/g;
    $line =~ s/\</&lt;/g;
    $line =~ s/\>/&gt;/g;
    $line =~ s/\'/&apos;/g;
    $line =~ s/\"/&quot;/g;
    print $line;
}

print "</preformat>\n";

0;


