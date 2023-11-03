package ICANN::RST::Spec;
use ICANN::RST::Plan;
use ICANN::RST::Suite;
use ICANN::RST::Case;
use ICANN::RST::Input;
use ICANN::RST::Text;
use ICANN::RST::Graph;
use YAML::XS;
use List::Util qw(pairmap);
use strict;

sub new {
    my ($package, $file) = @_;
    return bless(
        {
            'spec' => YAML::XS::LoadFile($file),
            'file' => $file
        },
        $package,
    );
}

sub schemaVersion   { $_[0]->{'spec'}->{'RST-Test-Plan-Schema-Version'}     }
sub version         { $_[0]->{'spec'}->{'Version'}                          }
sub lastUpdated     { $_[0]->{'spec'}->{'Last-Updated'}                     }
sub contactName     { $_[0]->{'spec'}->{'Contact'}->{'Name'}                }
sub contactOrg      { $_[0]->{'spec'}->{'Contact'}->{'Organization'}        }
sub contactEmail    { $_[0]->{'spec'}->{'Contact'}->{'Email'}               }
sub preamble        { ICANN::RST::Text->new($_[0]->{'spec'}->{'Preamble'})  }
sub plans           { my $self = shift ; return sort { $a->order <=> $b->order  } pairmap { ICANN::RST::Plan->new($a,  $b, $self) } %{$self->{'spec'}->{'Test-Plans'}}      }
sub suites          { my $self = shift ; return sort { $a->order <=> $b->order  } pairmap { ICANN::RST::Suite->new($a, $b, $self) } %{$self->{'spec'}->{'Test-Suites'}}     }
sub cases           { my $self = shift ; return sort {    $a->id cmp $b->id     } pairmap { ICANN::RST::Case->new($a,  $b, $self) } %{$self->{'spec'}->{'Test-Cases'}}      }
sub inputs          { my $self = shift ; return sort {    $a->id cmp $b->id     } pairmap { ICANN::RST::Input->new($a, $b, $self) } %{$self->{'spec'}->{'Input-Parameters'}}}
sub plan            { my ($self, $id) = @_ ; return $self->find($id, $self->plans)  };
sub suite           { my ($self, $id) = @_ ; return $self->find($id, $self->suites) };
sub case            { my ($self, $id) = @_ ; return $self->find($id, $self->cases)  };
sub input           { my ($self, $id) = @_ ; return $self->find($id, $self->inputs) };

sub find {
    my ($self, $needle, @haystack) = @_;

    foreach my $stick (@haystack) {
        return $stick if ($stick->id eq $needle);
    }

    warn("object '$needle' not found");

    return undef;
}

1;

__END__

=pod

=head1 NAME

ICAN::RST::Spec - an object representing the RST test specifications.

=head1 METHODS

=head2 new($file)

Constructor. C<$file> is the YAML file.

=head2 schemaVersion()

Returns a string containing the schema version of the spec file.

=head2 version()

Returns a string containing the version of the spec file.

=head2 lastUpdated()

Returns a string containing the date the spec was last updated.

=head2 preamble()

Returns a L<ICANN::RST::Text> object containing the preamble.

=head2 contactName()

Returns a string containing the contact name.

=head2 contactOrg()

Returns a string containing the contact organisation.

=head2 contactEmail()

Returns a string containing the contact email.

=head2 plans()

Returns an array of L<ICANN::RST::Plan> objects.

=head2 plan($id);

Returns the L<ICANN::RST::Plan> object with the given ID.

=head2 suites()

Returns an array of L<ICANN::RST::Suite> objects.

=head2 suite($id);

Returns the L<ICANN::RST::Suite> object with the given ID.

=head2 cases()

Returns an array of L<ICANN::RST::Case> objects.

=head2 case($id);

Returns the L<ICANN::RST::Case> object with the given ID.

=head2 inputs()

Returns an array of L<ICANN::RST::Input> objects.

=head2 input($id);

Returns the L<ICANN::RST::Input> object with the given ID.

=cut
