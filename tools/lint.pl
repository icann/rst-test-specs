#!/usr/bin/env perl
use Digest::SHA qw(sha256_hex);
use File::Slurp;
use File::Spec;
use ICANN::RST::Spec;
use IPC::Open3;
use JSON::XS;
use List::Util qw(any none);
use Symbol qw(gensym);
use YAML::XS;
use feature qw(say);
use strict;

my $spec = ICANN::RST::Spec->new($ARGV[0]);

say 'checking test specification in ', $ARGV[0];

check_spec();

say 'done';

sub check_spec {
    say 'checking plans...';
    foreach my $plan ($spec->plans) {
        check_plan($plan);
    }

    say 'checking suites...';
    foreach my $suite ($spec->suites) {
        check_suite($suite);
    }

    say 'checking cases...';
    foreach my $case ($spec->cases) {
        check_case($case);
    }

    say 'checking inputs...';
    foreach my $input ($spec->inputs) {
        check_input($input);
    }

    say 'checking resources...';
    foreach my $resource ($spec->resources) {
        check_resource($resource);
    }

    say 'checking errors...';
    foreach my $error ($spec->errors) {
        check_error($error);
    }

    say 'checking data providers...';
    foreach my $provider ($spec->providers) {
        check_provider($provider);
    }
}

sub check_plan {
    my $plan = shift;
    my @suites = $plan->suites;

    warn(sprintf("Plan '%s' has no test suites defined", $plan->id)) unless (scalar(@suites) > 0);
}

sub check_suite {
    my $suite = shift;

    my $used = 0;
    PLAN: foreach my $plan ($spec->plans) {
        foreach my $psuite ($plan->suites) {
            if ($psuite->id eq $suite->id) {
                $used = 1;
                last PLAN;
            }
        }
    }

    warn(sprintf("Suite '%s' is not used by any plans", $suite->id)) unless ($used);

    my @cases = $suite->cases;
    warn(sprintf("Suite '%s' has no cases defined", $suite->id)) unless (scalar(@cases) > 0);

    $used = {};
    foreach my $case (@cases) {
        foreach my $key (qw(Input-Parameters Resources)) {
            my $type = $key;
            $type =~ s/s$//;
            $type =~ s/-/ /;

            foreach my $id (@{$case->{$key}}) {
                next if ($key eq 'Errors' && $suite->id =~ /^StandardDNS/);

                if (any { $id eq $_ } @{$suite->{$key}}) {
                    warn(sprintf("%s '%s' is already present in %s, consider removing from %s", $type, $id, $suite->id, $case->id));
                }

                if (!defined($used->{$key}->{$id})) {
                    $used->{$key}->{$id} = $case->id;

                } else {
                    warn(sprintf("%s '%s' is present in both %s and %s, consider moving to %s", $type, $id, $used->{$key}->{$id}, $case->id, $suite->id));

                }
            }
        }

        foreach my $dep ($case->dependencies) {
            my @suites = $dep->suites;
            if (scalar(@suites) > 1 || $suites[0]->id ne $suite->id) {
                warn(sprintf("Test case '%s' in %s has a cross-suite dependency on %s in %s", $case->id, $suite->id, $dep->id, $suites[0]->id));
            }
        }
    }
}

sub check_case {
    my $case = shift;

    my @suites = $case->suites;
    warn(sprintf("Case '%s' is not used by any suites", $case->id)) unless (scalar(@suites) > 0);

    foreach my $dep (@{$case->{'Dependencies'}}) {
        warn(sprintf("Case '%s' has a dependency on non-existent case '%s'", $case->id, $dep)) if (none { $_->id eq $dep } $spec->cases);
    }

    foreach my $input (@{$case->{'Input-Parameters'}}) {
        warn(sprintf("Case '%s' uses non-existent input parameter '%s'", $case->id, $input)) if (none { $_->id eq $input } $spec->inputs);
    }

    foreach my $resource (@{$case->{'Resources'}}) {
        warn(sprintf("Case '%s' references non-existent resource '%s'", $case->id, $resource)) if (none { $_->id eq $resource } $spec->resources);
    }

    foreach my $error (@{$case->{'Errors'}}) {
        warn(sprintf("Case '%s' uses non-existent error '%s'", $case->id, $error)) if (none { $_->id eq $error } $spec->errors);
    }

    foreach my $provider ($case->providers) {
        foreach my $error ($provider->errors) {
            if (none { $_ eq $error->id } @{$case->{'Errors'}}) {
                warn(sprintf("Error '%s' referenced in data provider '%s' is not included in the list of errors for case '%s'", $error->id, $provider->id, $case->id));
            }
        }
    }

    warn(sprintf("Case '%s' has maturity of '%s' (expected one of ALPHA|BETA|GAMMA)", $case->id, $case->{'Maturity'})) unless (any { $_ eq $case->{'Maturity'} } qw(ALPHA BETA GAMMA));
}

sub check_input {
    my $input = shift;

    my @cases = $input->cases;
    my $used = scalar(@cases);

    foreach my $suite ($spec->suites) {
        $used += scalar(grep { $input->id eq $_ } @{$suite->{'Input-Parameters'}});
    }

    warn(sprintf("Input Parameter '%s' is not used by any cases or suites", $input->id)) unless ($used > 0);

    warn(sprintf("Input Parameter '%s' has an invalid type ('%s')", $input->id, $input->type)) unless (any { $input->type eq $_} qw(file input));

    if (!exists($input->{'Schema'})) {
        warn(sprintf("Input Parameter '%s' doesn't have a schema", $input->id));

        if (!exists($input->{'Example'})) {
            warn(sprintf("Input Parameter '%s' doesn't have an example", $input->id));
        }

    } else {
        my $schema = $input->schema;

        if (!validate_input_schema($schema)) {
            warn(sprintf("Schema for Input Parameter '%s' is invalid", $input->id));

        } else {
            if (!exists($input->{'Example'})) {
                warn(sprintf("Input Parameter '%s' doesn't have an example", $input->id));

            } else {
                my @errors = validate_input_example($schema, $input->example);
                if (scalar(@errors) > 0) {
                    printf(STDERR "example for Input Parameter '%s' is invalid:\n", $input->id);

                    foreach my $error (@errors) {
                        printf(STDERR "  * {%s}: %s\n", $error->property, $error->message);
                    }

                    print STDERR JSON::XS->new->utf8->canonical->pretty->encode($input->example);
                }
            }
        }
    }

    if (!exists($input->{'Required'})) {
        warn(sprintf("Missing 'Required' property for Input Parameter '%s'", $input->id));

    } elsif ($input->{'Required'} ne !1 && $input->{'Required'} ne !!1 && q{JSON::PP::Boolean} ne ref($input->{'Required'})) {
        warn(sprintf("'Required' property for Input Parameter '%s' is not a boolean", $input->id));

    }

    warn(sprintf("Input Parameter '%s' has redundant examples", $input->id)) if (exists($input->{'Example'}) && exists($input->{'Schema'}->{'examples'}));
}

sub check_resource {
    my $resource = shift;

    my $used;
    CASE: foreach my $case ($spec->cases) {
        if (scalar(grep { $resource->id eq $_ } @{$case->{'Resources'}}) > 0) {
            $used = 1;
            last CASE;
        }
    }

    SUITE: foreach my $suite ($spec->suites) {
        if (scalar(grep { $resource->id eq $_ } @{$suite->{'Resources'}}) > 0) {
            $used = 1;
            last SUITE;
        }
    }

    warn(sprintf("Resource '%s' is not used by any cases or suites", $resource->id)) unless ($used);
}

sub check_error {
    my $error = shift;

    if (none { $_ eq $error->severity} qw(WARNING ERROR CRITICAL)) {
        warn(sprintf("Error '%s' has unsupported severity '%s'", $error->id, $error->severity));
    }

    my $used;
    CASE: foreach my $case ($spec->cases) {
        if (scalar(grep { $error->id eq $_ } @{$case->{'Errors'}}) > 0) {
            $used = 1;
            last CASE;
        }
    }

    PROVIDER: foreach my $provider ($spec->providers) {
        my $i = 0;
        COLUMN: foreach my $column ($provider->columns) {
            if ('errorCode' eq $column->name) {
                ROW: foreach my $row (@{$provider->rows}) {
                    if ($error->id eq $row->[$i]) {
                        $used = 1;
                        last PROVIDER;
                    }
                }
            }
            $i++;
        }
    }

    warn(sprintf("Error '%s' appears to have a placeholder description", $error->id)) if ($error->{'Description'} =~ /^TBA/);

    warn(sprintf("Error '%s' is not used by any cases or data providers", $error->id)) unless ($used);
}

sub check_provider {
    my $provider = shift;

    my $i = 0;
    COLUMN: foreach my $column ($provider->columns) {
        if ('errorCode' eq $column->name) {
            my $j = 0;
            ROW: foreach my $row (@{$provider->rows}) {
                $j++;
                warn(sprintf("Row #%u in Data Provider '%s' uses non-existent error '%s'", $j, $provider->id, $row->[$i])) if (none { $_->id eq $row->[$i] } $spec->errors);
            }
        }
        $i++;
    }
}

sub validate_input_schema {
    my $schema = shift;

    my $json = JSON::XS->new->utf8->canonical->pretty->encode($schema->schema);
    my $file = File::Spec->catfile(File::Spec->tmpdir, sha256_hex($json).'.json');

    write_file($file, $json);

    my $err = gensym;
    my $pid = open3(undef, my $out, $err, qw(schemalint verify --skip-normalization), $file);

    my $output = join('', $out->getlines);
    $out->close;

    my $errors = join('', $err->getlines);
    $err->close;

    waitpid($pid, 0);

    if ($? > 0) {
        warn($output.$errors);
        return undef;
    }

    return 1;
}

sub validate_input_example {
    my ($schema, $example) = @_;

    #
    # gotcha - JSON::Schema assumes that if a scalar is passed to validate(),
    # then it is JSON, so we need to encode scalars into JSON before passing
    #
    if ('' eq ref($example)) {
        $example = JSON::XS->new->utf8->canonical->encode($example);
    }

    my @errors;

    my $result = $schema->validate($example);
    if (!$result) {
        foreach my $error ($result->errors) {
            push(@errors, $error);
        }
    }

    return @errors;
}
