#!perl
use strict;

my $tag = `git tag --list | tail -1`;
chomp($tag);

my $last = $tag;
$last =~ s/^v//;

my ($major, $minor, $patch) = split(/\./, $last);

$patch = `git rev-list $tag.. --count`;
chomp($patch);

printf("%u.%u.%u\n", $major, $minor, 1+$patch);
