#!/usr/bin/env perl
use warnings;
use strict;
use feature qw(switch);

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

sub computeDirectorySizes {
  my ($maxsize, $tree, $output) = @_;
  my $total = 0;
  my $recursive = 0;
  while (my ($key, $value) = each %$tree) {
    if ("$value" =~ /^HASH.*/) {
      my ($subtotal, $subrecursive) = computeDirectorySizes($maxsize, $value, $output);
      $total += $subtotal;
      $recursive += $subrecursive;
    } else {
      $total += $value;
    }
  }
  if ($total <= $maxsize) {
    $recursive += $total;
  }
  push @$output, $total;
  return ($total, $recursive);
}

# Parse input

open(FH, '<', 'resources/input.txt') or die $!;

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
}

close(FH);

# Compute results

my $maxsize = 100000;
my @dirsizes;
my ($total, $part1) = computeDirectorySizes($maxsize, \%fs, \@dirsizes);
print "Part 1: $part1\n";

my $available = 70000000;
my $required = 30000000;
my $unused = $available - $total;
my $min = $available; # Almost infinity
for my $size (@dirsizes) {
  if ($size >= ($required - $unused) && $size < $min) {
    $min = $size;
  }
}
my $part2 = $min;
print "Part 2: $part2\n";
