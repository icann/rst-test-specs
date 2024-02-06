#!/usr/bin/perl
use Cwd qw(getcwd realpath);
use Data::Mirror qw(mirror_json);
use File::Basename;
use File::Slurp;
use File::Spec;
use Getopt::Long 2.32; # enable auto_help
use List::Util qw(any none);
use Pod::Usage;
use URI;
use YAML::XS;
use Zonemaster::Engine;
use constant {
    PROFILE_URL => 'https://raw.githubusercontent.com/zonemaster/zonemaster-engine/%s/share/profile.json',
    ZM_URL_FMT => 'https://github.com/zonemaster/zonemaster/blob/v%s/%s',
    CASE_DESCRIPTION_TEMPLATE => 'This test case comes from version v%s of Zonemaster. For more information, please refer to the [Zonemaster documentation for this test case](%s).',
    ERROR_DESCRIPTION_TEMPLATE => 'For more information about this error, please refer to the [Zonemaster documentation for the test case this error comes from](%s#:~:text=%s).',
    UPGRADE_NOTE => "**Note:** the severity levels of one or more error codes for this test case have been changed from the default.",
};
use utf8;
use open qw(:std :utf8);
use strict;

my $mode = 'cases';
my $version;
GetOptions(
    'version=s' => \$version,
    'errors'    => sub { $mode = 'errors'},
) || pod2usage(1);

#
# this the directory where the Zonemaster documentation is located
#
my $base = $ARGV[0] || pod2usage(1);

my $config = YAML::XS::LoadFile(dirname(dirname(realpath(__FILE__)))
                .'/zonemaster-test-policies.yaml');

#
# the default profile is in the zonemaster-engine repository, so load it from
# GitHub
#
my $profile = mirror_json(sprintf(PROFILE_URL, $Zonemaster::Engine::VERSION));

#
# transform `error_level_overrides` into a simple hash of msg => level
#
my %levels;
foreach my $level (keys(%{$config->{'error_level_overrides'}})) {
    foreach my $message (@{$config->{'error_level_overrides'}->{$level}}) {
        $levels{$message} = $level;
    }
}

#
# cases and errors are stored here
#
my $cases = {};
my $errors = {};

#
# get metadata about each module
#
foreach my $module (qw(Address Connectivity Consistency Delegation DNSSEC Nameserver Syntax Zone)) {
    my $class = 'Zonemaster::Engine::Test::'.$module;
    my $meta = $class->metadata;

    #
    # extract cases and messages from metadata
    #
    foreach my $case (sort(keys(%{$meta}))) {

        next if (any { $case eq $_ } @{$config->{'skip'}});

        process_case($case, $module, @{$meta->{$case}});
    }
}

my $yaml;
if ('errors' eq $mode) {
    $yaml = YAML::XS::Dump($errors);

} else {
    $yaml = YAML::XS::Dump($cases);

}

$yaml =~ s/^---\n//g;
$yaml =~ s/\.\.\.\n$//g;

print $yaml;

exit(0);

sub process_case {
    my ($case, $module, @messages) = @_;

    #
    # transform case ID into one suitable for RST
    #
    my $id = $case;
    if ($id =~ /^dnssec/) {
        $id =~ s/^dnssec/dnssec-/;

    } else {
        $id = 'dns-'.$case;

    }

    #
    # initialise the case object
    #
    $cases->{$id} = {
        'Description'   => '',
        'Maturity'      => 'GAMMA',
        'Errors'        => [],
    };

    #
    # relative path to case documentation
    #
    my $mdfile = File::Spec->catfile(qw(docs public specifications tests), sprintf('%s-TP', ucfirst($module)), lc($case).'.md');

    #
    # URL of case documentation
    #
    my $url = sprintf(ZM_URL_FMT, $version, $mdfile);

    my $upgraded;

    #
    # process messages
    #
    foreach my $message (sort(@messages)) {
        my $severity = $levels{$message} || $profile->{'test_levels'}->{uc($module)}->{$message} || 'WARNING';

        #
        # skip if the level isn't listed
        #
        next unless (any { $severity eq $_ } @{$config->{'error_levels'}});

        $message = 'ZM_'.$message;

        #
        # add to case
        #
        push(@{$cases->{$id}->{'Errors'}}, $message);

        #
        # add to error list
        #
        $errors->{$message} = {
            'Description' => sprintf(
                ERROR_DESCRIPTION_TEMPLATE,
                $url,
                substr($message, 3),
            ),
            'Severity' => $severity,
        };

        $upgraded = $upgraded || exists($levels{$message});
    }

    #
    # append upgrade notice
    #
    if ($upgraded) {
        $cases->{$id}->{'Description'} .= "\n\n".$cases->{$id}->{'Description'};
    }

    #
    # append any comments
    #
    if ($config->{'case_comments'}->{$case}) {
        $cases->{$id}->{'Description'} .= "\n\n".$config->{'case_comments'}->{$case};
    }

    #
    # initialise description
    #
    $cases->{$id}->{'Description'} .= "\n\n".sprintf(
        CASE_DESCRIPTION_TEMPLATE,
        $version,
        $url,
    );

    chomp($cases->{$id}->{'Description'});
    $cases->{$id}->{'Description'} .= "\n\n";

    #
    # read Markdown 
    #
    my @lines = read_file(File::Spec->catfile($base, $mdfile));

    #
    # the summary should be the first line
    #
    if ($lines[0] =~ /^\#+ (.+?): (.+)$/ && uc($case) eq uc($1)) {
        $cases->{$id}->{'Summary'} = $2;
        shift(@lines);
    }

    #
    # extract the wanted sections from the Markdown text and append to the
    # description
    #
    my ($section, $wanted);
    foreach my $line (@lines) {
        if ($line =~ /^(\#+)\s+(.+)$/) {
            #
            # a new section has started
            #
            $section = $2;

            $wanted = any { lc($section) eq $_ } @{$config->{'wanted_sections'}};

            if ($wanted) {
                $cases->{$id}->{'Description'} .= sprintf("# %s\n", $section);
                next;
            }
        }

        $cases->{$id}->{'Description'} .= $line if ($wanted);
    }
}

=pod

=head1 NAME

C<generate-zonemaster-cases.pl> - a script which converts Zonemaster test cases
into RST test cases.

=head1 SYNOPSIS

    generate-zonemaster-cases.pl [--errors] --version=VERSION ZONEMASTER_DIRECTORY

=head1 OPTIONS

=over

=item *

C<--version> tells the script what version of Zonemaster is in
C<ZONEMASTER_DIRECTORY>.

=item *

C<--errors> causes the script to emit a YAML fragment for the Zonemaster errors
rather than the test cases.

=item *

C<--version=VERSION> specifies the version of Zonemaster which should be provided
in test case descriptions.

=item *

C<ZONEMASTER_DIRECTORY> is the only argument, and is the location of the
Zonemaster repository on the local system.

=back

=cut
