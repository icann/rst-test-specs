#!/usr/bin/perl
use lib qw(/Users/gavin.brown/Code/zonemaster-engine/lib);
use Cwd qw(getcwd realpath);
use Data::Mirror qw(mirror_json);
use File::Basename;
use File::Slurp;
use File::Spec;
use Getopt::Long;
use List::Util qw(any none);
use Pod::Usage;
use URI;
use YAML::XS;
use Zonemaster::Engine;
use constant {
    PROFILE_URL => 'https://raw.githubusercontent.com/zonemaster/zonemaster-engine/%s/share/profile.json',
    ZM_URL_FMT  => 'https://github.com/zonemaster/zonemaster/blob/v%s/%s',
};
use utf8;
use open qw(:std :utf8);
use strict;

my $config = YAML::XS::LoadFile(dirname(dirname(realpath(__FILE__)))
                .'/zonemaster-test-policies.yaml');

my $mode = 'cases';
my $devel;
my $version;
GetOptions(
    'devel'     => \$devel,
    'version=s' => \$version,
    'errors'    => sub { $mode = 'errors'},
    'help'      => sub { pod2usage() },
) || pod2usage();

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

C<--devel> tells the script not to munge the table in the Outcomes section (if
present) to remove unused message tags. This helps with reviewing those tags to
decide whether to override their severity.

=item *

C<ZONEMASTER_DIRECTORY> is the only argument, and is the location of the
Zonemaster repository on the local system.

=back

=head1 DESCRIPTION

<generate-zonemaster-cases.pl> executes the C<generateTestCaseList.pl> script in
the Zonemaster distribution, which generates a Markdown table listing of test
cases grouped by test plan. It then passes the Markdown text to C<pandoc> to
convert to HTML. It then parses the HTML to retrieve the test case ID and brief
summary, and prints a YAML fragment which can be pasted into
C<rst-test-specs.yaml>.

=cut

my $base = $ARGV[0] || pod2usage(1);

my @docpath = qw(docs public specifications tests);

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

my $cases = {};
my $errors = {};

MODULE: foreach my $module (qw(Address Connectivity Consistency Delegation DNSSEC Nameserver Syntax Zone)) {
    my $class = 'Zonemaster::Engine::Test::'.$module;
    my $meta = $class->metadata;

    #
    # extract cases from metadata
    #
    foreach my $case (sort(keys(%{$meta}))) {

        next if (any { $case eq $_ } @{$config->{'skip'}});

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
            'Maturity'  => 'GAMMA',
            'Errors'    => [],
        };

        #
        # relative path to case documentation
        #
        my $mdfile = File::Spec->catfile(@docpath, sprintf('%s-TP', ucfirst($module)), lc($case).'.md');

        #
        # URL of case documentation
        #
        my $url = sprintf(ZM_URL_FMT, $version, $mdfile);

        #
        # initialise description
        #
        $cases->{$id}->{'Description'} = sprintf(
            "This test case comes from version v%s of Zonemaster. "
            ."For more information, see <%s>.\n\n",
            $version,
            $url
        );

        #
        # prepend any comments
        #
        if ($config->{'case_comments'}->{$case}) {
            $cases->{$id}->{'Description'} = $config->{'case_comments'}->{$case}
                                                ."\n\n".$cases->{$id}->{'Description'};
        }

        my $upgraded;

        #
        # process messages
        #
        foreach my $message (sort(@{$meta->{$case}})) {
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
                'Description' => sprintf('For more information about this error, please see <%s#:~:text=%s>.', $url, substr($message, 3)),
                'Severity' => $severity,
            };

            $upgraded = $upgraded || exists($levels{$message});
        }

        #
        # prepend upgrade notice
        #
        if ($upgraded) {
            $cases->{$id}->{'Description'} = "**Note:** the severity levels of one or more error codes for this test case "
                                                ."have been changed from the default.\n\n"
                                                .$cases->{$id}->{'Description'};
        }

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
                $section = lc($2);

                $wanted = any { $section eq $_ } @{$config->{'wanted_sections'}};
            }

            $cases->{$id}->{'Description'} .= $line if ($wanted);
        }
    }
}

my $yaml;
if ('errors' eq $mode) {
    $yaml = YAML::XS::Dump($errors);

} else {
    $yaml = YAML::XS::Dump($cases);

}

$yaml =~ s/^---\n//g;

print $yaml;
