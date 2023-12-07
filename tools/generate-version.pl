#!perl
use strict;

my ($major, $minor, $patch);

#
# get the most recent tag
#
my $tag = `git tag --list | tail -1`;
chomp($tag);

if ($tag) {
    #
    # remove leading v
    #
    my $last = $tag;
    $last =~ s/^v//;

    #
    # split
    #
    ($major, $minor, $patch) = split(/\./, $last);

    #
    # get the number of commits since the tag
    #
    $patch = `git rev-list $tag.. --count`;
    chomp($patch);

} else {
    $major = 1;
    $minor = 0;
    $patch = `git log --oneline | wc -l`;

    chomp($patch);
}

printf("%u.%u.%u\n", $major, $minor, 1+$patch);
