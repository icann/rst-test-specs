package ICANN::RST::Error;
use base qw(ICANN::RST::Base);
use strict;

sub severity { $_[0]->{'Severity'} }
sub description { ICANN::RST::Text->new($_[0]->{'Description'}) }

sub cases {
    my $self = shift;

    my %cases;

    foreach my $case ($self->spec->cases) {
        foreach my $error ($case->errors) {
            $cases{$case->id} = $case if ($error->id eq $self->id && !defined($cases{$case->id}));
        }
    }

    return sort { $a->id cmp $b->id } values(%cases);
}

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

=head2 cases()

A list of all C<ICANN::RST::Case> objects that produce this error.

=cut
