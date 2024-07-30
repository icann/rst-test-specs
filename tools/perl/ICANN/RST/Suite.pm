package ICANN::RST::Suite;
use base qw(ICANN::RST::Base);
use strict;

#
# if GraphViz2 is available then we can load ICANN::RST::Graph
#
eval qq(use ICANN::RST::Graph;) if (eval qq(use GraphViz2 ; 1));

sub name        { $_[0]->{'Name'} }
sub description { ICANN::RST::Text->new($_[0]->{'Description'}) }
sub graph       { ICANN::RST::Graph->new($_[0]->cases) }

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

    foreach my $id (@{$self->{'Input-Parameters'}}) {
        $inputs{$id} = $self->spec->input($id);
    }

    foreach my $case ($self->cases) {
        foreach my $input ($case->inputs) {
            $inputs{$input->id} = $input unless (defined($inputs{$input->id}));
        }
    }

    return sort { $a->id cmp $b->id } values(%inputs);
}

sub resources {
    my $self = shift;

    my %resources;
    foreach my $id (@{$self->{'Resources'}}) {
        $resources{$id} = $self->spec->resource($id);
    }

    foreach my $case ($self->cases) {
        foreach my $resource ($case->resources) {
            $resources{$resource->id} = $resource unless (defined($resources{$resource->id}));
        }
    }

    return sort { $a->id cmp $b->id } values(%resources);
}

sub errors {
    my $self = shift;

    my %errors;
    foreach my $case ($self->cases) {
        foreach my $error ($case->errors) {
            $errors{$error->id} = $error unless (defined($errors{$error->id}));
        }
    }

    return sort { $a->id cmp $b->id } values(%errors);
}

sub implemented {
    my $self = shift;

    my @cases = $self->cases;

    my $implemented = scalar(grep { $_->implemented } @cases);

    return $implemented / scalar(@cases);
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

=head2 resources()

A list of L<ICANN::RST::Resources> objects relevant to this suite.

=head2 errors()

A list of L<ICANN::RST::Error> objects which may be produced by this suite.

=head2 graph()

Returns a L<GraphViz2> object visualising the sequence of tests for this suite.

=head2 implemented()

Returns a number in the range 0-1 indicating what fraction of this suite's test
cases have been implemented.

=cut
