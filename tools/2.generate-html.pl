#!perl
#
# this script takes the rst-spec.yaml file and generates an HTML version of it
#
# Usage: perl 2.generate-html.pl rst-test-specs.yaml > rst-test-specs.html
#
use Data::Dumper;
use Encode qw(decode_utf8);
use HTML::Tiny;
use IPC::Open2;
use List::Util qw(any);
use YAML::XS;
use constant {
    'href'          => 'href',
    'ol'            => 'ol',
    'ul'            => 'ul',
    'li'            => 'li',
    'section'       => 'section',
    'Description'   => 'Description',
    'name'          => 'name'
};
use open qw(:std :encoding(UTF-8));
use strict;
use utf8;

undef $/;

my $spec = YAML::XS::LoadFile($ARGV[0]);

my $contact = $spec->{'Contact'};
my $plans   = $spec->{'Test-Plans'};
my $suites  = $spec->{'Test-Suites'};
my $cases   = $spec->{'Test-Cases'};

my $h = HTML::Tiny->new;

my $section = 0;

print "<!doctype html>\n";
print $h->open('html');

print $h->head([
    $h->meta({'charset' => 'UTF-8'}),
    $h->meta({name => 'viewport', 'content' => 'width=device-width'}),
    $h->style(<DATA>),
]);

print $h->open('body');

print_title();

print_nav();

print_main();

print $h->close('body');
print $h->close('html');

sub print_title {
    print $h->header([
        $h->h1('Registry System Testing - Test Specifications'),
        $h->p(sprintf('Version %s', e($spec->{'Version'}))),
        $h->p(sprintf('Last Updated: %s', e($spec->{'Last-Updated'}))),
        $h->p($h->a(
            {href => 'mailto:'.$contact->{'Email'}},
            e($contact->{'Name'}.', '.$contact->{'Organization'})
        )),
    ]);
}

sub print_nav {
    print $h->open('nav');

    print_toc();

    print $h->a(
        {
            'class' => 'toc-link',
            'title' => 'Table of Contents',
            href  => '#table-of-contents',
        },
        ["● ━━", $h->br, "● ━━", $h->br, "● ━━"],
    );

    print $h->close('nav');
}

sub print_toc {
    print $h->a({name => 'table-of-contents'});
    print $h->h2(sprintf('%u. Table of Contents', ++$section));

    print $h->open(ol);

    print $h->li($h->a({href => '#table-of-contents'}, 'Table of Contents'));
    print $h->li($h->a({href => '#preamble'}, 'Preamble'));

    print $h->open(li);
    print_test_plan_toc_list();
    print $h->close(li);

    print $h->open(li);
    print_test_suite_toc_list();
    print $h->close(li);

    print $h->open(li);
    print_test_case_toc_list();
    print $h->close(li);

    print $h->close(ol);
}

sub print_test_plan_toc_list {
    print $h->a({href => '#test-plans'}, 'Test Plans');

    print $h->open(ol);

    my @plans = sort(
        { $plans->{$a}->{'Order'} <=> $plans->{$b}->{'Order'} }
        keys(%{$plans})
    );

    foreach my $plan (@plans) {
        my $anchor = sprintf('#Test-Plan-%s', $plan);

        print $h->li($h->a(
            { href => $anchor },
            e($plans->{$plan}->{'Name'})
        ));
    }

    print $h->close(ol);
}

sub print_test_suite_toc_list {
    print $h->a({href => '#test-cases'}, 'Test Suites');

    print $h->open(ol);

    my @suites = sort(
        { $suites->{$a}->{'Order'} <=> $suites->{$b}->{'Order'} }
        keys(%{$suites})
    );

    foreach my $suite (@suites) {
        my $anchor = sprintf('#Test-Suite-%s', $suite);

        print $h->li($h->a(
            { href => $anchor },
            e($suites->{$suite}->{'Name'})
        ));
    }

    print $h->close(ol);
}

sub print_test_case_toc_list {
    print $h->a({href => '#test-cases'}, 'Test Cases');

    print $h->open(ol);
    foreach my $case (grep { $_ !~ /^Doc/ } sort(keys(%{$cases}))) {
        my $title;
        if ($cases->{$case}->{'Summary'}) {
            $title = sprintf('%s - %s', $case, $cases->{$case}->{'Summary'});

        } else {
            $title = $case;

        }

        my $anchor = sprintf('#Test-Case-%s', $case);

        print $h->li($h->a(
            {href => $anchor},
            e($title)
        ));
    }
    print $h->close(ol);
}

sub print_main {
    print $h->open('main');

    print_preamble();

    print_plans();

    print_suites();

    print_cases();

    print $h->close('main');
}

sub print_preamble() {
    print $h->open(section);
    print $h->a({name => 'preamble'});
    print $h->h2(sprintf('%d. Preamble', ++$section));

    print md2html($spec->{'Preamble'});

    print $h->close(section);
}

sub print_plans {
    print $h->a({name => 'test-plans'});
    print $h->h2(sprintf('%d. Test Plans', ++$section));

    my @plans = sort(
        { $plans->{$a}->{'Order'} <=> $plans->{$b}->{'Order'} }
        keys(%{$plans})
    );

    my $i = 0;
    foreach my $plan (@plans) {
        print $h->open(section);
        print $h->a({name => sprintf('Test-Plan-%s', $plan)});
        print $h->h3(sprintf('%u.%u. %s', $section, ++$i, e($plans->{$plan}->{'Name'})));

        print $h->h4(Description);
        print md2html($plans->{$plan}->{Description}, 3);

        print $h->h4('Test Suite(s) used in this Plan');

        print $h->open(ol);
        foreach my $suite (sort(@{$plans->{$plan}->{'Test-Suites'}})) {
            my $anchor = sprintf('#Test-Suite-%s', $suite);

            print $h->li($h->a(
                { href => $anchor },
                e($suites->{$suite}->{'Name'}),
            ));
        }
        print $h->close(ol);

        print $h->close(section);
    }
}

sub print_suites {
    print $h->a({name => 'test-suites'});
    print $h->h2(sprintf('%d. Test Suites', ++$section));

    my @suites = sort(
        { $suites->{$a}->{'Order'} <=> $suites->{$b}->{'Order'} }
        keys(%{$suites})
    );

    my $i = 0;
    foreach my $suite (@suites) {
        print $h->open(section);

        print $h->a({name => sprintf('Test-Suite-%s', $suite)});

        print $h->h3(e(sprintf(
            '%u.%d. %s',
            $section,
            ++$i,
            $suites->{$suite}->{'Name'} || $suite,
        )));

        print $h->h4('Test Suite Identifier');
        print $h->pre(e($suite));

        print $h->h4(Description);
        print md2html($suites->{$suite}->{Description}, 2) || $h->p('No information available.');

        print $h->h4('Test Cases(s) used in this Suite');

        print $h->open('ol');
        foreach my $case (sort @{$suites->{$suite}->{'Test-Cases'} || []}) {
            my $anchor = sprintf('#Test-Case-%s', $case);

            my $title;
            if ($cases->{$case}->{'Summary'}) {
                $title = sprintf('%s - %s', $case, $cases->{$case}->{'Summary'});

            } else {
                $title = $case;

            }

            print $h->li($h->a(
                { href => $anchor },
                e($title),
            ));
        }
        print $h->close('ol');

        print $h->close(section);
    }
}

sub print_cases {
    print $h->a({name => 'test-cases'});
    print $h->h2(sprintf('%d. Test Cases', ++$section));

    my $i = 0;
    foreach my $case (grep { length($_) > 0 && $_ !~ /^Doc/ } sort(keys(%{$cases}))) {
        print $h->open(section);

        print $h->a({name => sprintf('Test-Case-%s', $case)});

        if ($cases->{$case}->{'Summary'}) {
            print $h->h3(sprintf('%u.%u. %s - %s', $section, ++$i, e($case), e($cases->{$case}->{'Summary'})));

        } else {
            print $h->h3(sprintf('%u.%u. %s', $section, ++$i, e($case)));

        }

        print $h->h4('Test Case Identifier');
        print $h->pre(e($case));

        print $h->h4(Description);
        print md2html($cases->{$case}->{Description}, $section-3) || $h->p('No information available.');

        print $h->h4('Test Suite(s) this Test Case is used in:');
        print $h->open(ul);
        foreach my $suite (sort({ $suites->{$a}->{'Order'} <=> $suites->{$b}->{'Order'} } keys(%{$suites}))) {
            if (any { $_ eq $case } @{$suites->{$suite}->{'Test-Cases'} || []}) {
                print $h->li($h->a(
                    { href => sprintf('#Test-Suite-%s', $suite) },
                    e($suites->{$suite}->{'Name'}),
                ));
            }
        }
        print $h->close(ul);

        print $h->close(section);
    }
}

sub md2html {
    my ($md, $shift) = @_;

    return '' unless ($md);

    $shift = sprintf('--shift-heading-level-by=%u', $shift);

    my($out, $in);
    my $pid = open2($out, $in, qw(pandoc -f markdown -t html), $shift, '-');
    binmode($out, ':encoding(UTF-8)');
    binmode($in, ':encoding(UTF-8)');
    $in->print($md);
    close($in);
    my $html = <$out>;
    close($out);

    waitpid($pid, 0);

    return $html;
}

sub e { $h->entity_encode(shift) }

__DATA__
html,body,p,div,ol,li,table,tr,td,th,input,button,select,option,textarea,* {
    font-family: Helvetica, Arial, sans-serif;
    font-weight: 300;
    line-height: 150%;
}

a {
    color: #00c;
}

a:active,a:hover {
    color: #c4c;
}

.toc-link:active,.toc-link:hover {
    border: 1px solid #c4c;
}

header {
    text-align:center;
}

strong,h1,h2,h3,h4,h5,h6 {
    font-weight: 600;
}

header,nav,body,main,section {
    padding:0 1em;
    border-bottom: 0.125em solid #ccc;
}

body {
    margin: 0.5em 5em;
}

dl {
    margin: auto 2em;
}

dt {
    font-weight:bold;
}

dt:after {
    content: ":";
}

dd {
    margin-bottom: 1em;
}

code,tt,pre {
    font-family: "Courier New", Courier, monospace;
}

pre {
    margin: auto auto auto 2em;
}

.toc-link {
    position:fixed;
    margin:0;
    padding: 0.25em;
    border-radius: 0.25em;
    top:1em;
    right:3em;
    font-size:50%;
    display:inline-block;
    line-height:100%;
    text-decoration:none;
    border: 1px solid #00c;
}
