#!/usr/bin/env perl
use Array::Utils qw(:all);
use Cwd qw(abs_path);
use DateTime::Format::ISO8601;
use Data::Mirror qw(mirror_xml);
use File::Basename qw(dirname);
use File::Glob qw(:bsd_glob);
use File::Spec;
use List::Util qw(none);
use XML::LibXML;
use YAML::XS;
use constant IANA_REGISTRY_NS => q{http://www.iana.org/assignments};
use vars qw($OK);
use common::sense;

$OK = 1;

my $file = abs_path(File::Spec->catfile(dirname(dirname(__FILE__)), qw(epp-extensions epp-extensions.yaml)));

printf(STDERR qq{Loading EPP extension list from %s\n}, $file);
my $list = YAML::XS::LoadFile($file);

printf(STDERR qq{INFO: the EPP extensions list was last updated on %s\n}, $list->{q{last-updated}});

say STDERR q{Mirroring IANA EPP Extension Registry...};
my $registry_xml = mirror_xml(q{https://www.iana.org/assignments/epp-extensions/epp-extensions.xml});

my $updated = $registry_xml->getElementsByTagNameNS(IANA_REGISTRY_NS, q{updated})->item(0)->textContent;
printf(STDERR qq{The EPP Extension Registry was last updated on %s\n}, $updated);

if (DateTime::Format::ISO8601->parse_datetime($list->{q{last-updated}}) <= DateTime::Format::ISO8601->parse_datetime($updated)) {
    say STDERR q{ERROR: the EPP extensions list is out of date!};
    $OK = undef;

} else {
    say STDERR q{INFO: the EPP extensions list is up to date};

}

say STDERR q{Loading target namespace URIs from schema files...};

my @uris =  map { XML::LibXML->load_xml(location => $_)->documentElement->getAttribute(q{targetNamespace}) }
                bsd_glob(abs_path(File::Spec->catfile(dirname(dirname(__FILE__)), qw(epp-extensions xsd *.xsd))));

#
# add these to suppress warnings (they are extensions which don't have a schema)
#
push(@uris, qw(urn:ietf:params:xml:ns:epp:secure-authinfo-transfer-1.0 urn:ietf:params:xml:ns:epp:unhandled-namespaces-1.0));

say STDERR q{Checking extensions...};

#
# pre-populate with the core mappings that aren't listed in the registry#
my $registry = [
    {
        name => q{Extensible Provisioning Protocol (EPP) Domain Name Mapping},
        ref  => q{https://www.rfc-editor.org/rfc/rfc5731.html},
    },
    {
        name => q{Extensible Provisioning Protocol (EPP) Host Mapping},
        ref  => q{https://www.rfc-editor.org/rfc/rfc5732.html},
    },
    {
        name => q{Extensible Provisioning Protocol (EPP) Contact Mapping},
        ref  => q{https://www.rfc-editor.org/rfc/rfc5733.html},
    },
];

#
# parse the IANA registry into an array of hashrefs
#
foreach my $extn ($registry_xml->getElementsByTagNameNS(IANA_REGISTRY_NS, q{record})) {
    my $name = $extn->getElementsByTagNameNS(IANA_REGISTRY_NS, q{name})->item(0)->textContent;

    $name =~ s/[\r\n ]+/ /g;
    $name =~ s/[\[\]]+//g;

    my $url;

    my $xref = [ grep { q{xref} eq $_->localName } $extn->childNodes ]->[0];
    my $xref_type = $xref->getAttribute(q{type});
    my $xref_data = $xref->getAttribute(q{data});

    if (q{uri} eq $xref_type) {
        $url = $xref_data;

    } elsif (q{rfc} eq $xref_type) {
        $url = sprintf(q{https://www.rfc-editor.org/rfc/%s.html}, $xref_data);

    } elsif (q{draft} eq $xref_type) {
        $url = sprintf(q{https://datatracker.ietf.org/doc/html/%s}, $xref_data);

    } else {
        printf(STDERR qq{ERROR: unsupported xref type '%s' (value %s)\n}, $xref_type, $xref_data);
        exit(1);

    }

    push(@{$registry}, {
        name => $name,
        ref  => $url,
    });
}

my @a = sort map { $_->{name}.chr(0).$_->{ref} } @{$registry};
my @b = sort map { $_->{name}.chr(0).$_->{ref} } @{$list->{uris}->{extensions}}, @{$list->{uris}->{objects}};

foreach my $missing (array_minus(@a, @b)) {
    my ($name, $ref) = split(/\0/, $missing, 2);
    printf(STDERR qq{WARNING: the following extension is not present in the local file:\n\n  name: %s\n  ref:  %s\n\n}, $name, $ref);
    $OK = undef;
}

foreach my $missing (array_minus(@b, @a)) {
    my ($name, $ref) = split(/\0/, $missing, 2);
    printf(STDERR qq{WARNING: the following extension is present in the local file but not in the IANA registry:\n\n  name: %s\n  ref:  %s\n\n}, $name, $ref);
    $OK = undef;
}

say STDERR q{Checking XSDs...};

foreach my $entry (@{$list->{uris}->{extensions}}, @{$list->{uris}->{objects}}) {
    if (none { $entry->{uri} eq $_ } @uris) {
        printf(STDERR qq{WARNING: no XSD found for '%s' (namespace '%s')\n}, $entry->{name}, $entry->{uri});
        $OK = undef;
    }
}

say STDERR ($OK ? q{Check completed with no errors} : q{Check completed with error(s)});

exit($OK ? 0 : 1);
