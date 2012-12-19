#!/usr/bin/perl
# This rudimentary test script does the following:
# * Runs make-samples.sh, which conversion XSLTs and generates JSON files for each
#   of the samples
# * Compares each of the resultant JSON files with the reference one that is in
#   git, and fails if they are different
# * As an added check, runs each resultant JSON through jsonlint
#  (https://github.com/zaach/jsonlint), and fails if there are syntax errors.


use strict;
use File::Compare;

my @samples = qw(
    sample1 sample2a sample2b sample2c sample3 sample4
);
# Set this to true if you have jsonlint installed.
my $test_jsonlint = 0;

my $failpref = "****** Failed: ";


print "Generating outputs for each of the samples.\n";
system "./make-samples.sh";



print "Testing that each expected output exists.\n";
foreach my $s (@samples) {
    my $sjson = $s . ".json";
    die "$failpref $sjson not found." if (!-f $sjson);
}

print "Testing that the new outputs are the same as the reference outputs.\n";
foreach my $s (@samples) {
    my $sjson = $s . ".json";
    my $srefjson = $s . ".ref.json";
    if (compare($sjson, $srefjson) != 0) {
        die "$failpref  New generated $sjson is not the same as refence $srefjson.";
    }
}

if ($test_jsonlint) {
    print "Testing that each new output is valid JSON.\n";
    foreach my $s (@samples) {
        my $sjson = $s . ".json";
        my $jsonlint_cmd = "jsonlint $sjson";
        system($jsonlint_cmd . " > /dev/null 2>\&1");
        if ($? != 0) {
            die "$failpref $sjson does not appear to be valid JSON.\nTry '$jsonlint_cmd'.\n";
        }
    }
}
