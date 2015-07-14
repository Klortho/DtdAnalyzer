#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

my $status;
my $cmd;

$cmd = 'dtdflatten http://jats.nlm.nih.gov/archiving/1.0/JATS-archivearticle1.dtd';
my $flat_dtd = 'archiving-1.0-flat.dtd';
$status = system($cmd . ' > ' . $flat_dtd);
ok($status == 0, "dtdflatten");

$cmd = 'xmllint --valid --noout test-yopf.xml';
$status = system($cmd);
ok($status == 0, "xmllint");



