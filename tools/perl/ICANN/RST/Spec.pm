package ICANN::RST::Spec;
use Carp;
use ICANN::RST::Case;
use ICANN::RST::Error;
use ICANN::RST::Input;
use ICANN::RST::Plan;
use ICANN::RST::Resource;
use ICANN::RST::Suite;
use ICANN::RST::Text;
use YAML::XS;
use List::Util qw(pairmap);
use constant SCHEMA_VERSION => v1.5.1;
use strict;

sub new {
    my ($package, $file) = @_;
    my $self = bless(
        {
            'spec' => YAML::XS::LoadFile($file),
            'file' => $file
        },
        $package,
    );

    my $v = version->parse($self->{'spec'}->{'RST-Test-Plan-Schema-Version'});
    croak(sprintf("Unsupported schema version '%s', must be '%s'", $v, SCHEMA_VERSION)) unless (SCHEMA_VERSION == $v);

    return $self;
}

sub schemaVersion   { $_[0]->{'spec'}->{'RST-Test-Plan-Schema-Version'}     }
sub version         { $_[0]->{'spec'}->{'Version'}                          }
sub lastUpdated     { $_[0]->{'spec'}->{'Last-Updated'}                     }
sub contactName     { $_[0]->{'spec'}->{'Contact'}->{'Name'}                }
sub contactOrg      { $_[0]->{'spec'}->{'Contact'}->{'Organization'}        }
sub contactEmail    { $_[0]->{'spec'}->{'Contact'}->{'Email'}               }
sub preamble        { ICANN::RST::Text->new($_[0]->{'spec'}->{'Preamble'})  }
sub plans           { my $self = shift ; return sort { $a->order <=> $b->order  } pairmap { ICANN::RST::Plan->new($a,  $b, $self)       } %{$self->{'spec'}->{'Test-Plans'}}        }
sub suites          { my $self = shift ; return sort { $a->order <=> $b->order  } pairmap { ICANN::RST::Suite->new($a, $b, $self)       } %{$self->{'spec'}->{'Test-Suites'}}       }
sub cases           { my $self = shift ; return sort {    $a->id cmp $b->id     } pairmap { ICANN::RST::Case->new($a,  $b, $self)       } %{$self->{'spec'}->{'Test-Cases'}}        }
sub inputs          { my $self = shift ; return sort {    $a->id cmp $b->id     } pairmap { ICANN::RST::Input->new($a, $b, $self)       } %{$self->{'spec'}->{'Input-Parameters'}}  }
sub resources       { my $self = shift ; return sort {    $a->id cmp $b->id     } pairmap { ICANN::RST::Resource->new($a, $b, $self)    } %{$self->{'spec'}->{'Resources'}}         }
sub errors          { my $self = shift ; return sort {    $a->id cmp $b->id     } pairmap { ICANN::RST::Error->new($a, $b, $self)       } %{$self->{'spec'}->{'Errors'}}            }
sub plan            { my ($self, $id) = @_ ; return $self->find($id, $self->plans)      };
sub suite           { my ($self, $id) = @_ ; return $self->find($id, $self->suites)     };
sub case            { my ($self, $id) = @_ ; return $self->find($id, $self->cases)      };
sub input           { my ($self, $id) = @_ ; return $self->find($id, $self->inputs)     };
sub resource        { my ($self, $id) = @_ ; return $self->find($id, $self->resources)  };
sub error           { my ($self, $id) = @_ ; return $self->find($id, $self->errors)     };

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

=head2 plan($id)

Returns the L<ICANN::RST::Plan> object with the given ID.

=head2 suites()

Returns an array of L<ICANN::RST::Suite> objects.

=head2 suite($id)

Returns the L<ICANN::RST::Suite> object with the given ID.

=head2 resources

Returns an array of L<ICANN::RST::Resource> objects.

=head2 resource

Returns the L<ICANN::RST::Resource> object with the given ID.

=head2 cases()

Returns an array of L<ICANN::RST::Case> objects.

=head2 case($id)

Returns the L<ICANN::RST::Case> object with the given ID.

=head2 inputs()

Returns an array of L<ICANN::RST::Input> objects.

=head2 input($id)

Returns the L<ICANN::RST::Input> object with the given ID.

=head2 errors()

Returns an array of L<ICANN::RST::Error> objects.

=head2 error($id)

Returns the L<ICANN::RST::Error> object with the given ID.

=cut
