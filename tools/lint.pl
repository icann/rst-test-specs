#!perl
use List::Util qw(any);
use ICANN::RST::Spec;
use JSON::XS;
use feature qw(say);
use strict;

my $json = JSON::XS->new->utf8;

undef $/;

say 'checking test specification in ', $ARGV[0];

my $spec = ICANN::RST::Spec->new($ARGV[0]);

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

say 'done';

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
        foreach my $key (qw(Input-Parameters Resources Errors)) {
            my $type = $key;
            $type =~ s/s$//;
            $type =~ s/-/ /;

            foreach my $id (@{$case->{$key}}) {
                next if ($key eq 'Errors' && $suite->id =~ /^StandardDNS/);

                if (any { $id eq $_ } @{$suite->{$key}}) {
                    warn(sprintf("%s '%s' is already present %s, consider removing from %s", $type, $id, $suite->id, $case->id));
                }

                if (!defined($used->{$key}->{$id})) {
                    $used->{$key}->{$id} = $case->id;

                } else {
                    warn(sprintf("%s '%s' is present in both %s and %s, consider moving to %s", $type, $id, $used->{$key}->{$id}, $case->id, $suite->id));

                }
            }
        }
    }
}

sub check_case {
    my $case = shift;

    my @suites = $case->suites;
    warn(sprintf("Case '%s' is not used by any suites", $case->id)) unless (scalar(@suites) > 0);
}

sub check_input {
    my $input = shift;

    my @cases = $input->cases;
    my $used = scalar(@cases);

    foreach my $suite ($spec->suites) {
        $used += scalar(grep { $input->id eq $_ } @{$suite->{'Input-Parameters'}});
    }

    warn(sprintf("Input Parameter '%s' is not used by any cases or suites", $input->id)) unless ($used > 0);

    # my ($v, $valid);
    # eval {
    #     $v = $json->decode($input->jsonExample);
    #     $valid = 1;
    # };
    # say STDERR $@;
    # if (!$valid) {
    #     print STDERR $input->dump;
    #     use Data::Dumper;
    #     print STDERR Dumper [$input->example, $input->jsonExample];
    #     warn(sprintf("Example value %s for %s is not valid JSON", $input->jsonExample, $input->id));
    #
    # } else {
    #     warn(sprintf("Example value %s for %s is not an object", $input->jsonExample, $input->id)) if ('object' eq $input->type && 'HASH' ne ref($v));
    #     warn(sprintf("Example value %s for %s is not an array", $input->jsonExample, $input->id)) if ('array' eq $input->type && 'ARRAY' ne ref($v));
    # }
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

    my $used = 0;
    foreach my $case ($spec->cases) {
        $used += scalar(grep { $error->id eq $_ } @{$case->{'Errors'}});
    }

    foreach my $suite ($spec->suites) {
        $used += scalar(grep { $error->id eq $_ } @{$suite->{'Errors'}});
    }

    warn(sprintf("Error '%s' is not used by any cases or suites", $error->id)) unless ($used > 0);
}

sub fail {
    my $msg = shift;
    printf(STDERR "Assertion '%s' failed\n", $msg);
}
