package ICANN::RST::Input;
use base qw(ICANN::RST::Base);
use JSON::Schema;
use strict;

sub description { ICANN::RST::Text->new($_[0]->{'Description'}) }
sub type        { $_[0]->{'Type'} }
sub example     { numify($_[0]->{'Example'}) }
sub schema      { $_[0]->{'Schema'} ? JSON::Schema->new(numify($_[0]->{'Schema'})) : undef }
sub required    { exists($_[0]->{'Required'}) && $_[0]->{'Required'} }

sub jsonExample {
    my $self = shift;

    if ('boolean' eq $self->{'Schema'}->{'type'}) {
        return ($self->example ? \1 : \0);

    } else {
        return numify($self->example);

    }
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

#
# iteratively convert scalars into numeric values where appropriate
#
sub numify {
    my $value = shift;

    if ('HASH' eq ref($value)) {
        return numify_hash($value);

    } elsif ('ARRAY' eq ref($value)) {
        return numify_array($value);

    } else {
        return numify_scalar($value);

    }
}

sub numify_hash {
    my $ref = shift;

    my $ref2 = {};
    foreach my $key (keys(%{$ref})) {
        $ref2->{$key} = numify($ref->{$key});
    }

    return $ref2;
}

sub numify_array {
    my $ref = shift;

    my @array;
    foreach my $value (@{$ref}) {
        push (@array, numify($value));
    }

    return \@array;
}

sub numify_scalar {
    my $value = shift;

    if (q{JSON::PP::Boolean} ne ref($value) && $value =~ /^\d+\.?\d*$/) {
        $value += 0;
    }

    return $value;
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

=head2 required()

Whether or not this input parameter is required.

=cut
