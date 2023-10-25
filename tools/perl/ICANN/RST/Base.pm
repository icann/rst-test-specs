package ICANN::RST::Base;
use strict;

sub new {
    my ($package, $id, $ref, $spec) = @_;

    warn("No reference for '$id'") unless (defined($ref));

    return bless(
        {
            %{$ref},
            'id'    => $id,
            'spec'  => $spec,
        },
        $package,
    );
}

sub id      { $_[0]->{'id'} }
sub order   { int($_[0]->{'Order'}) }
sub spec    { $_[0]->{'spec'} }

1;

__END__

=pod

=head1 NAME

ICAN::RST::Base - base class for other things

=head1 METHODS

=head2 id()

Returns a string containing the unique ID of the thing.

=head2 order()

Returns an integer representing the position of the thing among its siblings.

=head2 spec()

Returns a reference to the enclosing L<ICANN::RST::Spec> object.

=cut
