#!perl
use File::Glob qw(:bsd_glob);
use Getopt::Long 2.32; # enable auto_help
use IPC::Open2;
use JSON::XS;
use Pod::Usage;
use Text::Wrap;
use XML::LibXML;
use feature qw(say);
use strict;

=pod

=head1 NAME

C<generate-rdap-cases.pl> - a script which converts RDAP Conformance Tool test
cases into RST test cases.

=head1 SYNOPSIS

    generate-rdap-cases.pl FILE

=head1 OPTIONS

=over

=item *

C<FILE> is the only argument, and is the location of the RDAP Conformance Tool
documentation file (in Word format).

=back

=head1 DESCRIPTION

<generate-zonemaster-cases.pl> use C<pandoc> to convert the Word document to
HTML. It then parses the HTML to retrieve the test case ID and brief summary,
and prints a YAML fragment which can be pasted into C<rst-test-specs.yaml>.

=cut

my $file = $ARGV[0] || pod2usage(1);

open2(my $out, undef, qw(pandoc --metadata title=html --standalone -f docx -t html), $file);

my $html;
$html .= $out->getline while (!$out->eof);

my $doc = XML::LibXML->load_xml('string' => $html);
my @nodes = ($doc->getElementsByTagName('body'))[0]->childNodes;

my %cases;

for (my $i = 0 ; $i < scalar(@nodes) ; $i++) {
    my $el = $nodes[$i];
    next unless ('XML::LibXML::Element' eq ref($el));

    if ('h3' eq $el->localName) {
        my $test = $el->textContent;
        $test =~ s/[\r\n]+/ /g;

        if ($test =~ /^(.+?)\[(.+?)\]$/) {
            $cases{$2} = $1;
        }
    }
}

my $description = 'This test case comes from the RDAP Conformance Tool. ' .
                    "For more information, see\n" .
                    '    https://github.com/icann/rdap-conformance-tool/blob'.
                    '/master/doc/RDAPConformanceToolSpecifications.pdf';

binmode(STDOUT, 'encoding(utf-8)');

my $i = 0;
foreach my $case (sort keys(%cases)) {
    printf(
        "rdap-%02u-%s:\n".
        "  Summary: %s\n".
        "  Description: |\n".
        "    %s\n",
        ++$i,
        $case,
        $cases{$case},
        $description,
    );
}
