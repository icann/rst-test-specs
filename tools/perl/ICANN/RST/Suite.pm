package ICANN::RST::Suite;
use List::Util qw(any);
use base qw(ICANN::RST::Base);
use feature qw(say);
use strict;

sub name        { $_[0]->{'Name'} }
sub description { ICANN::RST::Text->new($_[0]->{'Description'}) }

sub plans {
    my $self = shift;

    my %plans;

    foreach my $plan ($self->spec->plans) {
        foreach my $suite ($plan->suites) {
            $plans{$plan->id} = $plan if ($self->id eq $suite->id && !defined($plans{$plan->id}));
        }
    }

    return sort { $a->order <=> $b->order } values(%plans);
}

sub cases {
    my $self = shift;

    my @cases;

    if ('ARRAY' eq ref($self->{'Test-Cases'})) {
        @cases = map { $self->spec->case($_) } @{$self->{'Test-Cases'}};

    } elsif (defined($self->{'Test-Cases'})) {
        @cases = grep { $_->id =~ /$self->{'Test-Cases'}/ } $self->spec->cases;

    }

    return sort { $a->id cmp $b->id } @cases;
}

sub inputs {
    my $self = shift;

    my %inputs;

    foreach my $case ($self->cases) {
        foreach my $input ($case->inputs) {
            $inputs{$input->id} = $input unless (defined($inputs{$input->id}));
        }
    }

    return sort { $a->id cmp $b->id } values(%inputs);
}

1;

__END__

=pod

=head1 NAME

ICAN::RST::Suite - an object representing an RST test suite. This class
inherits from L<ICANN::RST::Base> (so it has the C<id()>, C<order()> and
C<spec()> methods).

=head1 METHODS

=head2 name()

The name of the suite.

=head2 description()

A L<ICANN::RST::Text> object containing the long textual description of the
suite.

=head2 cases()

A list of L<ICANN::RST::Case> objects used by this suite.

=head2 inputs()

A list of L<ICANN::RST::Inputs> objects used by the test cases used by this
suite.

=cut
