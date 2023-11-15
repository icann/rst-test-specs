package ICANN::RST::Resource;
use URI;
use base qw(ICANN::RST::Base);
use strict;

sub url { URI->new($_[0]->{'URL'}) }
sub description { ICANN::RST::Text->new($_[0]->{'Description'}) }

1;

__END__

=pod

=head1 NAME

ICAN::RST::Resource - an object representing an RST resource. This class
inherits from L<ICANN::RST::Base> (so it has the C<id()> and C<spec()> methods).

=head1 METHODS

=head2 description()

A L<ICANN::RST::Text> object containing the long textual description of the
resource.

=head2 url()

A L<URI> object representing the URL for this resource.

=cut
