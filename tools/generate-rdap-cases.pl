#!/usr/bin/perl
use Getopt::Long 2.32; # enable auto_help
use IPC::Open2;
use Pod::Usage;
use XML::LibXML;
use YAML::XS;
use constant {
    CASE_DESCRIPTION    => 'This test case comes from the RDAP Conformance Tool. For more information, see <https://github.com/icann/rdap-conformance-tool/blob/master/doc/RDAPConformanceToolSpecifications.pdf>.',
    ERROR_DESCRIPTION   => 'For more information about this error, please refer to the test case(s) that use it.',
};
use utf8;
use open qw(:std :utf8);
use feature qw(say);
use strict;

my $mode;
GetOptions('errors' => sub { $mode = 'errors'});

my $file = $ARGV[0] || pod2usage(1);

#
# use pandoc to convert the doc file to HTML
#
my $pid = open2(my $out, undef, qw(pandoc --metadata title=html --standalone -f docx -t html), $file);

my $html;
$html .= $out->getline while (!$out->eof);
$out->close;

waitpid($pid, 0);

#
# parse the HTML
#
my $doc = XML::LibXML->load_xml('string' => $html);

my $cases = {};
my $errors = {};
my $j = 0;
my $case;
foreach my $el ($doc->getElementsByTagName('h3')) {
    my $text = $el->textContent;

    #
    # collapse all whitespace
    #
    $text =~ s/[\r\n]+/ /g;
    chomp($text);

    #
    # temporary hack to deal with broken document structure
    #
    $text =~ s/^(RFC7159|RDAP_RFCs|IDNA_RFCs)+//g;

    if ($text =~ /^(.+?)\s*\[(.+?)\]$/) {
        my $summary = $1;
        $case = sprintf('rdap-%02u-%s', ++$j, $2);

        my $error = uc($case).'_FAILED';
        $error =~ s/-/_/g;

        $errors->{$error} = {
            'Severity'      => 'ERROR',
            'Description'   => ERROR_DESCRIPTION,
        };

        $cases->{$case} = {
            'Summary'       => $summary,
            'Maturity'      => 'GAMMA',
            'Description'   => CASE_DESCRIPTION,
            'Errors'        => [$error],
        }
    }
}

my $yaml = YAML::XS::Dump('errors' eq $mode ? $errors : $cases);
$yaml =~ s/^---\n//;

print $yaml;

exit(0);

=pod

=head1 NAME

C<generate-rdap-cases.pl> - a script which converts RDAP Conformance Tool test
cases into RST test cases.

=head1 SYNOPSIS

    generate-rdap-cases.pl [--errors] FILE

=head1 OPTIONS

=over

=item *

C<--errors> tells the script to generate error codes only.

=item *

C<FILE> is the only argument, and is the location of the RDAP Conformance Tool
documentation file (in Word format).

=back

=head1 DESCRIPTION

<generate-zonemaster-cases.pl> use C<pandoc> to convert the Word document to
HTML. It then parses the HTML to retrieve the test case ID and brief summary,
and prints a YAML fragment which can be pasted into C<rst-test-specs.yaml>.

=cut
