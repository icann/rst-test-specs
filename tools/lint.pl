#!perl
use List::Util qw(any none);
use ICANN::RST::Spec;
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
}

sub check_plan {
    my $plan = shift;
    my @suites = $plan->suites;

    warn(sprintf("%s has no test suites defined", $plan->id)) unless (scalar(@suites) > 0);
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

    warn(sprintf("%s is not used by any plans", $suite->id)) unless ($used);

    my @cases = $suite->cases;
    warn(sprintf("%s has no cases defined", $suite->id)) unless (scalar(@cases) > 0);

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
}

sub check_resource {
    my $resource = shift;

    my $used = 0;
    foreach my $case ($spec->cases) {
        $used += scalar(grep { $resource->id eq $_ } @{$case->{'Resources'}});
    }

    foreach my $suite ($spec->suites) {
        $used += scalar(grep { $resource->id eq $_ } @{$suite->{'Resources'}});
    }

    warn(sprintf("Resource '%s' is not used by any cases or suites", $resource->id)) unless ($used > 0);
}

sub check_error {
    my $error = shift;

    if (none { $_ eq $error->severity} qw(WARNING ERROR CRITICAL)) {
        warn(sprintf("Error '%s' has unsupported severity '%s'", $error->id, $error->severity));
    }

    my $used = 0;
    foreach my $case ($spec->cases) {
        $used += scalar(grep { $error->id eq $_ } @{$case->{'Errors'}});
    }

    warn(sprintf("Error '%s' appears to have a placeholder description", $error->id)) if ($error->{'Description'} =~ /^TBA/);

    warn(sprintf("Error '%s' is not used by any cases", $error->id)) unless ($used > 0);
}

sub fail {
    my $msg = shift;
    printf(STDERR "Assertion '%s' failed\n", $msg);
}
