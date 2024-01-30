package ICANN::RST::ChangeLog;
use Carp;
use DateTime;
use base qw(ICANN::RST::Base);
use strict;

sub new {
    my ($package, $id, $ref, $spec) = @_;

    croak(sprintf("invalid date format '%s', must be YYYY-MM-DD", $id)) unless ($id =~ /^\d{4}-\d{2}-\d{2}$/);

    #
    # the ICANN::RST::Base constructor expects $ref to be a hashref so we need
    # to wrap it
    #
    return $package->SUPER::new(
        $id,
        {'changes' => $ref},
        $spec,
    );
}

sub date {
    my $self = shift;

    return DateTime->new(
        'year'  => int(substr($self->id, 0, 4)),
        'month' => int(substr($self->id, 5, 2)),
        'day'   => int(substr($self->id, 8, 2)),
    );
}

sub changes { map { ICANN::RST::Text->new($_) } @{$_[0]->{'changes'}} }

1;

__END__

=pod

=head1 NAME

ICAN::RST::ChangeLog - an object representing a set of changes. This class
inherits from L<ICANN::RST::Base> (so it has the C<id()> and C<spec()> methods).

=head1 METHODS

=head2 date()

Returns a L<DateTime> representing the date of the changes.

=head2 changes()

Returns an array of L<ICANN::RST::Text> objects.

=cut
