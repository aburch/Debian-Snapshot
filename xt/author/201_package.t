#! /usr/bin/perl

use strict;
use warnings;

use Test::More 0.88;
use File::Temp ();

use Debian::Snapshot;

my $tmp = File::Temp->newdir();

my $snapshot = Debian::Snapshot->new;
my $package  = $snapshot->package("libcpan-meta-perl", "2.101461-1");

my $files = $package->download(directory => "$tmp");
note("Downloaded files: ", join(", ", @$files));
ok(@$files == 3, "Downloaded three files for libcpan-meta-perl/2.101461-1 source package.");

done_testing;

# vim:set et sw=2:
