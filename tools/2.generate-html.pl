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
use JSON::XS;
use constant {
    'href'          => 'href',
    'ol'            => 'ol',
    'ul'            => 'ul',
    'li'            => 'li',
    'section'       => 'section',
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
my $inputs  = $spec->{'Input-Parameters'};

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

    print $h->open(li);
    print_input_parameter_toc_list();
    print $h->close(li);

    print $h->close(ol);
}

sub print_test_plan_toc_list {
    print $h->open('details');

    print $h->summary($h->a({href => '#test-plans'}, 'Test Plans'));

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

    print $h->close('details');
}

sub print_test_suite_toc_list {
    print $h->open('details');

    print $h->summary($h->a({href => '#test-cases'}, 'Test Suites'));

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

    print $h->close('details');
}

sub print_test_case_toc_list {
    print $h->open('details');

    print $h->summary($h->a({href => '#test-cases'}, 'Test Cases'));

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

    print $h->close('details');
}

sub print_input_parameter_toc_list {
    print $h->open('details');

    print $h->summary($h->a({href => '#input-parameters'}, 'Input Parameters'));

    print $h->open(ol);

    foreach my $input (sort(keys(%{$inputs}))) {
        my $anchor = sprintf('#Input-Parameter-%s', $input);

        print $h->li($h->a(
            {href => $anchor},
            e($input)
        ));
    }

    print $h->close(ol);

    print $h->close('details');
}

sub print_main {
    print $h->open('main');

    print_preamble();

    print_plans();

    print_suites();

    print_cases();

    print_inputs();

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

        print $h->h4('Plan ID');
        print $h->p('The following Test Plan ID may be used with the RST API:');
        print $h->pre(e($plan));

        print $h->h4('Description');
        print md2html($plans->{$plan}->{'Description'}, 3);

        print $h->h4('Test suites');
        print $h->p('This plan uses the following test suites:');

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

        print $h->h4('Description');
        print md2html($suites->{$suite}->{'Description'}, 2) || $h->p('No information available.');

        my %inputs;

        print $h->h4('Test cases');
        print $h->p('This suite uses the following test cases:');

        print $h->open('ol');

        my @cases;
        if ('ARRAY' eq ref($suites->{$suite}->{'Test-Cases'})) {
            @cases = sort @{$suites->{$suite}->{'Test-Cases'} || []};

        } else {
            @cases = sort grep { $_ =~ /$suites->{$suite}->{'Test-Cases'}/i } keys(%{$cases});

        }

        foreach my $case (@cases) {
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

            foreach my $input (sort(@{$cases->{$case}->{'Input-Parameters'} || []})) {
                $inputs{$input} = 1;
            }
        }
        print $h->close('ol');

        print $h->h4('Input parameters');
        print $h->p('The test cases used by this suite require the following input parameters:');

        print $h->open('ol');

        foreach my $input (sort(keys(%inputs))) {
            print $h->li($h->a(
                { href => sprintf('#Input-Parameter-%s', $input) },
                e($input),
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

        print $h->h4('Description');
        print md2html($cases->{$case}->{'Description'}, $section-3) || $h->p('No information available.');

        print $h->h4('Dependencies');
        print $h->p('This test case requires the following test cases to have successfully passed:');
        print $h->open(ul);
        foreach my $dep (sort(@{$cases->{$case}->{'Dependencies'} || []})) {
            my $title;
            if ($cases->{$dep}->{'Summary'}) {
                $title = sprintf('%s - %s', $dep, $cases->{$dep}->{'Summary'});

            } else {
                $title = $dep;

            }

            print $h->li($h->a(
                { href => sprintf('#Test-Case-%s', $dep) },
                e($title),
            ));
        }
        print $h->close(ul);

        print $h->h4('Dependants');
        print $h->p('The following test cases require this test case to have successfully passed:');
        print $h->open(ul);

        foreach my $dep (sort(keys(%{$cases}))) {
            if (any { $_ eq $case } @{$cases->{$dep}->{'Dependencies'} || []}) {
                my $title;
                if ($cases->{$dep}->{'Summary'}) {
                    $title = sprintf('%s - %s', $dep, $cases->{$dep}->{'Summary'});

                } else {
                    $title = $dep;

                }

                print $h->li($h->a(
                    { href => sprintf('#Test-Case-%s', $dep) },
                    e($title),
                ));
            }
        }
        print $h->close(ul);

        print $h->h4('Input parameters');
        print $h->p('This test case requires the following input parameters:');
        print $h->open(ul);
        foreach my $input (sort(@{$cases->{$case}->{'Input-Parameters'} || []})) {
            print $h->li($h->a(
                { href => sprintf('#Input-Parameter-%s', $input) },
                e($input),
            ));
        }
        print $h->close(ul);

        print $h->h4('Test suites');
        print $h->p('This test case is used in the following test suites:');

        print $h->open(ul);
        foreach my $suite (sort({ $suites->{$a}->{'Order'} <=> $suites->{$b}->{'Order'} } keys(%{$suites}))) {
            if ('ARRAY' eq ref($suites->{$suite}->{'Test-Cases'})) {
                if (any { $_ eq $case } @{$suites->{$suite}->{'Test-Cases'} || []}) {
                    print $h->li($h->a(
                        { href => sprintf('#Test-Suite-%s', $suite) },
                        e($suites->{$suite}->{'Name'}),
                    ));
                }
            } elsif ($case =~ /$suites->{$suite}->{'Test-Cases'}/i) {
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

sub print_inputs {
    print $h->a({name => 'input-parameters'});
    print $h->h2(sprintf('%d. Input Parameters', ++$section));

    my $i = 0;
    foreach my $input (sort(keys(%{$inputs}))) {
        print $h->open(section);

        print $h->a({name => sprintf('Input-Parameter-%s', $input)});

        print $h->h4('Description');
        print md2html($inputs->{$input}->{'Description'}, $section-3) || $h->p('No information available.');

        print $h->h4('Type');
        my $type = $inputs->{$input}->{'Type'};
        print $h->pre(e($type));

        print $h->h4('Example');
        my $value;
        if ('integer' eq $type) {
            $value = int($inputs->{$input}->{'Example'});

        } elsif ('number' eq $type) {
            $value = 0 + int($inputs->{$input}->{'Example'});

        } else {
            $value = $inputs->{$input}->{'Example'};

        }
        print $h->pre(e(JSON::XS->new->pretty->encode({$input => $value})));

        print $h->h4('Test cases');
        print $h->p('This input parameter is used in the following test cases:');

        print $h->open(ul);
        foreach my $case (sort(keys(%{$cases}))) {
            if (any { $_ eq $input } @{$cases->{$case}->{'Input-Parameters'}}) {
                my $title;
                if ($cases->{$case}->{'Summary'}) {
                    $title = sprintf('%s - %s', $case, $cases->{$case}->{'Summary'});

                } else {
                    $title = $case;

                }

                print $h->li($h->a(
                    { href => sprintf('#Test-Case-%s', $case) },
                    e($title),
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

    return '<div class="markdown-content">'.$html.'</div>';
}

sub e { $h->entity_encode(shift) }

__DATA__
html {
    background-color: #fefefe;
    font-size: 15px;
}
html,body,p,div,ol,li,table,tr,td,th,input,button,select,option,textarea,* {
    font-family: "Noto Sans", sans-serif;
    font-weight: normal;
    line-height: 1.5;
    color: #333333;
}

a {
    color: #036aa6;
}

a:active,a:hover {
    text-decoration: none;
}

header {
    text-align:center;
}

strong,h1,h2,h3,h4,h5,h6 {
    font-weight: 600;
}

header,nav,body,main,section {
    padding:0 1em;
    border-bottom: 0.0625em solid #ddd;
}

body {
    max-width: 70ch;
    margin: 0.5em auto;
    padding: 1em;
    background-color: #f6f6f6;
    border:1px solid #ddd;
    border-radius: 0.5em;
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
    font-family: "Fira Code", "Menlo", "Consolas", "Andale Mono", "Courier New", Courier, monospace;
}

pre,.markdown-content {
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
