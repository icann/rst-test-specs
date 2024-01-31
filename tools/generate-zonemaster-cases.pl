#!/usr/bin/perl
use Cwd qw(getcwd realpath);
use Digest::SHA qw(sha1_hex);
use File::Basename;
use File::Slurp;
use File::Spec;
use Getopt::Long;
use IPC::Open3;
use List::Util qw(any none);
use Pod::Usage;
use Symbol qw(gensym);
use Text::Unidecode;
use URI;
use XML::LibXML qw(:libxml);
use YAML::Node;
use YAML::XS;
use constant {
    HTML_ENCODING   => 'UTF-8',
    ZM_URL_FMT      => 'https://github.com/zonemaster/zonemaster/blob/v%s/%s',
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

$YAML::XS::UseHeader = undef;
$YAML::XS::SortKeys = undef;

my $base = $ARGV[0] || pod2usage(1);

my @docpath = qw(docs public specifications tests);

my @md2html = qw(pandoc --ascii -f markdown -t html --standalone);
my @html2md = qw(pandoc -f html -t markdown);

my %errors;
my @cases;

#
# this returns an XML::LibXML::Element object representing the output
# of the generateTestCaseList.pl script in HTML format
#
my $list = generateHTMLTestCaseList(File::Spec->catdir($base, @docpath));

my $plan;
foreach my $row ($list->getElementsByTagName('tr')) {
    my @cells = map { $_->textContent } $row->getElementsByTagName('td');
    next unless ($cells[0]);

    my $id = $cells[0];
    if ($id =~ /-TP$/i) {
        $plan = $id;
        next;
    }

    next if (any { lc($id) eq lc($_) } @{$config->{'skip'}});

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

    my @case_errors;

    my $upgraded = 0;

    my $section;
    my $sections = {};
    foreach my $el ($cdoc->getElementsByTagName('body')->shift->childNodes) {
        if ($el->localName =~ /^h\d$/) {
            $section = $el->getAttribute('id');

        } elsif ($section) {
            if ('table' ne $el->localName) {
                push(@{$sections->{$section}}, $el);

            } else {
                # this is the value of the first cell in the first row of the
                # header of the table
                my $value = uc($el->getElementsByTagName('thead')
                                ->shift->getElementsByTagName('tr')
                                ->shift->getElementsByTagName('th')
                                ->shift->textContent);

                if ($value !~ /message/i) {
                    #
                    # this is not the table we're looking for
                    #
                    push(@{$sections->{$section}}, $el);

                } else {
                    foreach my $row ($el->getElementsByTagName('tbody')->shift->getElementsByTagName('tr')) {
                        my $cells = $row->getElementsByTagName('td');

                        my $id_cell     = $cells->shift;
                        my $sev_cell    = $cells->shift;
                        my $desc_cell   = $cells->pop;

                        my $error_id = 'ZM_'.$id_cell->textContent;

                        #
                        # replace the cell contents with the new ID
                        #
                        $id_cell->removeChildNodes;
                        $id_cell->appendTextChild('code', $error_id);

                        #
                        # this could be simpler but we always want to shift()
                        # the node list
                        #
                        my $severity = $sev_cell->textContent || @{$config->{'error_levels'}}[-1];

                        foreach my $level (keys(%{$config->{'error_level_overrides'}})) {
                            if (any { 'ZM_'.$_ eq $error_id } @{$config->{'error_level_overrides'}->{$level}}) {
                                my $was = $severity;

                                $severity = $level;

                                #
                                # replace the cell contents with the new
                                # severity
                                #
                                $sev_cell->removeChildNodes;
                                $sev_cell->appendTextChild('code', $level);
                                $sev_cell->appendText(' (changed from ');
                                $sev_cell->appendTextChild('code', $was);
                                $sev_cell->appendText(')');

                                $upgraded++;

                                last;
                            }
                        }

                        if (none { $_ eq $severity } @{$config->{'error_levels'}}) {
                            $row->parentNode->removeChild($row) unless ($devel);

                        } else {
                            push(@case_errors, $error_id);

                            if (!defined($errors{$error_id})) {
                                $errors{$error_id} = {
                                    'Severity' => $severity,
                                };
                            }

                            if (!defined($errors{$error_id}->{'description'})) {
                                my $desc = "*Not available.*";

                                if ($desc_cell) {
                                    my $ddoc = createHTMLDocument();

                                    $ddoc->getElementsByTagName('body')
                                        ->shift
                                        ->appendChild($ddoc->importNode(
                                            $desc_cell
                                        ));

                                    $desc = unidecode(html2md(
                                        $ddoc->toStringHTML
                                    ));
                                }

                                $errors{$error_id}->{'Description'} = $desc;
                            }
                        }
                    }

                    push(@{$sections->{$section}}, $el) if ($devel || scalar(@case_errors) > 0);
                }
            }
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
        'This test case comes from version v%s of Zonemaster. '.
        'For more information, see ',
        $version
    ));

    my $a = $p->appendChild($idoc->createElement('a'));
    $a->setAttribute('href' => $url);
    $a->appendText($url);

    $p->appendText('. Some of the information below may not be applicable to the
        RST system.');

    foreach my $section (@{$config->{'wanted_sections'}}) {
        if (defined($sections->{$section}) && scalar(@{$sections->{$section}}) > 0) {

            $body->appendTextChild(
                'h1',
                $config->{'section_name_map'}->{$section} || ucfirst($section)
            );

            foreach my $el (@{$sections->{$section}}) {
                if (XML_ELEMENT_NODE == $el->nodeType) {
                    foreach my $a ($el->getElementsByTagName('a')) {
                        if ('li' eq $a->parentNode->localName && any { lc($a->textContent) eq lc($_) } @{$config->{'skip'}}) {
                            # reference to a skipped test, so remove
                            $a->parentNode->parentNode->removeChild($a->parentNode);

                        } else {
                            # rewrite URL so it works
                            $a->setAttribute('href', URI->new_abs($a->getAttribute('href'), $url)->as_string);

                        }
                    }
                }

                $body->appendChild($idoc->importNode($el));
            }
        }
    }

    if (scalar(@case_errors) < 1) {
        my $error_id = sprintf('ZM_%s_FAILED', uc($case_id));
        $error_id =~ s/-/_/g;

        push(@case_errors, $error_id);

        $errors{$error_id} = {
            'Severity'      => 'ERROR',
            'Description'   => sprintf('The `%s` test case failed, but no further information is available. Please consult the result log for this test case.', $case_id),
        };
    }

    printf(STDERR "Warning: case %s has no errors\n", $case_id) if (scalar(@case_errors) < 1);

    my $description_md = unidecode(html2md($idoc->toStringHTML));

    if ($config->{'case_comments'}->{lc($id)}) {
        $description_md = $config->{'case_comments'}->{lc($id)}."\n\n".$description_md;
    }

    if ($upgraded) {
        $description_md = "**Note:** the severity levels of one or more error codes for this test case have been changed from the default.\n\n".$description_md;
    }

    push(@cases, {
        'id'            => $case_id,
        'summary'       => unidecode($summary),
        'description'   => $description_md,
        'errors'        => [sort { $a cmp $b } @case_errors],
    });
}

if ('errors' eq $mode) {
    foreach my $id (sort { $a cmp $b } keys(%errors)) {
        print_error($id, $errors{$id});
    }

} else {
    foreach my $case (sort { $a->{'id'} cmp $b->{'id'} } grep { $_->{'id'} !~ /^dnssec/ } @cases) {
        print_case($case);
    }

    foreach my $case (sort { $a->{'id'} cmp $b->{'id'} } grep { $_->{'id'} =~ /^dnssec/ } @cases) {
        print_case($case);
    }
}

#
# convert Markdown to HTML
#
sub md2html {
    my $markdown = shift;

    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, @md2html);

    $in->binmode(':encoding(UTF-8)');
    $out->binmode(':encoding(UTF-8)');

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

    $in->binmode(':encoding(UTF-8)');
    $out->binmode(':encoding(UTF-8)');

    $in->print($html);
    $in->close;

    my $md = join('', $out->getlines);
    $out->close;

    $err->close;

    waitpid($pid, 0);

    return $md;
}

sub print_case {
    my $case = shift;

    my $node = {
        $case->{'id'} => {
            'Summary'       => $case->{'summary'},
            'Maturity'      => 'BETA',
            'Description'   => $case->{'description'},
            'Errors'        => $case->{'errors'},
        }
    };

    print join("\n", grep { '---' ne $_ } split(/\n/, YAML::XS::Dump($node)))."\n\n";
}

sub print_error {
    my ($id, $error) = @_;

    print join("\n", grep { '---' ne $_ } split(/\n/, YAML::XS::Dump({$id => $error})))."\n\n";
}

sub generateHTMLTestCaseList {
    my $dir = shift;

    my $err = gensym;
    my $pid = open3(
        undef,
        my $out,
        $err,
        File::Spec->catfile($base, qw(utils generateTestCaseList.pl)),
        '--dir='.$dir,
    );

    $out->binmode(':encoding(UTF-8)');

    my $markdown = join('', $out->getlines);
    $out->close;

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
    $doc->createInternalSubset('html', undef, undef);
    $doc->setDocumentElement($doc->createElement('html'));
    $doc->documentElement->setAttribute('lang', 'en');

    my $head = $doc->documentElement->appendChild($doc->createElement('head'));

    $head->appendChild($doc->createElement('meta'))->setAttribute('charset', $doc->encoding);

    $doc->documentElement->appendChild($doc->createElement('body'));

    return $doc;
}
