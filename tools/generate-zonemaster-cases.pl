#!perl
use Cwd;
use File::Slurp;
use File::Spec;
use Getopt::Long 2.32; # enable auto_help
use IPC::Open3;
use List::Util qw(any);
use Pod::Usage;
use Symbol qw(gensym);
use Text::Unidecode;
use XML::LibXML;
use YAML::Node;
use YAML::XS;
use constant {
    HTML_ENCODING   => 'UTF-8',
    ZM_URL_FMT      => 'https://github.com/zonemaster/zonemaster/blob/%s/%s',
};
use utf8;
use open qw(:std :utf8);
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
    basic00
    basic01
    basic02
    basic03
    dnssec07
    dnssec11
    syntax01
    syntax02
    syntax03
    syntax08
    zone08
    zone09
    zone11
);

my @wanted_sections = qw(objective summary outcomes);

#
# Human-readable names for test case documentation sections
#
my $snames = {
    'outcomes'  => 'Pass/fail criteria',
};

$YAML::XS::UseHeader = undef;
$YAML::XS::SortKeys = undef;

my $base = $ARGV[0] || pod2usage(1);

my @docpath = qw(docs public specifications tests);

my @md2html = qw(pandoc --ascii -f markdown -t html --standalone);
my @html2md = qw(pandoc -f html -t markdown);

my @cases;

my $dir = getcwd;
chdir($base);
chomp(my $version = `git tag -l | tail -1`);
chdir($dir);

#
# this returns an XML::LibXML::Element object representing the output
# of the generateTestCaseList.pl script
#
my $list = generateTestCaseList(File::Spec->catdir($base, @docpath));

my $plan;
foreach my $row ($list->getElementsByTagName('tr')) {
    my @cells = map { $_->textContent } $row->getElementsByTagName('td');
    next unless ($cells[0]);

    my $id = $cells[0];
    if ($id =~ /-TP$/i) {
        $plan = $id;
        next;
    }

    next if (any { lc($id) eq lc($_) } @skip);

    my $case_id;
    if ($id =~ /^dnssec(\d+)/i) {
        $case_id = lc(sprintf('dnssec-%02u', $1));

    } else {
        $case_id = lc('dns-'.$id);

    }

    next unless ($cells[1]);

    my $mdfile = File::Spec->catfile(@docpath, $plan, lc($id).'.md');
    my $md = join('', read_file(File::Spec->catfile($base, $mdfile)));

    my $cdoc = XML::LibXML->load_html(
        'string'    => md2html($md),
        'encoding'  => HTML_ENCODING,
    );

    my $section;
    my $sections = {};
    foreach my $el (($cdoc->getElementsByTagName('body'))[0]->childNodes) {
        if ($el->localName =~ /^h\d$/) {
            $section = $el->getAttribute('id');

        } else {
            push(@{$sections->{$section}}, $el);

        }
    }

    my $summary = $cells[1];
    chomp($summary);
    $summary =~ s/\n/ /g;

    my $url = sprintf(
        ZM_URL_FMT,
        $version,
        $mdfile
    );

    my $idoc = createHTMLDocument();
    my $body = $idoc->getElementsByTagName('body')->shift;

    my $p = $body->appendChild($idoc->createElement('p'));
    $p->appendText(sprintf(
        'This test case comes from version %s of Zonemaster. '.
        'For more information, see ',
        $version
    ));

    my $a = $p->appendChild($idoc->createElement('a'));
    $a->setAttribute('href' => $url);
    $a->appendText($url);

    $p->appendText('.');

    foreach my $section (@wanted_sections) {
        if (defined($sections->{$section}) && scalar(@{$sections->{$section}}) > 0) {

            $body->appendTextChild(
                'h1',
                $snames->{$section} || ucfirst($section)
            );

            foreach my $el (@{$sections->{$section}}) {
                $body->appendChild($idoc->importNode($el));
            }
        }
    }

    push(@cases, {
        'id'            => $case_id,
        'summary'       => unidecode($summary),
        'description'   => unidecode(html2md($idoc->toStringHTML)),
    });
}

foreach my $case (sort { $a->{'id'} cmp $b->{'id'} } grep { $_->{'id'} !~ /^dnssec/ } @cases) {
    print_case($case);
}

foreach my $case (sort { $a->{'id'} cmp $b->{'id'} } grep { $_->{'id'} =~ /^dnssec/ } @cases) {
    print_case($case);
}

#
# convert Markdown to HTML
#
sub md2html {
    my $markdown = shift;

    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, @md2html);

    $in->print($markdown);
    $in->close;

    my $html = join('', $out->getlines);

    $out->close;

    $err->close;

    waitpid($pid, 0);

    return $html;
}

#
# convert HTML to Markdown
#
sub html2md {
    my $html = shift;

    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, @html2md);

    $in->print($html);
    $in->close;

    my $md = join('', $out->getlines);
    $out->close;

    print STDERR join('', $err->getlines);
    $err->close;

    waitpid($pid, 0);

    return $md;
}

sub print_case {
    my $case = shift;

    my $node = {
        $case->{'id'} => {
            'Summary'       => $case->{'summary'},
            'Description'   => $case->{'description'},
        }
    };

    print "  ".
            join(
                "\n  ",
                grep { '---' ne $_ } split(/\n/, YAML::XS::Dump($node))
            ).
            "\n\n";
}

sub generateTestCaseList {
    my $dir = shift;

    my $err = gensym;
    my $pid = open3(
        my $in,
        my $out,
        $err,
        File::Spec->catfile($base, qw(utils generateTestCaseList.pl)),
        '--dir='.$dir,
    );

    $in->close;

    my $markdown = join('', $out->getlines);
    $out->close;

    print STDERR join('', $err->getlines);
    $err->close;

    waitpid($pid, 0);

    my $doc = XML::LibXML->load_html(
        'string'    => md2html($markdown),
        'encoding'  => HTML_ENCODING,
    );

    return $doc->getElementsByTagName('table')->shift;
}

sub createHTMLDocument {
    my $doc = XML::LibXML::Document->createDocument('1.0', HTML_ENCODING);

    $doc->createInternalSubset('html',undef, undef);

    $doc->setDocumentElement($doc->createElement('html'));

    $doc->documentElement->setAttribute('lang', 'en');
    my $head = $doc->documentElement->appendChild($doc->createElement('head'));

    $head->appendChild($doc->createElement('meta'))->setAttribute('charset', $doc->encoding);
    my $body = $doc->documentElement->appendChild($doc->createElement('body'));

    return $doc;
}
