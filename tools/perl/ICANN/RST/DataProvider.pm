package ICANN::RST::DataProvider;
use ICANN::RST::DataProvider::Column;
use base qw(ICANN::RST::Base);
use strict;

sub description { ICANN::RST::Text->new($_[0]->{'Description'}) }

sub rows { $_[0]->{'Rows'} }

sub columns { map { ICANN::RST::DataProvider::Column->new($_) } @{$_[0]->{'Columns'}} }

sub cases {
    my $self = shift;

    my %cases;

    foreach my $case ($self->spec->cases) {
        foreach my $provider ($case->providers) {
            $cases{$case->id} = $case if ($provider->id eq $self->id && !defined($cases{$case->id}));
        }
    }

    return sort { $a->id cmp $b->id } values(%cases);
}

1;

__END__

=pod

=head1 NAME

ICAN::RST::DataProvider - an object representing an RST data provider. This class
inherits from L<ICANN::RST::Base> (so it has the C<id()> and C<spec()> methods).

=head1 METHODS

=head2 description()

A L<ICANN::RST::Text> object containing the long textual description of the
error.

=head2 columns()

An array of L<ICANN::RST::DataProvider::Column> objects representing the columns
for this data provider.

=head2 rows()

An arrayref of arrayrefs containing the rows for this data provider.

=head2 cases()

A list of all C<ICANN::RST::Case> objects that use this data provider.

=cut
