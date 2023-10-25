#!perl
use File::Spec;
use Getopt::Long 2.32; # enable auto_help
use IPC::Open2;
use List::Util qw(any);
use Pod::Usage;
use XML::LibXML;
use strict;

=pod

=head1 NAME

C<generate-zonemaster-cases.pl> - a script which converts Zonemaster test cases
into RST test cases.

=head1 SYNOPSIS

    generate-zonemaster-cases.pl ZONEMASTER_DIRECTORY

=head1 OPTIONS

=over

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

#
# any test listed here will be ignored
#
my @skip = qw(
    basic01
    basic03
    dnssec07
    dnssec11
    syntax08
    zone08
    zone09
    zone11
);

my $base = $ARGV[0] || pod2usage(1);

my $generator = File::Spec->catfile($base, qw(utils generateTestCaseList.pl));
my $testdir = File::Spec->catdir($base, qw(docs public specifications tests));

my $pid = open2(my $out, undef, $generator, '--dir='.$testdir);
$out->binmode('encoding(utf-8)');

my $markdown = join('', $out->getlines);
$out->close;
waitpid($pid, 0);

$pid = open2($out, my $in, qw(pandoc -f markdown -t html));

$in->binmode('encoding(utf-8)');
$in->print($markdown);
$in->close;

$out->binmode('encoding(utf-8)');

my $html = join('', $out->getlines);
$out->close;
waitpid($pid, 0);

my $doc = XML::LibXML->load_html('string' => $html);

binmode(STDOUT, 'encoding(utf-8)');

my @cases;

my $plan;
foreach my $row ($doc->getElementsByTagName('tr')) {
    my @cells = map { $_->textContent } $row->getElementsByTagName('td');
    next unless ($cells[0]);

    my $id = $cells[0];
    if ($id =~ /-TP$/i) {
        $plan = $id;
        next;
    }

    next if (any { lc($id) eq lc($_) } @skip);

    my $case_id = lc($id =~ /^dnssec/i ? $id : 'dns-'.$id);

    next unless ($cells[1]);

    my $summary = $cells[1];

    $summary =~ s/\n/ /g;
    chomp($summary);
    next if (!$summary);

    my $description = sprintf(
        'This test case comes from Zonemaster. ' .
        "For more information, see\n" .
        '      https://github.com/zonemaster/zonemaster/blob' .
        '/master/docs/public/specifications/tests/%s/%s.md',
        $plan,
        lc($id)
    );

    push(@cases, {
        'id'            => $case_id,
        'summary'       => $summary,
        'description'   => $description,
    });
}

foreach my $case (sort grep { $_->{'id'} !~ /^dnssec/ } @cases) {
    printf(
        "  %s:\n".
        "    Summary: %s\n".
        "    Description: %s\n",
        $case->{'id'},
        $case->{'summary'},
        $case->{'description'},
    );
}

foreach my $case (sort grep { $_->{'id'} =~ /^dnssec/ } @cases) {
    printf(
        "  %s:\n".
        "    Summary: %s\n".
        "    Description: |\n".
        "      %s\n",
        $case->{'id'},
        $case->{'summary'},
        $case->{'description'},
    );
}
