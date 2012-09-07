#!/usr/bin/perl

open GISTLIST, "gist-list.txt" or die "Can't open gist-list.txt";

my @gistents;
while (my $gist = <GISTLIST>)
{
    chomp $gist;
    print "converting $gist\n";

    open G, $gist or die "Can't open $gist";

    my $gistent = $gist;
    $gistent =~ s/\..*/.ent/;
    print "  writing $gistent\n";
    push @gistents, $gistent;
    open GE, ">$gistent" or die "Can't open $gistent for writing";
    print GE "<preformat>";
    while (my $line = <G>) {
      $line =~ s/\&/\&amp;/g;
      $line =~ s/\</\&lt;/g;
      $line =~ s/\>/\&gt;/g;
      $line =~ s/\'/\&apos;/g;
      $line =~ s/\"/\&quot;/g;
      print GE $line;
    }
    print GE "</preformat>";
    close GE;
    close G;
}

close GISTLIST;

print "Entity declarations:\n";
print "=========================================\n";

print "[\n";
foreach my $gistent (@gistents) {
    my $ent = $gistent;
    $ent =~ s/\..*//;
    print "<!ENTITY $ent SYSTEM \"$gistent\">\n";
}

print "]\n";
print "=========================================\n";

