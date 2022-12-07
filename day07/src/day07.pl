#!/usr/bin/env perl
use warnings;
use strict;
use feature qw(switch);

open(FH, '<', 'resources/demo.txt') or die $!;

my @pwd;
my %fs;

sub printTree {
  my ($indent, $tree) = @_;
  while (my ($key, $value) = each %$tree) {
    print "$indent$key -> $value\n";
    if ("$value" =~ /^HASH.*/) {
      printTree("$indent  ", $value);
    }
  }
}

sub get {
  my ($path, $tree) = @_;
  my $len = scalar(@$path);
  if ($len > 0) {
    my @subpath = (@$path)[1..($len - 1)];
    my $subtree = $tree->{$path->[0]};
    return get(\@subpath, $subtree);
  } else {
    return $tree;
  }
}

sub insertFile {
  my ($name, $size) = @_;
  my ($tree) = get(\@pwd, \%fs);
  $tree->{$name} = $size;
}

sub insertDir {
  my ($name) = @_;
  print "Pwd: @pwd\n";
  my ($tree) = get(\@pwd, \%fs);
  $tree->{$name} = {};
}

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
    insertFile($name, $size);
  } elsif (my ($name) = ($_ =~ m/dir\s+(.+)/)) {
    print "Directory $name\n";
    insertDir($name);
  }
  print "<tree>\n";
  printTree("", \%fs);
  print "</tree>\n";
}

close(FH);
