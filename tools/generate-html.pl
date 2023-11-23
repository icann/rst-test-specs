#!perl
#
# this script takes the rst-spec.yaml file and generates an HTML version of it
#
# Usage: perl 2.generate-html.pl rst-test-specs.yaml > rst-test-specs.html
#
use File::Spec;
use File::Temp;
use File::Slurp;
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
use bytes;
use utf8;
use strict;

my $s = ICANN::RST::Spec->new($ARGV[0]);

my $h = HTML::Tiny->new;

my $j = JSON::XS->new->pretty->canonical;

my ($_DATA, $section);
while (<DATA>) {
    if (/^__(.+?)__$/) {
        $section = $1;

    } elsif ($section) {
        $_DATA->{$section} .= $_;

    }
}

my $section = 0;

binmode(STDOUT, ':encoding(UTF-8)');

print "<!doctype html>\n";
print $h->open('html');

my $title = 'Registry System Testing - Test Specifications';

print $h->head([
    $h->meta({'charset' => 'UTF-8'}),
    $h->meta({name => 'viewport', 'content' => 'width=device-width'}),
    $h->style($_DATA->{'CSS'}),
    $h->script($_DATA->{'SCRIPT'}),
    $h->title($title),
]);

print $h->open('body');

print_title();

print_nav();

print_main();

print_footer();

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

    print $h->li($h->a({href => '#meta'}, 'About this document'));

    print $h->open(li);
    print_test_plan_toc_list();
    print $h->close(li);

    print $h->open(li);
    print_test_suite_toc_list();
    print $h->close(li);

    print $h->open(li);
    print_resource_toc_list();
    print $h->close(li);

    print $h->open(li);
    print_test_case_toc_list();
    print $h->close(li);

    print $h->open(li);
    print_input_parameter_toc_list();
    print $h->close(li);

    print $h->open(li);
    print_error_toc_list();
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

sub print_resource_toc_list {
    print $h->open(details, {'open' => 1});

    print $h->summary($h->a({href => '#resources'}, 'Resources'));

    print $h->open(ol);

    foreach my $resource ($s->resources) {
        my $anchor = sprintf('#Resource-%s', $resource->id);

        print $h->li($h->a(
            { href => $anchor },
            e($resource->id)
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

sub print_error_toc_list {
    print $h->open(details, {'open' => 1});

    print $h->summary($h->a({href => '#errors'}, 'Errors'));

    print $h->open(ol);

    foreach my $error ($s->errors) {
        print $h->li($h->a(
            {href => sprintf('#Error-%s', $error->id)},
            sprintf(
                '%s (%s)',
                e($error->id),
                $h->code(e($error->severity)),
            )
        ));
    }

    print $h->close(ol);

    print $h->close(details);
}

sub print_main {
    print $h->open('main');

    print_preamble();

    print_meta();

    print_plans();

    print_suites();

    print_resources();

    print_cases();

    print_inputs();

    print_errors();

    print $h->close('main');
}

sub print_preamble() {
    print $h->open(section);
    print $h->a({name => 'preamble'});
    print $h->h2(sprintf('%d. Preamble', ++$section));

    print $s->preamble->html;

    print $h->close(section);
}

sub print_meta() {
    print $h->open(section);
    print $h->a({name => 'meta'});
    print $h->h2(sprintf('%d. About this document', ++$section));

    print ICANN::RST::Text->new($_DATA->{'META'})->html(2);

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

        print $h->h4('Description');
        print $plan->description->html(3);

        print $h->open(details, {'open' => 1});

        print $h->summary($h->h4('Plan ID'));
        print $h->p('The following Test Plan ID may be used with the RST API:');
        print $h->pre(e($plan->id));

        print $h->close(details);

        print $h->open(details, {'open' => 1});

        print $h->summary($h->h4('Test suites'));
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

        print $h->close(details);

        print $h->open(details, {'open' => 1});

        print $h->summary($h->h4('Resources'));
        print $h->p('The following resources may be required to prepare for this
                        test plan:');

        my @resources = $plan->resources;
        if (scalar(@resources) < 1) {
            print $h->ul($h->li($h->em('None specified.')));

        } else {
            print $h->open(ul);

            foreach my $resource (@resources) {
                print $h->li($h->a(
                    { href => sprintf('#Resource-%s', $resource->id) },
                    e($resource->id),
                ));
            }

            print $h->close(ul);
        }
        print $h->close(details);

        print $h->open(details, {'open' => 1});

        print $h->summary($h->h4('Errors'));
        print $h->p('This test plan may produce the following errors:');

        my @errors = $plan->errors;
        if (scalar(@errors) < 1) {
            print $h->ul($h->li($h->em('None specified.')));

        } else {
            print $h->open(ul);

            foreach my $error (@errors) {
                print $h->li($h->a(
                    { href => sprintf('#error-%s', $error->id) },
                    sprintf(
                        '%s (%s)',
                        e($error->id),
                        $h->code(e($error->severity)),
                    )
                ));
            }

            print $h->close(ul);
        }

        print $h->close(details);

        print $h->open(details, {'open' => 1});

        print $h->summary($h->h4('Input parameters'));
        print $h->p('This plan requires the following input parameters:');

        my %params;
        my @files;
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

                $params{$input->id} = $input->jsonExample;
                push(@files, $input) if ('file' eq $input->type);
            }

            print $h->close(ul);
        }

        print $h->close(details);

        print $h->open(details, {'open' => 1});

        print $h->summary($h->h4('Required files'));
        if (scalar(@files) < 1) {
            print $h->ul($h->li($h->em('None specified.')));

        } else {
            print $h->open(ul);
            foreach my $file (@files) {
                print $h->li($h->a(
                    { href => sprintf('#Input-Parameter-%s', $file->id) },
                    e($file->id),
                ));
            }
            print $h->close(ul);
        }

        print $h->close(details);

        print $h->open(details, {'open' => 1});

        print $h->summary($h->h4('RST-API example'));

        my $json = $j->encode(\%params);
        print $h->pre(e(sprintf(
            "POST /test/987654/inputs HTTP/1.1\n".
                "Content-Type: application/json\n".
                "Content-Length: %u\n\n".
                "%s",
            length($json),
            $json
        )));

        print $h->close(details);

        print $h->open(details, {'open' => 1});

        print $h->summary($h->h4('Sequence diagram'));

        my $file = File::Temp::tempnam(File::Spec->tmpdir, '').'.svg';
        $plan->graph->run('format' => 'svg', 'output_file' => $file);

        print read_file($file);

        unlink($file);

        print $h->close(details);

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

        print $h->open(details, {'open' => 1});

        print $h->summary($h->h4('Test plans'));
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

        print $h->close(details);

        print $h->open(details, {'open' => 1});
        print $h->summary($h->h4('Resources'));
        print $h->p('The following resources may be required to prepare for this
                        test plan:');

        my @resources = $suite->resources;
        if (scalar(@resources) < 1) {
            print $h->ul($h->li($h->em('None specified.')));

        } else {
            print $h->open(ul);

            foreach my $resource (@resources) {
                print $h->li($h->a(
                    { href => sprintf('#Resource-%s', $resource->id) },
                    e($resource->id),
                ));
            }

            print $h->close(ul);
        }

        print $h->close(details);

        print $h->open(details, {'open' => 1});

        print $h->summary($h->h4('Errors'));
        print $h->p('This test suite may produce the following errors:');

        my @errors = $suite->errors;
        if (scalar(@errors) < 1) {
            print $h->ul($h->li($h->em('None specified.')));

        } else {
            print $h->open(ul);

            foreach my $error (@errors) {
                print $h->li($h->a(
                    { href => sprintf('#error-%s', $error->id) },
                    sprintf(
                        '%s (%s)',
                        e($error->id),
                        $h->code(e($error->severity)),
                    )
                ));
            }

            print $h->close(ul);
        }

        print $h->close(details);

        print $h->open(details, {'open' => 1});

        print $h->summary($h->h4('Input parameters'));
        print $h->p('The test cases used by this suite require the following
                        input parameters:');

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

        print $h->close(details);

        print $h->open(details, {'open' => 1});

        print $h->summary($h->h4('Sequence diagram'));

        my $file = File::Temp::tempnam(File::Spec->tmpdir, '').'.svg';
        $suite->graph->run('format' => 'svg', 'output_file' => $file);

        print read_file($file);

        unlink($file);

        print $h->close(details);

        print $h->close(section);
    }
}

sub print_resources {
    print $h->a({name => 'resources'});
    print $h->h2(sprintf('%d. Resources', ++$section));

    my $i = 0;
    foreach my $resource ($s->resources) {
        print $h->open(section);

        print $h->a({name => sprintf('Resource-%s', $resource->id)});

        print $h->h3(sprintf('%u.%u. %s', $section, ++$i, e($resource->id)));

        print $h->h4('Description');
        print $resource->description->html($section-3);

        print $h->h4('URL');
        my $url = $resource->url->as_string;
        print $h->ul($h->li($h->a({href => $url}, e($url))));

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
            print $h->h3(sprintf(
                '%u.%u. %s - %s', $section, ++$i, e($case->id), e($summary)));

        } else {
            print $h->h3(sprintf('%u.%u. %s', $section, ++$i, e($case->id)));

        }

        print $h->h4('Description');
        print $case->description->html($section-3);

        print $h->open(details, {'open' => 1});

        print $h->summary($h->h4('Errors'));
        print $h->p('This test case may produce the following errors:');

        my @errors = $case->errors;
        if (scalar(@errors) < 1) {
            print $h->ul($h->li($h->em('None specified.')));

        } else {
            print $h->open(ul);

            foreach my $error (@errors) {
                print $h->li($h->a(
                    { href => sprintf('#error-%s', $error->id) },
                    sprintf(
                        '%s (%s)',
                        e($error->id),
                        $h->code(e($error->severity)),
                    )
                ));
            }

            print $h->close(ul);
        }

        print $h->close(details);

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

        print $h->open(details, {'open' => 1});
        print $h->summary($h->h4('Resources'));
        print $h->p('The following resources may be required to prepare for this
                        test plan:');

        my @resources = $case->resources;
        if (scalar(@resources) < 1) {
            print $h->ul($h->li($h->em('None specified.')));

        } else {
            print $h->open(ul);

            foreach my $resource (@resources) {
                print $h->li($h->a(
                    { href => sprintf('#Resource-%s', $resource->id) },
                    e($resource->id),
                ));
            }

            print $h->close(ul);
        }

        print $h->close(details);

        print $h->open(details, {'open' => 1});

        print $h->summary($h->h4('Dependencies'));
        print $h->p('This test case requires the following test cases to have
                        successfully passed:');

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

        print $h->close(details);

        print $h->open(details, {'open' => 1});

        print $h->summary($h->h4('Dependants'));
        print $h->p('The following test cases require this test case to have
                        successfully passed:');

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

        print $h->close(details);

        print $h->open(details, {'open' => 1});

        print $h->summary($h->h4('Test suites'));
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

        print $h->close(details);

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
        print $h->pre(e($j->encode({$input->id => $input->jsonExample})));

        print $h->open(details, {'open' => 1});

        print $h->summary($h->h4('Test cases'));
        print $h->p('This input parameter is used in the following test
                        cases:');

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

        print $h->close(details);

        print $h->close(section);
    }
}

sub print_errors {
    print $h->a({name => 'errors'});
    print $h->h2(sprintf('%d. Errors', ++$section));

    my $i = 0;
    foreach my $error ($s->errors) {
        print $h->open(section);

        print $h->a({name => sprintf('Error-%s', $error->id)});

        print $h->h4('Description');
        print $error->description->html($section-3);

        print $h->h4('Severity');
        print $h->pre(e($error->severity));

        print $h->close(section);
    }
}

sub print_footer {
    print $h->footer($h->p(e(sprintf(
        'Copyright %u %s.',
        substr($s->lastUpdated, 0, 4),
        $s->contactOrg
    ))));
}

sub e { $h->entity_encode(shift) }

__DATA__
__SCRIPT__
window.addEventListener('beforeprint', (event) => {
    var els = document.getElementsByTagName('details');
    for (var i = 0 ; i < els.length ; i++) {
        els.item(i).setAttribute('open', true);
    }
});

__META__
This document was automatically generated from the formal specification for the
RST system, which is available in
[YAML](https://github.com/icann/rst-test-specs/blob/master/rst-test-specs.yaml)
and
[JSON](https://github.com/icann/rst-test-specs/blob/master/rst-test-specs.json)
formats.

The schema for the formal specification can be found in
[Schema.md](https://github.com/icann/rst-test-specs/blob/master/Schema.md). The
YAML file is the normative reference, other representations are informational
only.

ICANN welcomes feedback and contributions from the community. Interested parties
are encouraged to [fork](https://github.com/icann/rst-test-specs/fork) the
repository and submit a [pull
request](https://github.com/icann/rst-test-specs/pulls).
__CSS__
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
    font-family: "Fira Code", "Menlo", "Consolas", "Andale Mono", "Courier New",
        Courier, monospace;
}

pre {
    margin: auto auto auto 2em;
}

summary {
    cursor: pointer;
}

summary h4 {
    display:inline;
    margin:0;
}

summary:has(> h4) {
    margin: 1em 0;
}

summary h4:active, summary h4:hover {
    text-decoration: underline;
    color: #036aa6;
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

svg {
    display:block;
    max-width:100%;
    max-height:100vh;
    margin:1em auto;
}

footer {
    text-align:center;
}
