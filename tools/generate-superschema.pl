#!/usr/bin/env perl
use Cwd qw(abs_path);
use File::Basename qw(basename dirname);
use File::Glob qw(:bsd_glob);
use File::Spec;
use POSIX qw(strftime);
use XML::LibXML;
use common::sense;

my $dir = File::Spec->catdir(dirname(dirname(abs_path(__FILE__))), qw(epp-extensions xsd));

my $super = XML::LibXML::Document->new;
$super->appendChild($super->createComment(sprintf(' EPP "super schema" generated on %s ', strftime('%Y-%m-%dT%H:%M:%SZ', gmtime()))));

$super->setDocumentElement($super->createElementNS(q{http://www.w3.org/2001/XMLSchema}, q{schema}));

foreach my $file (bsd_glob(sprintf('%s/*.xsd', $dir))) {
	my $xsd = XML::LibXML->load_xml(location => $file);

	my $import = $super->createElement(q{import});
	$import->setAttribute(namespace => $xsd->documentElement->getAttribute(q{targetNamespace}));
	$import->setAttribute(schemaLocation => basename($file));

	$super->documentElement->appendChild($import);
}

print $super->toString(1);
