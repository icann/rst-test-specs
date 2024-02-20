package ICANN::RST::Input;
use base qw(ICANN::RST::Base);
use JSON::Schema;
use strict;

sub description { ICANN::RST::Text->new($_[0]->{'Description'}) }
sub type        { $_[0]->{'Type'} }
sub example     { $_[0]->{'Example'} }
sub schema      { $_[0]->{'Schema'} ? JSON::Schema->new($_[0]->{'Schema'}) : undef }

sub jsonExample {
    my $self = shift;

    if ('integer' eq $self->type) {
        return int($self->example);

    } elsif ('number' eq $self->type) {
        return 0 + int($self->example);

    } elsif ('boolean' eq $self->type) {
        return ($self->example ? \1 : \0);

    }

    return $self->example;
}

sub cases {
    my $self = shift;

    my %cases;

    foreach my $case ($self->spec->cases) {
        foreach my $input ($case->inputs) {
            $cases{$case->id} = $case if ($input->id eq $self->id && !defined($cases{$case->id}));
        }
    }

    return sort { $a->id cmp $b->id } values(%cases);
}

sub suites {
    my $self = shift;

    my %suites;

    foreach my $suite ($self->spec->suites) {
        foreach my $id (@{$suite->{'Input-Parameters'}}) {
            $suites{$suite->id} = $suite if ($id eq $self->id && !defined($suites{$suite->id}));
        }
    }

    return sort { $a->order cmp $b->order } values(%suites);
}

1;

__END__

=pod

=head1 NAME

ICAN::RST::Input - an object representing an RST input parameter. This class
inherits from L<ICANN::RST::Base> (so it has the C<id()>, C<order()> and
C<spec()> methods).

=head1 METHODS

=head2 description()

A L<ICANN::RST::Text> object containing the long textual description of the test
case.

=head2 type()

A string containing the input type.

=head2 example()

A string containing an example value.

=head2 jsonExample()

A scalar containing the example value coerced into a type that L<JSON::XS>
understands. This ensures that numbers and booleans are properly represented
when encoded into JSON.

=head2 schema()

A hashref containing a L<JSON::Schema> object that can be used to validate this
parameter.

=head2 cases()

A list of all C<ICANN::RST::Case> objects that use this input parameter.

=head2 suites()

A list of all C<ICANN::RST::Suite> objects that use this input parameter.

=cut
