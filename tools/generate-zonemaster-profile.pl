#!/usr/bin/env perl
use Getopt::Long;
use List::Util qw(any);
use Cwd qw(getcwd realpath);
use Pod::Usage;
use File::Spec;
use File::Basename;
use YAML::XS;
use JSON::XS;
use Data::Mirror qw(mirror_json);
use constant {
    PROFILE_URL => 'https://raw.githubusercontent.com/zonemaster/zonemaster-engine/v%s/share/profile.json',
};
use strict;

my $version;
GetOptions(
    'version=s' => \$version,
    'help'      => sub { pod2usage() },
) || pod2usage();

my $config = YAML::XS::LoadFile(dirname(dirname(realpath(__FILE__)))
                .'/zonemaster-test-policies.yaml');

#
# get the profile from GitHub
#
my $profile = mirror_json(sprintf(PROFILE_URL, $version));

#
# remove test cases that are present in 'skip'
#
my $i = 0;
while ($i < scalar(@{$profile->{'test_cases'}})) {
    my $case = $profile->{'test_cases'}->[$i];

    if (any { $_ eq $case } @{$config->{'skip'}}) {
        splice(@{$profile->{'test_cases'}}, $i, 1);

    } else {
        $i++;

    }
}

#
# change severity levels for messages we've overridden
#

#
# first we need to transform `error_level_overrides` into a simple hash of
# msg => level
#
my %levels;
foreach my $level (keys(%{$config->{'error_level_overrides'}})) {
    foreach my $message (@{$config->{'error_level_overrides'}->{$level}}) {
        $levels{$message} = $level;
    }
}

#
# iterate through the test_levels structure in the profile and set the levels
#
foreach my $module (keys(%{$profile->{'test_levels'}})) {
    foreach my $message (keys(%{$profile->{'test_levels'}->{$module}})) {
        if (defined($levels{$message})) {
            $profile->{'test_levels'}->{$module}->{$message} = $levels{$message};
            delete($levels{$message});
        }
    }
}

#
# some messages are not explicitly included in the profile, so we need to add
# them in
#
foreach my $message (keys(%levels)) {
    if (defined($config->{'module_hints'}->{$message})) {
        $profile->{'test_levels'}->{$config->{'module_hints'}->{$message}}->{$message} = $levels{$message};
        delete($levels{$message});
    }
}

#
# catch this and throw an error
#
if (scalar(%levels) > 0) {
    print STDERR "One or more messages with overridden severity could not be ".
                    "added to the profile. Please add them to module_hints:\n".
                    YAML::XS::Dump(\%levels);
    exit(1);
}

#
# output canonical JSON
#
print JSON::XS->new->utf8->canonical->pretty->encode($profile);

=pod

=head1 NAME

generate-zonemaster-profile.pl - generate a Zonemaster profile from the RST
policies

=head1 SYNOPSIS

    generate-zonemaster-profile.pl --version=VERSION

The C<--version> argument identifies the version of the L<Zonemaster::Engine>
from which the profile should be taken.

=cut
