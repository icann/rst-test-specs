#!/usr/bin/env perl
use Data::Mirror qw(mirror_json);
use JSON::XS;
use IO::File;
use List::Util qw(none);
use constant TEMPLATE_URL => q{https://raw.githubusercontent.com/icann/rdap-conformance-tool/refs/heads/master/tool/bin/rdapct_config.json};
use vars qw($CONFIG @WARNING @IGNORE);
use common::sense;

@WARNING = (
    {
      code  => -23100,
      notes => "The TLD is not included in the bootstrapDomainNameSpace. See section 1.11.1 of the RDAP_Technical_Implementation_Guide_2_1."
    },
    {
      code  => -10102,
      notes => "The IPv4 address is included in the IANA IPv4 Special-Purpose Address Registry. Dataset: specialIPv4Addresses."
    },
    {
      code  => -10202,
      notes => "The IPv6 address is included in the IANA IPv6 Special-Purpose Address Registry. Dataset: specialIPv6Addresses."
    }
);

@IGNORE = (
    -10403,
    -12201,
    -46101,
    -46900,
    -47000,
    -47203,
    -52104,
);

foreach my $code (@WARNING) {
    push(@{$CONFIG->{definitionWarning}}, $code) if (none { $_->{code} == $code->{code} } @{$CONFIG->{definitionWarning}});
}

foreach my $code (@IGNORE) {
    push(@{$CONFIG->{definitionIgnore}}, $code) if (none { $_ == $code } @{$CONFIG->{definitionIgnore}});
}

$CONFIG = mirror_json(TEMPLATE_URL);

$CONFIG->{definitionIdentifier} = q{RDAP Conformance Tool (RDAPCT) Configuration for Registry System Testing (RST) v2.0.};

$CONFIG->{definitionNotes} = [ grep { length > 0 } map { chomp ; $_ } split(/\n/, <<END
This configuration file is based on the default configuration file published in the RDAP Conformance Tool's git repository.
It includes additional options appropriate for the Registry System Testing (RST) v2.0 system.
END
) ];

say JSON::XS->new->pretty->utf8->encode($CONFIG);
