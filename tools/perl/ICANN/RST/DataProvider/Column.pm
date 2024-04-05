package ICANN::RST::DataProvider::Column;
use strict;

sub new {
    my ($package, $ref) = @_;
    return bless($ref, $package);
}

sub name        { $_->{'Name'} }
sub type        { $_->{'Type'} }
sub description { ICANN::RST::Text->new($_[0]->{'Description'}) }

1;

__END__

=pod

=head1 NAME

ICANN::RST::DataProvider::Column - an object representing a column in an RST
data provider.

=head1 METHODS

=head2 name()

The column name.

=head2 type()

The column type.

=head2 description()

A L<ICANN::RST::Text> object containing the textual description of the column.
