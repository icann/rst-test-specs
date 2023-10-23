#!perl
#
# this script takes the rst-spec.yaml file and generates an HTML version of it
#
# Usage: perl 2.generate-html.pl rst-test-specs.yaml > rst-test-specs.html
#
use HTML::Tiny;
use JSON::XS;
use ICANN::RST::Spec;
use constant {
    'href'          => 'href',
    'ol'            => 'ol',
    'ul'            => 'ul',
    'li'            => 'li',
    'section'       => 'section',
    'name'          => 'name',
    'details'       => 'details',
};
use utf8;
use strict;

my $s = ICANN::RST::Spec->new($ARGV[0]);

my $h = HTML::Tiny->new;

my $section = 0;

binmode(STDOUT, ':encoding(UTF-8)');

print "<!doctype html>\n";
print $h->open('html');

undef $/;

my $title = 'Registry System Testing - Test Specifications';

print $h->head([
    $h->meta({'charset' => 'UTF-8'}),
    $h->meta({name => 'viewport', 'content' => 'width=device-width'}),
    $h->style(<DATA>),
    $h->title($title),
]);

print $h->open('body');

print_title();

print_nav();

print_main();

print $h->close('body');
print $h->close('html');

sub print_title {
    print $h->header([
        $h->h1($title),
        $h->p(sprintf('Version %s', e($s->version))),
        $h->p(sprintf('Last Updated: %s', e($s->lastUpdated))),
        $h->p($h->a(
            {href => 'mailto:'.$s->contactEmail},
            e($s->contactName.', '.$s->contactOrg),
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
    print $h->open(details, {'open' => 1});

    print $h->summary($h->a({href => '#test-plans'}, 'Test Plans'));

    print $h->open(ol);

    foreach my $plan ($s->plans) {
        my $anchor = sprintf('#Test-Plan-%s', $plan->id);

        print $h->li($h->a(
            { href => $anchor },
            e($plan->name)
        ));
    }

    print $h->close(ol);

    print $h->close(details);
}

sub print_test_suite_toc_list {
    print $h->open(details, {'open' => 1});

    print $h->summary($h->a({href => '#test-suites'}, 'Test Suites'));

    print $h->open(ol);

    foreach my $suite ($s->suites) {
        my $anchor = sprintf('#Test-Suite-%s', $suite->id);

        print $h->li($h->a(
            { href => $anchor },
            e($suite->name)
        ));
    }

    print $h->close(ol);

    print $h->close(details);
}

sub print_test_case_toc_list {
    print $h->open(details, {'open' => 1});

    print $h->summary($h->a({href => '#test-cases'}, 'Test Cases'));

    print $h->open(ol);

    foreach my $case ($s->cases) {
        print $h->li($h->a(
            {href => sprintf('#Test-Case-%s', $case->id)},
            e($case->title)
        ));
    }

    print $h->close(ol);

    print $h->close(details);
}

sub print_input_parameter_toc_list {
    print $h->open(details, {'open' => 1});

    print $h->summary($h->a({href => '#input-parameters'}, 'Input Parameters'));

    print $h->open(ol);

    foreach my $input ($s->inputs) {
        print $h->li($h->a(
            {href => sprintf('#Input-Parameter-%s', $input->id)},
            e(sprintf('%s (%s)', $input->id, $input->type)),
        ));
    }

    print $h->close(ol);

    print $h->close(details);
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

    print $s->preamble->html;

    print $h->close(section);
}

sub print_plans {
    print $h->a({name => 'test-plans'});
    print $h->h2(sprintf('%d. Test Plans', ++$section));

    my $i = 0;
    foreach my $plan ($s->plans) {
        print $h->open(section);
        print $h->a({name => sprintf('Test-Plan-%s', $plan->id)});
        print $h->h3(sprintf('%u.%u. %s', $section, ++$i, e($plan->name)));

        print $h->h4('Plan ID');
        print $h->p('The following Test Plan ID may be used with the RST API:');
        print $h->pre(e($plan->id));

        print $h->h4('Description');
        print $plan->description->html(3);

        print $h->h4('Test suites');
        print $h->p('This plan uses the following test suites:');

        my @suites = $plan->suites;
        if (scalar(@suites) < 1) {
            print $h->ul($h->li($h->em('None specified.')));

        } else {
            print $h->open(ol);

            foreach my $suite (@suites) {
                print $h->li($h->a(
                    { href => sprintf('#Test-Suite-%s', $suite->id) },
                    e($suite->name),
                ));
            }

            print $h->close(ol);
        }

        print $h->h4('Input parameters');
        print $h->p('This plan requires the following input parameters:');

        my @inputs = $plan->inputs;
        if (scalar(@inputs) < 1) {
            print $h->ul($h->li($h->em('None specified.')));

        } else {
            print $h->open(ul);

            foreach my $input (@inputs) {
                print $h->li($h->a(
                    { href => sprintf('#Input-Parameter-%s', $input->id) },
                    e(sprintf('%s (%s)', $input->id, $input->type)),
                ));
            }

            print $h->close(ul);
        }

        print $h->close(section);
    }
}

sub print_suites {
    print $h->a({name => 'test-suites'});
    print $h->h2(sprintf('%d. Test Suites', ++$section));

    my $i = 0;
    foreach my $suite ($s->suites) {
        print $h->open(section);

        print $h->a({name => sprintf('Test-Suite-%s', $suite->id)});

        print $h->h3(e(sprintf(
            '%u.%d. %s',
            $section,
            ++$i,
            $suite->name || $suite->id,
        )));

        print $h->h4('Description');
        print $suite->description->html(2);

        print $h->h4('Test plans');
        print $h->p('This suite is used by the following test plans:');

        my @plans = $suite->plans;
        if (scalar(@plans) < 1) {
            print $h->ul($h->li($h->em('None specified.')));

        } else {
            print $h->open('ol');

            foreach my $plan (@plans) {
                print $h->li($h->a(
                    { href => sprintf('#Test-Plan-%s', $plan->id) },
                    e($plan->name),
                ));
            }

            print $h->close('ol');
        }

        print $h->h4('Test cases');
        print $h->p('This suite uses the following test cases:');

        my @cases = $suite->cases;
        if (scalar(@cases) < 1) {
            print $h->ul($h->li($h->em('None specified.')));

        } else {
            print $h->open('ol');

            foreach my $case (@cases) {
                print $h->li($h->a(
                    { href => sprintf('#Test-Case-%s', $case->id) },
                    e($case->title),
                ));
            }

            print $h->close('ol');
        }

        print $h->h4('Input parameters');
        print $h->p('The test cases used by this suite require the following input parameters:');

        my @inputs = $suite->inputs;
        if (scalar(@inputs) < 1) {
            print $h->ul($h->li($h->em('None specified.')));

        } else {
            print $h->open('ol');

            foreach my $input (@inputs) {
                print $h->li($h->a(
                    { href => sprintf('#Input-Parameter-%s', $input->id) },
                    e(sprintf('%s (%s)', $input->id, $input->type)),
                ));
            }

            print $h->close('ol');
        }

        print $h->close(section);
    }
}

sub print_cases {
    print $h->a({name => 'test-cases'});
    print $h->h2(sprintf('%d. Test Cases', ++$section));

    my $i = 0;
    foreach my $case ($s->cases) {
        print $h->open(section);

        print $h->a({name => sprintf('Test-Case-%s', $case->id)});

        my $summary = $case->summary;
        if ($summary) {
            print $h->h3(sprintf('%u.%u. %s - %s', $section, ++$i, e($case->id), e($summary)));

        } else {
            print $h->h3(sprintf('%u.%u. %s', $section, ++$i, e($case->id)));

        }

        print $h->h4('Description');
        print $case->description->html($section-3);

        print $h->h4('Dependencies');
        print $h->p('This test case requires the following test cases to have successfully passed:');

        my @deps = $case->dependencies;
        if (scalar(@deps) < 1) {
            print $h->ul($h->li($h->em('None specified.')));

        } else {
            print $h->open(ul);

            foreach my $dep (@deps) {
                print $h->li($h->a(
                    { href => sprintf('#Test-Case-%s', $dep->id) },
                    e($dep->title),
                ));
            }

            print $h->close(ul);
        }

        print $h->h4('Dependants');
        print $h->p('The following test cases require this test case to have successfully passed:');

        my @deps = $case->dependants;
        if (scalar(@deps) < 1) {
            print $h->ul($h->li($h->em('None specified.')));

        } else {
            print $h->open(ul);

            foreach my $dep (@deps) {
                print $h->li($h->a(
                    { href => sprintf('#Test-Case-%s', $dep->id) },
                    e($dep->title),
                ));
            }

            print $h->close(ul);
        }

        print $h->h4('Input parameters');
        print $h->p('This test case requires the following input parameters:');

        my @inputs = $case->inputs;
        if (scalar(@inputs) < 1) {
            print $h->ul($h->li($h->em('None specified.')));

        } else {
            print $h->open(ul);

            foreach my $input (@inputs) {
                print $h->li($h->a(
                    { href => sprintf('#Input-Parameter-%s', $input->id) },
                    e(sprintf('%s (%s)', $input->id, $input->type)),
                ));
            }

            print $h->close(ul);
        }

        print $h->h4('Test suites');
        print $h->p('This test case is used in the following test suites:');

        my @suites = $case->suites;
        if (scalar(@suites) < 1) {
            print $h->ul($h->li($h->em('None specified.')));

        } else {
            print $h->open(ul);

            foreach my $suite (@suites) {
                print $h->li($h->a(
                    { href => sprintf('#Test-Suite-%s', $suite->id) },
                    e($suite->name),
                ));
            }

            print $h->close(ul);
        }

        print $h->close(section);
    }
}

sub print_inputs {
    print $h->a({name => 'input-parameters'});
    print $h->h2(sprintf('%d. Input Parameters', ++$section));

    my $i = 0;
    foreach my $input ($s->inputs) {
        print $h->open(section);

        print $h->a({name => sprintf('Input-Parameter-%s', $input->id)});

        print $h->h4('Description');
        print $input->description->html($section-3);

        print $h->h4('Type');
        print $h->pre(e($input->type));

        print $h->h4('Example');
        my $value;
        if ('integer' eq $input->type) {
            $value = int($input->example);

        } elsif ('number' eq $input->type) {
            $value = 0 + int($input->example);

        } elsif ('boolean' eq $input->type) {
            $value = ($input->example ? \1 : \0);

        } else {
            $value = $input->example;

        }
        print $h->pre(e(JSON::XS->new->pretty->encode({$input->id => $value})));

        print $h->h4('Test cases');
        print $h->p('This input parameter is used in the following test cases:');

        my @cases = $input->cases;
        if (scalar(@cases) < 1) {
            print $h->ul($h->li($h->em('None specified.')));

        } else {
            print $h->open(ul);

            foreach my $case (@cases) {
                print $h->li($h->a(
                    { href => sprintf('#Test-Case-%s', $case->id) },
                    e($case->title),
                ));
            }
        
            print $h->close(ul);
        }

        print $h->close(section);
    }
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

body {
    margin: 0.5em 5em;
    padding: 1em;
    background-color: #f6f6f6;
    border:1px solid #ddd;
    border-radius: 0.5em;
}

header,nav,main,section {
    margin:0;
    padding:0;
    border-bottom: 0.0625em solid #ddd;
}

h2 {
    break-before: page;
}

section {
    break-inside: avoid;
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
