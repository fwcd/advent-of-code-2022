#!/usr/bin/env perl
use warnings;
use strict;
use feature qw(switch);

open(FH, '<', 'resources/demo.txt') or die $!;

my @pwd = ();

sub cd {
  my ($dest) = @_;
  given ($dest) {
    when ('.') {}
    when ('..') { pop @pwd; }
    when ('/') { @pwd = (); }
    default { push @pwd, $dest; }
  }
}

while (<FH>) {
  if (my ($command, $arg) = ($_ =~ m/\$\s+(\w+)\s*(.*)/)) {
    if ($command eq 'cd') {
      cd($arg);
      my $path = join '/', @pwd;
      print "Now at /$path\n";
    }
  } elsif (my ($size, $name) = ($_ =~ m/(\d+)\s+(.+)/)) {
    print "File $name of size $size\n";
  } elsif (my ($name) = ($_ =~ m/dir\s+(.+)/)) {
    print "Directory $name\n";
  }
}

close(FH);
