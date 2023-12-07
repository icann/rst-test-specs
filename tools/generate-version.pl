#!perl
use strict;

#
# get the most recent tag
#
my $tag = `git tag --list | tail -1`;
chomp($tag);

#
# remove leading v
#
my $last = $tag;
$last =~ s/^v//;

#
# split
#
my ($major, $minor, $patch) = split(/\./, $last);

#
# get the number of commits since the most recent tag
#
$patch = `git rev-list $tag.. --count`;
chomp($patch);

#
# generate a new version based on the current release and the number of commits
#
printf("%u.%u.%u\n", $major, $minor, 1+$patch);
