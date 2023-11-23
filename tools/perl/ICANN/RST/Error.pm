package ICANN::RST::Error;
use base qw(ICANN::RST::Base);
use strict;

sub url { URI->new($_[0]->{'URL'}) }
sub severity { $_[0]->{'Severity'} }
sub description { ICANN::RST::Text->new($_[0]->{'Description'}) }

1;

__END__

=pod

=head1 NAME

ICAN::RST::Error - an object representing an RST error. This class
inherits from L<ICANN::RST::Base> (so it has the C<id()> and C<spec()> methods).

=head1 METHODS

=head2 description()

A L<ICANN::RST::Text> object containing the long textual description of the
error.

=head2 severity()

A string containing one of C<WARNING>, C<ERROR> or C<CRITICAL>.

=cut
