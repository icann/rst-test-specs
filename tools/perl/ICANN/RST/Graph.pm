package ICANN::RST::Graph;
use Encode;
use base qw(GraphViz2);
use utf8;
use strict;

sub new {
    my ($package, @cases) = @_;

    my $self = $package->SUPER::new(
        'global' => {
            'directed'  => 1,
        },
        'graph' => {
            'layout'    => 'dot',
            'rankdir'   => 'LR',
        }
    );

    foreach my $case (@cases) {
        $self->add_node(
            'name'      => $case->id,
            'href'      => sprintf('#Test-Case-%s', $case->id),
            'tooltip'   => $self->entity_encode($case->summary),
            'shape'     => 'box',
        );
    }

    for (my $i = 0 ; $i < scalar(@cases) ; $i++) {
        my $case = $cases[$i];

        my @deps = $case->dependencies;

        if (scalar(@deps) < 1 && $i > 0) {
            my $prev = $cases[$i-1];
            $self->add_edge(
                'from'  => $prev->id,
                'to'    => $case->id,
            );

        } else {
            foreach my $dep (@deps) {
                $self->add_edge(
                    'from'  => $dep->id,
                    'to'    => $case->id,
                );
            }
        }
    }

    return $self;
}

sub entity_encode {
    my ($self, $str) = @_;

    return join('', map { sprintf('&#%u;', ord($_)) } split(//, encode("UTF-8", $str)));
}

1;
