#!/usr/bin/env perl
use Data::Mirror qw(mirror_json);
use JSON::XS;
use IO::File;
use List::Util qw(none);
use constant TEMPLATE_URL => q{https://raw.githubusercontent.com/icann/rdap-conformance-tool/refs/heads/master/tool/bin/rdapct_config.json};
use vars qw($CONFIG @WARNING @IGNORE @IGNORE_OTE $ENVIRONMENTS $ENVIRONMENT);
use common::sense;

$ENVIRONMENTS = {
    OTE     => 1,
    PROD    => 1,
};

if (!exists($ARGV[0])) {
    $ENVIRONMENT = q{PROD};

} else {
    if (exists($ENVIRONMENTS->{$ARGV[0]})) {
        $ENVIRONMENT = $ARGV[0];

    } else {
        printf(STDERR "Invalid argument '%s', must be one of: %s\n", $ARGV[0], join(',', keys(%{$ENVIRONMENTS})));
        exit(1);

    }
}

@WARNING = (
    {
      code  => -23100,
      notes => "The TLD is not included in the bootstrapDomainNameSpace. See section 1.11.1 of the RDAP_Technical_Implementation_Guide_2_1.",
    },
    {
      code  => -10102,
      notes => "The IPv4 address is included in the IANA IPv4 Special-Purpose Address Registry. Dataset: specialIPv4Addresses.",
    },
    {
      code  => -10202,
      notes => "The IPv6 address is included in the IANA IPv6 Special-Purpose Address Registry. Dataset: specialIPv6Addresses.",
    },
);

@IGNORE = (
    -10403,
    -12201,
    -46101,
    -46900,
    -47000,
    -47203,
    -52104,
    -10303,
    -23100,
    -13005,
    -13006,
);

@IGNORE_OTE = (
    -46205,
    -47205,
    -49104,
    -52106,
);

push(@IGNORE, @IGNORE_OTE) if (q{OTE} eq $ENVIRONMENT);

$CONFIG = mirror_json(TEMPLATE_URL);

foreach my $code (@WARNING) {
    push(@{$CONFIG->{definitionWarning}}, $code) if (none { $_->{code} == $code->{code} } @{$CONFIG->{definitionWarning}});
}

foreach my $code (@IGNORE) {
    push(@{$CONFIG->{definitionIgnore}}, $code) if (none { $_ == $code } @{$CONFIG->{definitionIgnore}});
}

if (q{OTE} eq $ENVIRONMENT) {
    $CONFIG->{definitionIdentifier} = q{RDAP Conformance Tool (RDAPCT) Configuration for Registry System Testing (RST) v2.0 Operational Testing & Evaluation (OT&E) Environment.};

} else {
    $CONFIG->{definitionIdentifier} = q{RDAP Conformance Tool (RDAPCT) Configuration for Registry System Testing (RST) v2.0 Production Environment.};

}

$CONFIG->{definitionNotes} = [ grep { length > 0 } map { chomp ; $_ } split(/\n/, <<END
This configuration file is based on the default configuration file published in the RDAP Conformance Tool's git repository.
It includes additional options appropriate for the Registry System Testing (RST) v2.0 system.
END
) ];

push(@{$CONFIG->{definitionNotes}}, q{This file is intended for use in the OT&E environment.}) if (q{OTE} eq $ENVIRONMENT);

say JSON::XS->new->pretty->utf8->encode($CONFIG);
