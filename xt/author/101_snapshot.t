#! /usr/bin/perl

use strict;
use warnings;

use Test::More 0.88;
use Debian::Snapshot;

my $s = Debian::Snapshot->new;

{
  my $vs = $s->package_versions("libdist-zilla-perl");
  ok(@$vs > 1, "libdist-zilla-perl source versions found.");
}

{
  my $vs = $s->binaries("libdist-zilla-perl");
  ok(@$vs > 1, "libdist-zilla-perl binary versions found.");
}

done_testing;

# vim:set et sw=2:
