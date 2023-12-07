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
use XML::LibXML;
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

my $spec = ICANN::RST::Spec->new($ARGV[0]);

my $json = JSON::XS->new->pretty->canonical;

my $h = HTML::Tiny->new;

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
        $_DATA->{'LOGO'},
        $h->h1($title),
        $h->p(sprintf('Version %s', e($spec->version))),
        $h->p(sprintf('Last Updated: %s', e($spec->lastUpdated))),
        $h->p($h->a(
            {href => 'mailto:'.$spec->contactEmail},
            e($spec->contactName.', '.$spec->contactOrg),
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

    print $h->open(li);
    print_preamble_toc_list();
    print $h->close(li);

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

    print $h->li($h->a({href => '#meta'}, 'About this document'));

    print $h->close(ol);
}

sub print_preamble_toc_list {
    print $h->open(details, {'open' => 1});

    print $h->summary($h->a({href => '#preamble'}, 'Preamble'));

    my $doc = XML::LibXML->load_html(
        'string'    => $spec->preamble->html,
        'encoding'  => 'UTF-8',
    );

    my @counts;
    my @els;
    for (my $i = 1 ; $i <= 6 ; $i++) {
        $counts[$i] = 0;
        @els = (@els, $doc->getElementsByTagName(sprintf('h%u', $i)));
    }

    my $md;

    my $level = 1;
    foreach my $el (sort { $a->textContent cmp $b->textContent } @els) {
        my $new = int(substr($el->localName, 1));

        $counts[$level] = 0 if ($new < $level);

        my $anchor = sprintf('#Preamble-%s', $el->textContent);
        $anchor =~ s/ /-/g;

        $md .= sprintf(
            "%s%u. [%s](%s)\n",
            ("\t" x ($new-1)),
            ++$counts[$new],
            substr($el->textContent, 1+index($el->textContent, ' ')),
            $anchor,
        );

        $level = $new;
    }

    print ICANN::RST::Text->new($md)->html;

    print $h->close(details);
}

sub print_test_plan_toc_list {
    print $h->open(details, {'open' => 1});

    print $h->summary($h->a({href => '#test-plans'}, 'Test Plans'));

    print $h->open(ol);

    foreach my $plan ($spec->plans) {
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

    foreach my $suite ($spec->suites) {
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

    foreach my $resource ($spec->resources) {
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

    foreach my $case ($spec->cases) {
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

    foreach my $input ($spec->inputs) {
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

    foreach my $error ($spec->errors) {
        print $h->li($h->a(
            {href => sprintf('#Error-%s', $error->id)},
            sprintf(
                '%s (%s)',
                $h->code(e($error->id)),
                e($error->severity),
            )
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

    print_resources();

    print_cases();

    print_inputs();

    print_errors();

    print_meta();

    print $h->close('main');
}

sub print_preamble() {
    print $h->open(section);
    print $h->a({name => 'preamble'});
    print $h->h2(sprintf('%d. Preamble', ++$section));

    my $doc = XML::LibXML->load_html(
        'string'    => $spec->preamble->html(2),
        'encoding'  => 'UTF-8',
    );

    for (my $i = 1 ; $i <= 6 ; $i++) {
        foreach my $el ($doc->getElementsByTagName(sprintf('h%u', $i))) {
            my $anchor = sprintf('Preamble-%s', $el->textContent);
            $anchor =~ s/ /-/g;

            my $a = $el->parentNode->insertBefore($doc->createElement('a'), $el);
            $a->setAttribute('name', $anchor);
        }
    }

    print $doc->toStringHTML;

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
    foreach my $plan ($spec->plans) {
        print $h->open(section);
        print_plan($plan, ++$i);
        print $h->close(section);
    }
}

sub print_plan {
    my ($plan, $i) = @_;

    print $h->a({name => sprintf('Test-Plan-%s', $plan->id)});
    print $h->h3(sprintf('%u.%u. %s', $section, $i, e($plan->name)));

    my $j = 0;

    print $h->h4(sprintf('%u.%u.%u. Description', $section, $i, ++$j));
    print $plan->description->html(3);

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Plan ID', $section, $i, ++$j)));
    print $h->p('The following Test Plan ID may be used with the RST API:');
    print $h->pre(e($plan->id));

    print $h->close(details);

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Test suites', $section, $i, ++$j)));
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

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Resources', $section, $i, ++$j)));
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

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Errors', $section, $i, ++$j)));
    print $h->p('This test plan may produce the following errors:');

    my @errors = $plan->errors;
    if (scalar(@errors) < 1) {
        print $h->ul($h->li($h->em('None specified.')));

    } else {
        print $h->open(ul);

        foreach my $error (@errors) {
            print $h->li($h->a(
                { href => sprintf('#Error-%s', $error->id) },
                sprintf(
                    '%s (%s)',
                    $h->code(e($error->id)),
                    e($error->severity),
                )
            ));
        }

        print $h->close(ul);
    }

    print $h->close(details);

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Input parameters', $section, $i, ++$j)));
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

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Required files', $section, $i, ++$j)));
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

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. RST-API example', $section, $i, ++$j)));

    my $jstr = $json->encode(\%params);
    print $h->pre(e(sprintf(
        "POST /test/987654/inputs HTTP/1.1\n".
            "Content-Type: application/json\n".
            "Content-Length: %u\n\n".
            "%s",
        length($jstr),
        $jstr
    )));

    print $h->close(details);

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Sequence diagram', $section, $i, ++$j)));

    my $file = File::Temp::tempnam(File::Spec->tmpdir, '').'.svg';
    $plan->graph->run('format' => 'svg', 'output_file' => $file);

    print read_file($file);

    unlink($file);

    print $h->close(details);
}

sub print_suites {
    print $h->a({name => 'test-suites'});
    print $h->h2(sprintf('%d. Test Suites', ++$section));

    my $i = 0;
    foreach my $suite ($spec->suites) {
        print $h->open(section);
        print_suite($suite, ++$i);
        print $h->close(section);
    }
}

sub print_suite {
    my ($suite, $i) = @_;

    print $h->a({name => sprintf('Test-Suite-%s', $suite->id)});

    print $h->h3(e(sprintf(
        '%u.%d. %s',
        $section,
        $i,
        $suite->name || $suite->id,
    )));

    my $j = 0;

    print $h->h4(sprintf('%u.%u.%u. Description', $section, $i, ++$j));
    print $suite->description->html(3);

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Test cases', $section, $i, ++$j)));
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

    print $h->close(details);

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Test plans', $section, $i, ++$j)));
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

    print $h->open(details);
    print $h->summary($h->h4(sprintf('%u.%u.%u. Resources', $section, $i, ++$j)));
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

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Errors', $section, $i, ++$j)));
    print $h->p('This test suite may produce the following errors:');

    my @errors = $suite->errors;
    if (scalar(@errors) < 1) {
        print $h->ul($h->li($h->em('None specified.')));

    } else {
        print $h->open(ul);

        foreach my $error (@errors) {
            print $h->li($h->a(
                { href => sprintf('#Error-%s', $error->id) },
                sprintf(
                    '%s (%s)',
                    $h->code(e($error->id)),
                    e($error->severity),
                )
            ));
        }

        print $h->close(ul);
    }

    print $h->close(details);

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Input parameters', $section, $i, ++$j)));
    print $h->p('The test cases used by this suite require the following input
                    parameters:');

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

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Sequence diagram', $section, $i, ++$j)));

    my $file = File::Temp::tempnam(File::Spec->tmpdir, '').'.svg';
    $suite->graph->run('format' => 'svg', 'output_file' => $file);

    print read_file($file);

    unlink($file);

    print $h->close(details);
}

sub print_resources {
    print $h->a({name => 'resources'});
    print $h->h2(sprintf('%d. Resources', ++$section));

    my $i = 0;
    foreach my $resource ($spec->resources) {
        print $h->open(section);
        print_resource($resource, ++$i);
        print $h->close(section);
    }
}

sub print_resource {
    my ($resource, $i) = @_;

    print $h->a({name => sprintf('Resource-%s', $resource->id)});

    print $h->h3(sprintf('%u.%u. %s', $section, $i, e($resource->id)));

    my $j = 0;

    print $h->h4(sprintf('%u.%u.%u. Description', $section, $i, ++$j));
    print $resource->description->html(3);

    print $h->h4(sprintf('%u.%u.%u. URL', $section, $i, ++$j));
    my $url = $resource->url->as_string;
    print $h->ul($h->li($h->a({href => $url}, e($url))));
}

sub print_cases {
    print $h->a({name => 'test-cases'});
    print $h->h2(sprintf('%d. Test Cases', ++$section));

    my $i = 0;
    foreach my $case ($spec->cases) {
        print $h->open(section);
        print_case($case, ++$i);
        print $h->close(section);
    }
}

sub print_case {
    my ($case, $i) = @_;

    print $h->a({name => sprintf('Test-Case-%s', $case->id)});

    my $summary = $case->summary;
    if ($summary) {
        print $h->h3(sprintf(
            '%u.%u. %s - %s', $section, $i, e($case->id), e($summary)));

    } else {
        print $h->h3(sprintf('%u.%u. %s', $section, $i, e($case->id)));

    }

    my $j = 0;

    print $h->h4(sprintf('%u.%u.%u. Description', $section, $i, ++$j));
    print $case->description->html(3);

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Errors', $section, $i, ++$j)));
    print $h->p('This test case may produce the following errors:');

    my @errors = $case->errors;
    if (scalar(@errors) < 1) {
        print $h->ul($h->li($h->em('None specified.')));

    } else {
        print $h->open(ul);

        foreach my $error (@errors) {
            print $h->li($h->a(
                { href => sprintf('#Error-%s', $error->id) },
                sprintf(
                    '%s (%s)',
                    $h->code(e($error->id)),
                    e($error->severity),
                )
            ));
        }

        print $h->close(ul);
    }

    print $h->close(details);

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Input parameters', $section, $i, ++$j)));
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
    print $h->close(details);

    print $h->open(details);
    print $h->summary($h->h4(sprintf('%u.%u.%u. Resources', $section, $i, ++$j)));
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

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Dependencies', $section, $i, ++$j)));
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

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Dependants', $section, $i, ++$j)));
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

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Test suites', $section, $i, ++$j)));
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
}

sub print_inputs {
    print $h->a({name => 'input-parameters'});
    print $h->h2(sprintf('%d. Input Parameters', ++$section));

    my $i = 0;
    foreach my $input ($spec->inputs) {
        print $h->open(section);
        print_input($input, ++$i);
        print $h->close(section);
    }
}

sub print_input {
    my ($input, $i) = @_;

    print $h->a({name => sprintf('Input-Parameter-%s', $input->id)});

    print $h->h3(sprintf('%u.%u. %s', $section, $i, e($input->id)));

    my $j = 0;

    print $h->h4(sprintf('%u.%u.%u. Description', $section, $i, ++$j));
    print $input->description->html(3);

    print $h->h4(sprintf('%u.%u.%u. Type', $section, $i, ++$j));
    print $h->pre(e($input->type));

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Example', $section, $i, ++$j)));
    print $h->pre(e($json->encode({$input->id => $input->jsonExample})));

    print $h->close(details);

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Test cases', $section, $i, ++$j)));
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

    print $h->close(details);
}

sub print_errors {
    print $h->a({name => 'errors'});
    print $h->h2(sprintf('%d. Errors', ++$section));

    my $i = 0;
    foreach my $error ($spec->errors) {
        print $h->open(section);
        print_error($error, ++$i);
        print $h->close(section);
    }
}

sub print_error {
    my ($error, $i) = @_;

    print $h->a({name => sprintf('Error-%s', $error->id)});

    print $h->h3(sprintf('%u.%u. %s', $section, $i, e($error->id)));

    my $j = 0;

    print $h->h4(sprintf('%u.%u.%u. Severity', $section, $i, ++$j));
    print $h->pre(e($error->severity));

    print $h->h4(sprintf('%u.%u.%u. Description', $section, $i, ++$j));
    print $error->description->html(3);
}

sub print_footer {
    print $h->footer($h->p(e(sprintf(
        'Copyright %u %s.',
        substr($spec->lastUpdated, 0, 4),
        $spec->contactOrg
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
are encouraged to [fork the
repository](https://github.com/icann/rst-test-specs/fork) and submit a [pull
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

code,tt {
    white-space:nowrap;
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

header svg {
    height: 5em;
    margin: 1em auto 0 auto;
}

main svg {
    display:block;
    max-width:100%;
    max-height:100vh;
    margin:1em auto;
}

footer {
    text-align:center;
}

table {
    width:100%;
}

th {
    font-weight:bold;
}

__LOGO__

<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 259.69 207.3">
  <defs>
    <clipPath id="a">
      <path d="m204.75 581.6h211.3v169.4h-211.3v-169.4"/>
    </clipPath>
    <clipPath id="b">
      <path d="m204.75 751h211.52v-169.64h-211.52v169.64"/>
    </clipPath>
    <clipPath id="c">
      <path d="m204.75 751v-169.4h215.5v169.4h-215.5"/>
    </clipPath>
  </defs>
  <g transform="translate(-228.8 -344.37)">
    <g transform="matrix(1.25 0 0 -1.25 -30.054 1281.3)">
      <g clip-path="url(#c)">
        <g clip-path="url(#b)">
          <path d="m242.37 609.75h-14.706v-4.437h4.113v-16.2h-4.113v-4.446h14.706v4.446h-4.122v16.2h4.122v4.437" fill="#274a5b"/>
          <path d="m266.52 610.24c-1.908 0-3.672-0.30604-5.283-0.909-1.611-0.60303-2.961-1.467-4.05-2.583-1.134-1.152-1.998-2.538-2.592-4.158-0.59401-1.62-0.89101-3.42-0.89101-5.409 0-2.133 0.315-4.014 0.936-5.643 0.62101-1.629 1.503-2.988 2.637-4.077 1.134-1.089 2.484-1.917 4.059-2.466 1.584-0.54901 3.303-0.81903 5.166-0.81903 1.251 0 2.241 0.054 2.961 0.17999 0.72 0.12604 1.485 0.30603 2.304 0.54004 0.63 0.17999 1.233 0.396 1.8 0.63898 0.57598 0.25201 1.179 0.513 1.8 0.79199v5.994h-0.66598c-0.306-0.27002-0.693-0.58502-1.161-0.95398-0.47699-0.36902-0.98999-0.711-1.539-1.035-0.64798-0.40497-1.359-0.71998-2.124-0.95398-0.77398-0.23401-1.548-0.35102-2.331-0.35102-0.819 0-1.656 0.12598-2.493 0.396-0.84601 0.26098-1.602 0.70202-2.295 1.314-0.66601 0.612-1.224 1.44-1.674 2.493-0.44101 1.053-0.66601 2.367-0.66601 3.933 0 1.503 0.207 2.781 0.621 3.834 0.405 1.053 0.94501 1.899 1.602 2.538 0.702 0.66601 1.458 1.134 2.277 1.422 0.819 0.28802 1.683 0.432 2.592 0.432 0.819 0 1.584-0.12597 2.304-0.36902 0.72001-0.24298 1.386-0.54901 2.007-0.90899 0.603-0.35102 1.143-0.71997 1.62-1.089s0.87301-0.68402 1.188-0.95398h0.738v6.084c-0.45898 0.22498-0.98999 0.46802-1.602 0.72901-0.612 0.27002-1.296 0.50396-2.043 0.71997-0.72 0.18902-1.503 0.34204-2.349 0.45904-0.85502 0.11701-1.8 0.18-2.853 0.18" fill="#274a5b"/>
          <path d="m301.56 609.75h-7.443l-9.261-25.083h6.525l1.746 5.058h9.279l1.737-5.058h6.678l-9.261 25.083m-6.876-15.417 3.078 8.973 3.078-8.973h-6.156" fill="#274a5b"/>
          <path d="m344.79 609.75h-5.94v-14.364l-9.153 14.364h-7.74v-25.083h5.94v17.217l10.647-17.217h6.246v25.083" fill="#274a5b"/>
          <g clip-path="url(#a)" fill="#274a5b">
            <path d="m381.54 609.75h-5.94v-14.364l-9.153 14.364h-7.74v-25.083h5.94v17.217l10.647-17.217h6.246v25.083"/>
            <path d="m312.02 748.42c-3.8451-1.2e-4 -7.7645-0.39001-11.709-1.1769-6.552-1.458-12.339-4.599-18.135-7.794-19.107-9.36-31.284-29.007-29.601-50.274l9.306 2.7c-1.134 14.994 2.925 28.314 12.285 39.186 5.688-30.195 17.973-57.636 36.261-82.647 1.6699-0.10748 3.2862-0.2149 4.889-0.2149 1.6194 0 3.2252 0.10968 4.858 0.43988-6.444 6.489-11.583 13.473-16.785 20.457 7.956 3.627 16.02 7.362 23.22 12.447-0.97199 2.43-1.674 5.085-2.916 7.254-7.578-5.742-15.426-10.719-23.814-14.454-3.897 5.841-7.254 11.853-10.503 17.919v0.594c8.928 3.627 17.532 8.118 25.542 14.013-1.404 2.601-2.916 5.31-4.491 7.632-7.524-5.841-15.264-11.259-23.382-15.588h-0.81c-4.923 10.449-8.82 21.384-11.691 32.742 2.655 2.979 5.688 5.85 8.766 8.172l8.991 2.547c22.617-25.38 37.341-54.18 45.405-85.347 2.115 2.106 4.005 4.383 4.491 7.191-1.566 4.392-2.7 8.883-4.707 13.05-1.026 3.087-3.033 5.949-3.681 8.982 5.904 4.329 11.583 9.036 17.154 14.238-0.108 3.897-1.08 7.461-2.916 10.71h-0.432c-5.472-6.165-11.691-12.177-17.919-17.37-3.357 5.463-6.444 11.043-10.116 16.398 6.273 4.761 12.339 10.503 17.91 16.56-1.998 2.601-4.599 5.364-7.578 6.39-4.761-5.31-10.116-10.881-15.588-15.372-6.597 8.388-13.743 16.722-21.645 24.354 3.2175 0.729 6.8828 1.0935 10.542 1.0935 3.6596 0 7.3136-0.3645 10.509-1.0935 18.621-3.357 36.747-21.645 39.726-40.32 3.951-20.889-3.519-40.104-20.619-52.821-6.0596-2.1978-12.52-3.3118-18.957-3.3118-13.86 0-27.604 5.1683-36.951 15.813 6.489 1.08 12.663 3.033 18.891 5.0309-0.927 1.566-2.061 3.033-2.763 4.707-17.2-6.9091-35.946-10.885-55.713-10.885-2.3774 0-4.773 0.0576-7.179 0.1745 6.7313-0.86554 13.604-1.2413 20.52-1.2413 4.3743 0 8.766 0.15039 13.149 0.42236 4.599-5.733 10.44-10.332 16.398-13.635 6.7947-3.7817 15.237-5.6669 23.738-5.6669 10.112 0 20.306 2.6691 27.894 7.9889 8.55 3.627 16.776 10.017 22.563 18.135 10.935 13.968 12.609 37.017 4.491 52.821l-3.51 6.012c-10.236 15.141-26.08 23.039-43.389 23.038"/>
          </g>
          <path d="m280.99 695.99c-15.048-7.029-31.284-11.304-48.708-12.663 1.1884-0.0182 2.3782-0.0272 3.5672-0.0272 5.844 0 11.662 0.21741 17.106 0.62128 1.134-6.867 3.465-13.311 7.2-19.098 3.897 0.75599 7.794 1.404 11.466 2.538-3.294 4.383-5.625 9.261-7.353 14.4-0.27002 1.242-1.197 2.709-0.43201 3.897 6.705 1.2419 13.257 2.763 19.476 5.085l-2.322 5.247" fill="#274a5b"/>
          <path d="m310.57 625.63c-35.46-7.9e-4 -70.956-3.4794-103.24-10.334 32.38 3.5225 66.211 5.1816 100.08 5.1816 35.879-7e-5 71.8-1.8621 106.07-5.3436-32.148 7.032-67.51 10.497-102.91 10.496" fill="#274a5b"/>
        </g>
      </g>
    </g>
  </g>
</svg>
