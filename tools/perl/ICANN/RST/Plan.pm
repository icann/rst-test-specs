package ICANN::RST::Plan;
use base qw(ICANN::RST::Base);
use strict;

sub name        { $_[0]->{'Name'} }
sub description { ICANN::RST::Text->new($_[0]->{'Description'}) }
sub graph       { ICANN::RST::Graph->new($_[0]->cases) }

sub suites {
    my $self = shift;

    my %suites;

    foreach my $suite ($self->spec->suites) {
        foreach my $id (@{$self->{'Test-Suites'}}) {
            $suites{$suite->id} = $suite if ($id eq $suite->id && !defined($suites{$suite->id}));
        }
    }

    return sort { $a->order <=> $b->order } values(%suites);
}

sub cases {
    my $self = shift;

    my %cases;

    foreach my $suite ($self->suites) {
        foreach my $case ($suite->cases) {
            $cases{$case->id} = $case unless (defined($cases{$case->id}));
        }
    }

    return sort { $a->id cmp $b->id } values(%cases);
}

sub inputs {
    my $self = shift;

    my %inputs;

    foreach my $suite ($self->suites) {
        foreach my $input ($suite->inputs) {
            $inputs{$input->id} = $input unless (defined($inputs{$input->id}));
        }
    }

    return sort { $a->id cmp $b->id } values(%inputs);
}

sub resources {
    my $self = shift;

    my %resources;

    foreach my $suite ($self->suites) {
        foreach my $resource ($suite->resources) {
            $resources{$resource->id} = $resource unless (defined($resources{$resource->id}));
        }
    }

    return sort { $a->id cmp $b->id } values(%resources);
}

sub errors {
    my $self = shift;

    my %errors;

    foreach my $suite ($self->suites) {
        foreach my $error ($suite->errors) {
            $errors{$error->id} = $error unless (defined($errors{$error->id}));
        }
    }

    return sort { $a->id cmp $b->id } values(%errors);
}

1;

__END__

=pod

=head1 NAME

ICAN::RST::Plan - an object representing an RST test plan. This class
inherits from L<ICANN::RST::Base> (so it has the C<id()>, C<order()> and
C<spec()> methods).

=head1 METHODS

=head2 name()

The name of the plan.

=head2 description()

A L<ICANN::RST::Text> object containing the long textual description of the
plan.

=head2 suites()

A list of L<ICANN::RST::Suite> objects used by this plan.

=head2 cases()

A list of L<ICANN::RST::Case> objects used by the suites used by this plan.

=head2 inputs()

A list of L<ICANN::RST::Inputs> objects used by the test cases used by the
suites used by this plan.

=head2 resources()

A list of L<ICANN::RST::Resource> objects relevant to this plan.

=head2 inputs()

A list of L<ICANN::RST::Inputs> objects which may be produced by this plan.

=cut
