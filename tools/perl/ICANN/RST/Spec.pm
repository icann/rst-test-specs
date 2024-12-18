package ICANN::RST::Spec;
use Carp;
use ICANN::RST::Case;
use ICANN::RST::ChangeLog;
use ICANN::RST::DataProvider;
use ICANN::RST::Error;
use ICANN::RST::Input;
use ICANN::RST::Plan;
use ICANN::RST::Resource;
use ICANN::RST::Suite;
use ICANN::RST::Text;
use YAML::XS;
use List::Util qw(pairmap);
use constant SCHEMA_VERSION => v1.13.0;
use feature qw(say);
use strict;

$YAML::XS::Boolean = q{JSON::PP};

sub new {
    my ($package, $file) = @_;

    my $self = bless(
        {
            'spec' => YAML::XS::LoadFile($file),
            'file' => $file
        },
        $package,
    );

    my $v = version->parse($self->spec->{'RST-Test-Plan-Schema-Version'});
    croak(sprintf("Unsupported schema version '%s', must be '%s'", $v, SCHEMA_VERSION)) unless (SCHEMA_VERSION == $v);

    #
    # precompile everything
    #
    $self->{'_preamble'}    = ICANN::RST::Text->new($self->spec->{'Preamble'});
    $self->{'_plans'}       = [ sort { $a->order <=> $b->order  } pairmap {     ICANN::RST::Plan     -> new($a, $b, $self) } %{$self->spec->{'Test-Plans'}}       ];
    $self->{'_suites'}      = [ sort { $a->order <=> $b->order  } pairmap {     ICANN::RST::Suite    -> new($a, $b, $self) } %{$self->spec->{'Test-Suites'}}      ];
    $self->{'_cases'}       = [ sort {    $a->id cmp $b->id     } pairmap {     ICANN::RST::Case     -> new($a, $b, $self) } %{$self->spec->{'Test-Cases'}}       ];
    $self->{'_inputs'}      = [ sort {    $a->id cmp $b->id     } pairmap {     ICANN::RST::Input    -> new($a, $b, $self) } %{$self->spec->{'Input-Parameters'}} ];
    $self->{'_resources'}   = [ sort {    $a->id cmp $b->id     } pairmap {   ICANN::RST::Resource   -> new($a, $b, $self) } %{$self->spec->{'Resources'}}        ];
    $self->{'_errors'}      = [ sort {    $a->id cmp $b->id     } pairmap {    ICANN::RST::Error     -> new($a, $b, $self) } %{$self->spec->{'Errors'}}           ];
    $self->{'_providers'}   = [ sort {    $a->id cmp $b->id     } pairmap { ICANN::RST::DataProvider -> new($a, $b, $self) } %{$self->spec->{'Data-Providers'}}   ];

    return $self;
}

sub changelog {
    my $self = shift;

    my @log;

    foreach my $date (reverse(sort(keys(%{$self->spec->{'ChangeLog'}})))) {
        push(@log, ICANN::RST::ChangeLog->new($date, $self->spec->{'ChangeLog'}->{$date}, $self));
    }

    return @log;
}

sub spec            { $_[0]->{'spec'}                                                   }
sub schemaVersion   { $_[0]->spec->{'RST-Test-Plan-Schema-Version'}                     }
sub version         { $_[0]->spec->{'Version'}                                          }
sub lastUpdated     { $_[0]->spec->{'Last-Updated'}                                     }
sub contactName     { $_[0]->spec->{'Contact'}->{'Name'}                                }
sub contactOrg      { $_[0]->spec->{'Contact'}->{'Organization'}                        }
sub contactEmail    { $_[0]->spec->{'Contact'}->{'Email'}                               }
sub preamble        { $_[0]->{'_preamble'}                                              }
sub plans           { @{ $_[0]->{'_plans'} }                                            }
sub suites          { @{ $_[0]->{'_suites'} }                                           }
sub cases           { @{ $_[0]->{'_cases'} }                                            }
sub inputs          { @{ $_[0]->{'_inputs'} }                                           }
sub resources       { @{ $_[0]->{'_resources'} }                                        }
sub errors          { @{ $_[0]->{'_errors'} }                                           }
sub providers       { @{ $_[0]->{'_providers'} }                                        }
sub plan            { my ($self, $id) = @_ ; return $self->find($id, $self->plans)      }
sub suite           { my ($self, $id) = @_ ; return $self->find($id, $self->suites)     }
sub case            { my ($self, $id) = @_ ; return $self->find($id, $self->cases)      }
sub resource        { my ($self, $id) = @_ ; return $self->find($id, $self->resources)  }
sub error           { my ($self, $id) = @_ ; return $self->find($id, $self->errors)     }
sub input           { my ($self, $id) = @_ ; return $self->find($id, $self->inputs)     }
sub provider        { my ($self, $id) = @_ ; return $self->find($id, $self->providers)  }

sub find {
    my ($self, $needle, @haystack) = @_;

    foreach my $stick (@haystack) {
        return $stick if ($stick->id eq $needle);
    }

    carp("object '$needle' not found");

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

=head2 changelog()

Returns an array of L<ICANN::RST::ChangeLog> objects.

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

=head2 resources()

Returns an array of L<ICANN::RST::Resource> objects.

=head2 resource($id)

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

=head2 providers()

Returns an array of L<ICANN::RST::Error> objects.

=head2 provider($id)

Returns the L<ICANN::RST::DataProvider> object with the given ID.

=head2 spec()

Returns a hashref of the specification data structure.

=cut
