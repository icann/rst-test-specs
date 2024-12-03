#!/usr/bin/env perl
#
# this script takes the rst-spec.yaml file and generates an HTML version of it
#
# Usage: generate-html.pl SRC > DST
#
use File::Basename;
use File::Spec;
use File::Temp;
use File::Slurp;
use HTML::Tiny;
use JSON::XS;
use ICANN::RST::Spec;
use XML::LibXML;
use YAML::XS;
use constant {
    'href'          => 'href',
    'ol'            => 'ol',
    'ul'            => 'ul',
    'li'            => 'li',
    'section'       => 'section',
    'name'          => 'name',
    'details'       => 'details',
};
use feature qw(say);
use bytes;
use utf8;
use strict;

my $spec = ICANN::RST::Spec->new($ARGV[0]);

my $json = JSON::XS->new->pretty->canonical;

my $h = HTML::Tiny->new;

my $mdesc = {
    'ALPHA'     => 'rough outline, more work needed',
    'BETA'      => 'complete but likely to require further changes',
    'GAMMA'     => 'finalized and ready for review',
};

my $sdev = {
    'WARNING'   => ICANN::RST::Text->new('an issue which does not prevent the test from *passing*, but which may benefit from further investigation.')->raw_html,
    'ERROR'     => ICANN::RST::Text->new('an issue which prevents the test case from *passing*, but does not prevent the test case from *continuing*. A test case may produce multiple `ERROR` results.')->raw_html,
    'CRITICAL'  => ICANN::RST::Text->new('an issue which prevents the test case from continuing any further. A test case will only produce a single `CRITICAL` result and it will always be the last result in the log.')->raw_html,
};
foreach my $s (keys(%{$sdev})) {
    chomp($sdev->{$s});
    $sdev->{$s} =~ s/^<p>//;
    $sdev->{$s} =~ s/<\/p>$//;
}

my %API_SERVERS = (
    'OT&E' => 'rst-api-ote.icann.org',
    'Production' => 'rst-api.icann.org',
);

my $assets = File::Spec->catdir(dirname($ARGV[0]), qw(inc html));

my $section = 0;

binmode(STDOUT, ':encoding(UTF-8)');

print "<!doctype html>\n";
print $h->open('html', {'lang' => 'en'});

my $title = 'Registry System Testing - Test Specifications';

print $h->head([
    $h->meta({'charset' => 'UTF-8'}),
    $h->meta({name => 'viewport', 'content' => 'width=device-width'}),
    $h->style(join('', read_file(File::Spec->catfile($assets, 'style.css')))),
    $h->script(join('', read_file(File::Spec->catfile($assets, 'script.js')))),
    $h->title($title),
]);

say STDERR 'wrote header';

print $h->open('body');

print_title();

print_nav();

print_main();

print_footer();

print $h->close('body');
print $h->close('html');

say STDERR 'done';

exit(0);

sub print_title {
    print $h->header([
        join('', read_file(File::Spec->catfile($assets, 'icann-logo.svg'))),
        $h->h1($title),
        $h->p(sprintf('Version %s', e($spec->version))),
        $h->p(sprintf('Last Updated: %s', e($spec->lastUpdated))),
        $h->p($h->a(
            {href => 'mailto:'.$spec->contactEmail},
            e($spec->contactName.', '.$spec->contactOrg),
        )),
    ]);

    say STDERR 'wrote title';
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

    say STDERR 'wrote nav';
}

sub print_toc {
    print $h->a({name => 'table-of-contents'});
    print $h->h2(sprintf('%u. Table of Contents', ++$section));

    print $h->open(ol);

    print $h->li($h->a({href => '#table-of-contents'}, 'Table of Contents'));

    print $h->li($h->a({href => '#change-log'}, 'Change Log'));

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

    print $h->open(li);
    print_provider_toc_list();
    print $h->close(li);

    print $h->li($h->a({href => '#meta'}, 'About this document'));

    print $h->close(ol);

    say STDERR 'wrote toc';
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
            e($plan->name. ($plan->oteOnly ? ' (OT&E only)' : ''))
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
            e($case->title),
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
                e($error->id),
                e($error->severity),
            )
        ));
    }

    print $h->close(ol);

    print $h->close(details);
}

sub print_provider_toc_list {
    print $h->open(details, {'open' => 1});

    print $h->summary($h->a({href => '#data-providers'}, 'Data Providers'));

    print $h->open(ol);

    foreach my $provider ($spec->providers) {
        print $h->li($h->a(
            {href => sprintf('#Data-Provider-%s', $provider->id)},
            e($provider->id),
        ));
    }

    print $h->close(ol);

    print $h->close(details);
}

sub print_main {
    print $h->open('main');

    print_change_log();

    print_preamble();

    print_plans();

    print_suites();

    print_resources();

    print_cases();

    print_inputs();

    print_errors();

    print_providers();

    print_meta();

    print $h->close('main');
}

sub print_change_log {
    print $h->open(section);
    print $h->a({name => 'change-log'});
    print $h->h2(sprintf('%d. Change Log', ++$section));

    my $i = 0;
    foreach my $log ($spec->changelog) {
        undef($log->{'spec'});

        my $dt = $log->date;

        print $h->open(section);
        print $h->h3(sprintf('%d.%s. %s, %s %u, %04u', $section, ++$i, $dt->day_name, $dt->month_name, $dt->day, $dt->year));

        print $h->open(ol);
        foreach my $change ($log->changes) {
            print $h->open(li);
            my $doc = XML::LibXML->load_html('string' => $change->html);
            foreach my $el ($doc->getElementsByTagName('div')->item(0)->childNodes) {
                print $el->toString;
            }
            print $h->close(li);
        }
        print $h->close(ol);

        print $h->close(section);
    }

    print $h->close(section);

    say STDERR 'wrote change log';
}

sub print_preamble {
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

    say STDERR 'wrote preamble';
}

sub print_meta {
    print $h->open(section);
    print $h->a({name => 'meta'});
    print $h->h2(sprintf('%d. About this document', ++$section));

    print ICANN::RST::Text->new(join('', read_file(File::Spec->catfile($assets, 'meta.md'))))->html(2);

    print $h->close(section);

    say STDERR 'wrote meta';
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

    say STDERR 'wrote plans';
}

sub print_plan {
    my ($plan, $i) = @_;

    print $h->a({name => sprintf('Test-Plan-%s', $plan->id)});
    print $h->h3(sprintf('%u.%u. %s', $section, $i, e($plan->name . ($plan->oteOnly ? ' (OT&E only)' : ''))));

    my $j = 0;

    print $h->h4(sprintf('%u.%u.%u. Description', $section, $i, ++$j));

    if ($plan->oteOnly) {
        print $h->p($h->em(
            $h->strong('Note:'). ' this plan is only available in the OT&E environment.',
        ));
    }

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
                    e($error->id),
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

    print $h->summary($h->h4(sprintf('%u.%u.%u. Implementation status', $section, $i, ++$j)));

    print $h->p(sprintf(
        'As of the publication of this document, <strong>%u%%</strong> of the test cases in this plan have been implemented in the RST system.',
        100 * $plan->implemented
    ));

    print $h->close(details);

=pod

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Sequence diagram', $section, $i, ++$j)));

    my $file = File::Temp::tempnam(File::Spec->tmpdir, '').'.svg';
    $plan->graph->run('format' => 'svg', 'output_file' => $file);

    print read_file($file);

    unlink($file);

    print $h->close(details);

=cut

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

    say STDERR 'wrote suites';
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
                    e($error->id),
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

    print $h->summary($h->h4(sprintf('%u.%u.%u. Implementation status', $section, $i, ++$j)));

    print $h->p(sprintf(
        'As of the publication of this document, <strong>%u%%</strong> of the test cases in this suite have been implemented in the RST system.',
        100 * $suite->implemented
    ));

    print $h->close(details);

=pod

This is disabled until it becomes meaningful.

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Sequence diagram', $section, $i, ++$j)));

    my $file = File::Temp::tempnam(File::Spec->tmpdir, '').'.svg';
    $suite->graph->run('format' => 'svg', 'output_file' => $file);

    print read_file($file);

    unlink($file);

    print $h->close(details);

=cut

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

    say STDERR 'wrote resources';
}

sub print_resource {
    my ($resource, $i) = @_;

    print $h->a({name => sprintf('Resource-%s', $resource->id)});

    print $h->h3(sprintf('%u.%u. %s', $section, $i, e($resource->id)));

    my $j = 0;

    print $h->h4(sprintf('%u.%u.%u. Description', $section, $i, ++$j));
    print $resource->description->html(3);

    print $h->h4(sprintf('%u.%u.%u. URL', $section, $i, ++$j));

    my $url = $resource->url;
    if ($API_SERVERS{'Production'} ne lc($url->host)) {
        print $h->ul($h->li($h->a({href => $url->as_string}, e($url->as_string))));

    } else {
        print $h->p(e('This resource has different contents for different environments:'));

        print $h->open(ul);

        foreach my $env (sort(keys(%API_SERVERS))) {
            $url->host($API_SERVERS{$env});
            print $h->li([e($env.': '), $h->a({href => $url->as_string}, e($url->as_string))]);
        }

        print $h->close(ul);
    }
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

    say STDERR 'wrote cases';
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

=pod

This is no longer really meaningful.

    print $h->h4(sprintf('%u.%u.%u. Maturity Level', $section, $i, ++$j));
    print $h->ul($h->li([$h->strong($case->maturity.': '), $mdesc->{$case->maturity}]));

=cut

    print $h->h4(sprintf('%u.%u.%u. Implementation status', $section, $i, ++$j));
    print $h->ul($h->li(sprintf('This test <strong>%s</strong> been implemented in the RST system.', $case->implemented ? 'has' : 'has not yet')));

    print $h->h4(sprintf('%u.%u.%u. Description', $section, $i, ++$j));
    print $case->description->html(4);

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
                    e($error->id),
                    e($error->severity),
                )
            ));
        }

        print $h->close(ul);
    }

    print $h->close(details);

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Input parameters', $section, $i, ++$j)));
    print $h->p('This test case requires the following input parameters, in
        addition to those defined in the test suite:');

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

    print $h->summary($h->h4(sprintf('%u.%u.%u. Data providers', $section, $i, ++$j)));
    print $h->p('This test case uses the following data providers(s):');

    my @providers = $case->providers;
    if (scalar(@providers) < 1) {
        print $h->ul($h->li($h->em('None specified.')));

    } else {
        print $h->open(ul);

        foreach my $provider (@providers) {
            print $h->li($h->a(
                { href => sprintf('#Data-Provider-%s', $provider->id) },
                e($provider->id),
            ));
        }

        print $h->close(ul);
    }

    print $h->close(details);

    print $h->open(details);
    print $h->summary($h->h4(sprintf('%u.%u.%u. Resources', $section, $i, ++$j)));
    print $h->p('The following resources may be required to prepare for this
                    test case, in addition to those defined in the test
                    suite:');

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

=pod

This is disabled until it becomes meaningful.

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

=cut

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Test suites', $section, $i, ++$j)));
    print $h->p('This test case is used in the following test suite(s):');

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

    say STDERR 'wrote inputs';
}

sub print_input {
    my ($input, $i) = @_;

    print $h->a({name => sprintf('Input-Parameter-%s', $input->id)});

    print $h->h3(sprintf('%u.%u. %s', $section, $i, e($input->id)));

    my $j = 0;

    print $h->h4(sprintf('%u.%u.%u. Description', $section, $i, ++$j));
    print $input->description->html(3);

    print $h->h4(sprintf('%u.%u.%u. Required', $section, $i, ++$j));
    print $h->p($input->required ?
        'This input parameter is REQUIRED.'
        :
        'This input parameter is NOT required.'
    );

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Example', $section, $i, ++$j)));
    print $h->pre(e($json->encode({$input->id => $input->jsonExample})));

    print $h->close(details);

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Schema', $section, $i, ++$j)));

    if (!$input->schema) {
        print $h->ul($h->li($h->em('None specified.')));

    } else {
        my $yaml = YAML::XS::Dump($input->{'Schema'});
        $yaml =~ s/^---//;
        print $h->pre(e($yaml));

    }

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
                e($case->id),
            ));
        }

        print $h->close(ul);
    }

    print $h->close(details);

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Test suites', $section, $i, ++$j)));
    print $h->p('This input parameter is also used in the following test suites:');

    my @suites = $input->suites;
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

sub print_errors {
    print $h->a({name => 'errors'});
    print $h->h2(sprintf('%d. Errors', ++$section));

    my $i = 0;
    foreach my $error ($spec->errors) {
        print $h->open(section);

        print_error($error, ++$i);

        print $h->close(section);
    }

    say STDERR 'wrote errors';
}

sub print_error {
    my ($error, $i) = @_;

    print $h->a({name => sprintf('Error-%s', $error->id)});

    print $h->h3(sprintf('%u.%u. %s', $section, $i, e($error->id)));

    my $j = 0;

    print $h->h4(sprintf('%u.%u.%u. Severity', $section, $i, ++$j));
    print $h->ul($h->li($h->code($h->strong(e($error->severity)))));

    print $h->h4(sprintf('%u.%u.%u. Description', $section, $i, ++$j));
    print $error->description->html(3);

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Test cases', $section, $i, ++$j)));
    print $h->p('This error may be produced by the following test cases:');

    my @cases = $error->cases;
    if (scalar(@cases) < 1) {
        print $h->ul($h->li($h->em('None specified.')));

    } else {
        print $h->open(ul);

        foreach my $case (@cases) {
            print $h->li($h->a(
            { href => sprintf('#Test-Case-%s', $case->id) },
            e($case->id),
            ));
        }

        print $h->close(ul);
    }

    print $h->close(details);
}

sub print_providers {
    print $h->a({name => 'data-providers'});
    print $h->h2(sprintf('%d. Data Providers', ++$section));

    my $i = 0;
    foreach my $provider ($spec->providers) {
        print $h->open(section);

        print_provider($provider, ++$i);

        print $h->close(section);
    }

    say STDERR 'wrote errors';
}

sub print_provider {
    my ($provider, $i) = @_;

    print $h->a({name => sprintf('Data-Provider-%s', $provider->id)});

    print $h->h3(sprintf('%u.%u. %s', $section, $i, e($provider->id)));

    my $j = 0;

    print $h->h4(sprintf('%u.%u.%u. Description', $section, $i, ++$j));
    print $provider->description->html(3);

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Data table', $section, $i, ++$j)));

    print $h->open('table');

    my @columns = $provider->columns;

    print $h->thead([
        $h->tr([ map { $h->th($h->pre(e($_->name))) } @columns ]),
        $h->tr([ map { $h->th($h->pre(e($_->type))) } @columns ]),
        $h->tr([ map { $h->th($_->description->raw_html) } @columns ]),
    ]);

    print $h->tbody([
        map {
            $h->tr([
                map {
                    $h->td($h->pre(e($_)))
                }
                @{$_}
            ])
        }
        @{$provider->rows}
    ]);

    print $h->close('table');

    print $h->close(details);

    print $h->open(details);

    print $h->summary($h->h4(sprintf('%u.%u.%u. Test cases', $section, $i, ++$j)));
    print $h->p('This data provider is used by the following test cases:');

    my @cases = $provider->cases;
    if (scalar(@cases) < 1) {
        print $h->ul($h->li($h->em('None specified.')));

    } else {
        print $h->open(ul);

        foreach my $case (@cases) {
            print $h->li($h->a(
            { href => sprintf('#Test-Case-%s', $case->id) },
            e($case->id),
            ));
        }

        print $h->close(ul);
    }

    print $h->close(details);
}

sub print_footer {
    print $h->footer($h->p(e(sprintf(
        'Copyright %u %s.',
        substr($spec->lastUpdated, 0, 4),
        $spec->contactOrg
    ))));

    say STDERR 'wrote footer';
}

sub e { $h->entity_encode(shift) }
