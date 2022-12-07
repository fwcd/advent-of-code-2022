#!/usr/bin/env perl
use warnings;
use strict;

open(FH, '<', 'resources/demo.txt') or die $!;

while (<FH>) {
  if (my ($command, $args) = ($_ =~ m/\$\s+(\w+)\s*(.*)/)) {
    print "$command with args $args\n";
  } elsif (my ($size, $name) = ($_ =~ m/(\d+)\s+(.+)/)) {
    print "File $name of size $size\n"
  } elsif (my ($name) = ($_ =~ m/dir\s+(.+)/)) {
    print "Directory $name\n"
  }
}

close(FH);
