#!/usr/bin/env perl
use Data::Mirror qw(mirror_json);
use JSON::XS;
use IO::File;
use List::Util qw(none);
use constant TEMPLATE_URL => q{https://raw.githubusercontent.com/icann/rdap-conformance-tool/refs/heads/master/tool/bin/rdapct_config.json};
use vars qw($CONFIG @WARNING @IGNORE @IGNORE_RSP $USAGES $USAGE);
use common::sense;

$USAGES = {
    RSP     => 1,
    PROD    => 1,
};

if (!exists($ARGV[0])) {
    $USAGE = q{PROD};

} else {
    if (exists($USAGES->{$ARGV[0]})) {
        $USAGE = $ARGV[0];

    } else {
        printf(STDERR "Invalid argument '%s', must be one of: %s\n", $ARGV[0], join(',', keys(%{$USAGES})));
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
    -11703,
    -12205,
    -12405, 
    -12206,
    -11603,
    -12406,
    -10611,
    -10704,
    -12217,
    -10100,
    -11100,
    -12215,
    -10402,
    -10200,
    -999,
    -11404,
    -11406,
    -11407,
    -11409,
    -12412,
    -12414,

    -23202, # to be removed once v3.1.0 of the RCT is integrated
);

#
# these codes all pertain to the use of "ICANNRST" as a repository ID in domain,
# nameserver and entity handles, so should be ignored during RSP evaluation
# tests.
#
@IGNORE_RSP = (
    -46205,
    -47205,
    -49104,
    -52106,
);

push(@IGNORE, @IGNORE_RSP) if (q{RSP} eq $USAGE);

$CONFIG = mirror_json(TEMPLATE_URL);

foreach my $code (@WARNING) {
    push(@{$CONFIG->{definitionWarning}}, $code) if (none { $_->{code} == $code->{code} } @{$CONFIG->{definitionWarning}});
}

foreach my $code (@IGNORE) {
    push(@{$CONFIG->{definitionIgnore}}, $code) if (none { $_ == $code } @{$CONFIG->{definitionIgnore}});
}

if (q{RSP} eq $USAGE) {
    $CONFIG->{definitionIdentifier} = q{RDAP Conformance Tool (RDAPCT) Configuration for Registry System Testing (RST) v2.0 Registry Service Provider (RSP) evaluation.};

} else {
    $CONFIG->{definitionIdentifier} = q{RDAP Conformance Tool (RDAPCT) Configuration for Registry System Testing (RST) v2.0.};

}

$CONFIG->{definitionNotes} = [ grep { length > 0 } map { chomp ; $_ } split(/\n/, <<END
This configuration file is based on the default configuration file published in the RDAP Conformance Tool's git repository.
It includes additional options appropriate for the Registry System Testing (RST) v2.0 system.
END
) ];

push(@{$CONFIG->{definitionNotes}}, q{This file is intended for use in Registry Service Provider (RSP) evaluation.}) if (q{RSP} eq $USAGE);

say JSON::XS->new->pretty->utf8->canonical->encode($CONFIG);
