package ICANN::RST::Case;
use List::Util qw(any);
use base qw(ICANN::RST::Base);
use strict;

sub summary     { $_[0]->{'Summary'} }
sub description { ICANN::RST::Text->new($_[0]->{'Description'}) }

sub title {
    my $self = shift;

    if ($self->summary) {
        return sprintf('%s - %s', $self->id, $self->summary);

    } else {
        return $self->id;

    }
}

sub inputs {
    my $self = shift;

    my @inputs;

    foreach my $input ($self->spec->inputs) {
        push(@inputs, $input) if (any { $_ eq $input->id } @{$self->{'Input-Parameters'}});
    }

    return sort { $a->id <=> $b->id } @inputs;    
}

sub dependencies {
    my $self = shift;

    my @cases;

    foreach my $case ($self->spec->cases) {
        push(@cases, $case) if (any { $_ eq $case->id } @{$self->{'Dependencies'}});
    }

    return sort { $a->id <=> $b->id } @cases;
}

sub dependants {
    my $self = shift;

    my @cases;

    foreach my $case ($self->spec->cases) {
        push(@cases, $case) if (any { $_ eq $self->id } $case->dependencies);
    }

    return sort { $a->id <=> $b->id } @cases;
}

sub suites {
    my $self = shift;

    my %suites;

    foreach my $suite ($self->spec->suites) {
        foreach my $case ($suite->cases) {
            $suites{$suite->id} = $suite if ($case->id eq $self->id && !defined($suites{$suite->id}));
        }
    }

    return sort { $a->order <=> $b->order } values(%suites);
}

1;

__END__

=pod

=head1 NAME

ICANN::RST::Case - an object representing an RST test case. This class inherits
from L<ICANN::RST::Base> (so it has the C<id()>, C<order()> and
C<spec()> methods).

=head1 METHODS

=head2 summary()

Short textual description of the test case.

=head2 description()

A L<ICANN::RST::Text> object containing the long textual description of the test
case.

=head2 inputs()

A list of L<ICANN::RST::Inputs> required by this test case.

=head2 dependencies()

A list of test cases that this test case depends on.

=head2 dependents()

A list of test cases that depend on this test case.

=head2 suites()

A list of all L<ICANN::RST::Suite> objects that use this test case.

=cut
