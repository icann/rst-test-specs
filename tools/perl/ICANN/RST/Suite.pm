package ICANN::RST::Suite;
use HTML::Tiny;
use List::Util qw(any);
use GraphViz2;
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

sub graph {
    my $self = shift;

    my $graph = GraphViz2->new(
        'global' => {
            'directed'  => 1,
        },
        'graph' => {
            'layout'    => 'dot',
            'rankdir'   => 'LR',
        }
    );

    my @cases = $self->cases;

    foreach my $case (@cases) {
        $graph->add_node(
            'name'      => $case->id,
            'href'      => sprintf('#Test-Case-%s', $case->id),
            'tooltip'   => HTML::Tiny->entity_encode($case->summary),
            'shape'     => 'box',
        );
    }

    for (my $i = 0 ; $i < scalar(@cases) ; $i++) {
        my $case = $cases[$i];

        my @deps = $case->dependencies;

        if (scalar(@deps) < 1 && $i > 0) {
            my $prev = $cases[$i-1];
            $graph->add_edge(
                'from'  => $prev->id,
                'to'    => $case->id,
            );

        } else {
            foreach my $dep (@deps) {
                $graph->add_edge(
                    'from'  => $dep->id,
                    'to'    => $case->id,
                );
            }
        }
    }

    return $graph;
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

=head2 graph()

Returns a L<GraphViz2> object visualising the sequence of tests for this suite.

=cut
