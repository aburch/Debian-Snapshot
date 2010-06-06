#! /usr/bin/perl

use strict;
use warnings;

use Test::More 0.88;
use File::Temp;
use Debian::Snapshot;

my $tmp      = File::Temp->newdir();
my $snapshot = Debian::Snapshot->new;

{
  my $binary = $snapshot->package("libcpan-meta-perl", "2.101461-1")
                        ->binary("libcpan-meta-perl", "2.101461-1");
  my $file = $binary->download(
    architecture => "all",
    directory    => "$tmp",
  );

  note("Downloaded $file");
  ok($file, "download binary package libcpan-meta-perl/2.101461-1 (all)");
}

{
  my $binary = $snapshot->package("libdbd-sqlite3-perl", "1.29-1")
                        ->binary("libdbd-sqlite3-perl", "1.29-1");

  my $file = $binary->download(
    architecture => "amd64",
    directory    => "$tmp",
  );

  note("Downloaded $file");
  ok($file, "download binary package libdbd-sqlite3-perl/1.29-1 (amd64)");
}

{
  my $binary = $snapshot->package("libdbd-sqlite3-perl", "1.29-1")
                        ->binary("libdbd-sqlite3-perl", "1.29-1+b1");

  my $file = $binary->download(
    architecture => "amd64",
    directory    => "$tmp",
  );

  note("Downloaded $file");
  ok($file, "download binary package libdbd-sqlite3-perl/1.29-1+b1 (amd64)");
}

done_testing;

# vim:set et sw=2:
