<?php

/*

This script takes the output from 0.docx2html.sh, parses it, and emits a YAML fragment
containing the "Test-Cases" part of rst-spec.yaml

Usage: php 1.parse-html.php FILE > test-cases.yaml

*/

require __DIR__.'/vendor/autoload.php';

use Symfony\Component\Yaml\Yaml;

$summaries = [
    'DNS01' => 'Minimum number of name servers',
    'DNS02' => 'Name server reachability',
    'DNS03' => 'Answer authoritatively',
    'DNS04' => 'Network diversity',
    'DNS05' => 'Consistency between glue and authoritative data',
    'DNS06' => 'Consistency between delegation and zone',
    'DNS07' => 'SOA record consistency between authoritative name servers',
    'DNS08' => 'NS record consistency between authoritative name servers',
    'DNS09' => 'No truncation of referrals',
    'DNS10' => 'Prohibited networks',
    'DNS11' => 'No open recursive name service',
    'DNS12' => 'Same source address',
    'DNS14' => 'Legal values for the DS hash digest algorithm',
    'DNS15' => 'DS must match a DNSKEY in the designated zone',
    'DNS16' => 'Signatures in the designated zone must validate',
    'DNS17' => 'Zone contains NSEC or NSEC3 records',
    'DNS18' => 'Consistency between glue and authoritative data',
    'DNS19' => 'SOA record consistency between authoritative name servers',
    'DNS20' => 'NS record consistency between authoritative name servers',
    'DNS21' => 'No open recursive name service',
    'DNS23' => 'Syntax for SOA RNAME',
    'DNS24' => 'SOA Minimum',
    'DNS25' => 'NSEC3 Iterations',
    'DNS26' => 'RRSIG Lifetimes',
    'DNS27' => 'DNSKEY Algorithms',
    'DNS28' => 'DS TTL',
    'DNS29' => 'Wildcards',
    'DNS30' => 'Dotless domain',
    'DNS31' => 'nic.<TLD> or whois.nic.<TLD> must be delegated',
    'DNS32' => 'Name server reachability',
    'DNS33' => 'Answer authoritatively',
    'DNS34' => 'Consistency between delegation and zone',
    'DNS35' => 'Name server must be able to provide referral to known subdomains',
    'DNS36' => 'RRSIG(SOA) must validate with supplied DS record',
    'DataEscrowContent01' => 'Validate content, full escrow',
    'DataEscrowContent02' => 'Validate content, differential escrow',
    'DataEscrowFileName01' => 'Verify file names, full escrow',
    'DataEscrowFileName02' => 'Verify file names, differential escrow',
    'DataEscrowVerify01' => 'Verify signatures, full escrow',
    'DataEscrowVerify02' => 'Verify signatures, differential escrow',
    'DocDNS01' => 'Capacity and DDOS mitigation',
    'DocDNS02' => 'Load capacity, latency and network reachability',
    'DocDNS03' => 'Load capacity – tables and graphs',
    'DocDNS04' => 'Load capacity – 20 data points',
    'DocDNS05' => 'Query latency',
    'DocDNS06' => 'TCP reachability',
    'DocDNS07' => 'Basic DNSSEC support',
    'DocDNS08' => 'Name server consistency',
    'DocDPS01' => 'DNSSEC Practice Statement – Structure',
    'DocDPS02' => 'DNSSEC Practice Statement – Content',
    'DocEPP01' => 'EPP capacity',
    'DocEPP02' => 'EPP TPS',
    'DocEPP03' => 'EPP landrush',
    'DocEPP04' => 'EPP extensions',
    'DocEscr01' => 'Data Escrow Agreement',
    'DocSL01' => 'DNS SLA',
    'DocSL02' => 'Whois SLA',
    'DocSL03' => 'EPP SLA',
    'DocWhois01' => 'Maximum QPS',
    'DocWhois02' => 'Data mining',
    'EPPConCreate 01' => 'Create a contact',
    'EPPConDelete01' => 'Delete a contact',
    'EPPContactUpdate01' => 'Update a contact',
    'EPPDomCreate01' => 'Create a domain',
    'EPPDomCreate02' => 'Add hosts to existing domain',
    'EPPDomCreate03' => 'Create a DNSSEC-signed domain',
    'EPPDomDelete01' => 'Delete a domain',
    'EPPDomRenew01' => 'Renew a domain',
    'EPPDomTransfer01' => 'Request transfer of a domain',
    'EPPDomTransfer02' => 'Approve a requested domain transfer',
    'EPPDomUpdate01' => 'Add DNSSEC records to a domain',
    'EPPExtensions' => 'Verify required EPP extensions',
    'EPPHostDelete01' => 'Delete a host',
    'EPPHostUpdate01' => 'Update a host',
    'EppConnTest' => 'Verify connectivity',
    'IDNvalid00' => 'IDN documentation validation',
    'IDNvalid01' => 'IDN Table validation',
    'IDNvalid02' => 'IDNA Code Point validation',
    'IDNvalid03' => 'Contextual Rule validation',
    'IDNvalid04' => 'IDN Script validation',
    'IDNvalid05' => 'IDN Script Mixing Rule validation',
    'IDNvalid06' => 'IDN Language validation',
    'IDNvalid07' => 'Variant Code Point validation',
    'IDNvalid09' => 'Variant Management Policy',
    'IDNvalid10' => 'Basic IDN compliance',
    'IDNvalid11' => 'IDN online registry response validation ',
    'IDNvalid12' => 'Asymmetrical and intransitive variant rule verification',
    'IDNvalid13' => 'Pre-composed vs. decomposed character equivalence verification',
    'SRSGWAddrVer' => 'Verify IP addresses to SRS Gateway System',
    'SRSGWConCreate01' => 'Create a contact and verify that TLD SRS is updated',
    'SRSGWConDelete01' => 'Delete a contact and verify that TLD SRS is updated',
    'SRSGWConUpdate01' => 'Update a contact and verify that TLD SRS is updated',
    'SRSGWConnTest' => 'Verify connectivity',
    'SRSGWDomCreate01' => 'Create a domain and verify that TLD SRS is updated',
    'SRSGWDomCreate02' => 'Add hosts to a domain and verify that TLD SRS is updated',
    'SRSGWDomCreate03' => 'Create DNSSEC-signed domain and verify TLD SRS is updated',
    'SRSGWDomDelete01' => 'Delete a domain and verify TLD SRS is updated',
    'SRSGWDomRenew01' => 'Renew a domain and verify that TLD SRS is updated',
    'SRSGWDomTransfer01' => 'Request transfer of a domain and verify TLD SRS is updated',
    'SRSGWDomTransfer02' => 'Approve a domain transfer and verify TLD SRS is updated',
    'SRSGWDomUpdate01' => 'Add DNSSEC records to a domain, verify TLD SRS is updated',
    'SRSGWHostDelete01' => 'Delete a host and verify that TLD SRS is updated',
    'SRSGWHostUpdate01' => 'Update a host and verify that TLD SRS is updated',
    'SRSGWWhoisCLI01' => 'Verify consistency for domain name objects',
    'SRSGWWhoisCLI02' => 'Verify consistency for registrar objects',
    'SRSGWWhoisCLI03' => 'Verify consistency for name server objects',
    'TLDSRSEPPConDelete01' => 'Delete a contact',
    'TLDSRSEPPConUpdate01' => 'Update a contact',
    'TLDSRSEPPConnTest' => 'Verify connectivity',
    'TLDSRSEPPDomCreate01' => 'Create a domain',
    'TLDSRSEPPDomCreate02' => 'Add hosts to existing domain',
    'TLDSRSEPPDomCreate03' => 'Create a DNSSEC-signed domain',
    'TLDSRSEPPDomDelete01' => 'Delete a domain',
    'TLDSRSEPPDomRenew01' => 'Renew a domain',
    'TLDSRSEPPDomTransfer01' => 'Request transfer of a domain',
    'TLDSRSEPPDomTransfer02' => 'Approve a requested domain transfer',
    'TLDSRSEPPDomUpdate01' => 'Add DNSSEC records to a domain',
    'TLDSRSEPPHostDelete01' => 'Delete a host',
    'TLDSRSEPPHostUpdate01' => 'Update a host',
    'TLDSRSEppConCreate01' => 'Create a contact',
    'WhoisCLI01 ' => 'Query for domain name',
    'WhoisCLI02 ' => 'Query for registrar',
    'WhoisCLI03 ' => 'Query for name server',
    'WhoisSearch00' => 'Verify if Whois Search is supported',
    'WhoisSearch01' => 'Verify abuse protection',
    'WhoisSearch02' => 'Partial Match capabilities',
    'WhoisSearch03' => 'Exact Match search',
    'WhoisSearch04' => 'Boolean Search capabilities',
    'WhoisSearch09' => 'Search over IPv6',
    'WhoisWeb01 ' => 'Verify IPv4 connectivity',
    'WhoisWeb02 ' => 'Verify IPv6 connectivity',
    'WhoisWeb03' => 'Manual query for domain name',
    'WhoisWeb04' => 'Manual query for registrar',
    'WhoisWeb05' => 'Manual query for name server',
    'WhoisWeb09' => 'Manual query for domain name over IPv6',
];

$cases = [];

libxml_use_internal_errors(true);

$doc = new DOMDocument('1.0', 'UTF-8');
$doc->preserveWhiteSpace = false;
$doc->formatOutput = true;

if (true !== $doc->loadHTMLFile($argv[1], LIBXML_NOBLANKS | LIBXML_NOCDATA)) {
    foreach (libxml_get_errors() as $error) {
        if ($error->level > LIBXML_ERR_WARNING) {
            var_export($error);
            exit(1);
        }
    }
}

$headers = $doc->getElementsByTagName('h1');

for ($i = 0 ; $i < $headers->length ; $i++) {
    $el = $headers->item($i);

    if (isTestCaseSectionHeader($el)) {
        $title = trim(preg_replace('/[ \t\r\n]+/', ' ', $el->textContent));
        preg_match('/^Test Case ([^:]+):/i', $title, $matches);
        $id = $matches[1];

        $siblings = [];
        foreach ($el->parentNode->childNodes as $node) $siblings[] = $node;

        $content = [];

        for ($j = 0 ; $j < count($siblings) ; $j++) {
            if ($siblings[$j] === $el) break;
        }

        for ($j = 1 + $j ; $j < count($siblings) ; $j++) {
            $sib = $siblings[$j];

            if (isTestCaseSectionHeader($sib)) break;

            if (!$sib instanceof DOMText || strlen(trim($sib->textContent)) > 0) $content[] = $sib;
        }

        if ('h2' == $content[0]->localName && 1 == preg_match('/test case identifier/i', $content[0]->textContent)) {
            array_shift($content);
            $nid = array_shift($content)->textContent;

            if (0 != strcasecmp($nid, $id)) $id = $nid;
        }

        $proc = proc_open(  
            ['pandoc', '-f', 'html', '-t', 'markdown', '--reference-links=false'],
            [['pipe', 'r'], ['pipe', 'w']],
            $pipes,
        );

        foreach ($content as $el) fwrite($pipes[0], $doc->saveHTML($el));
        fclose($pipes[0]);

        $markdown = stream_get_contents($pipes[1]);
        fclose($pipes[1]);

        proc_close($proc);

        $cases[$id] = [
            'Summary'       => $summaries[$id] ?? '',
            'Description'   => $markdown,
        ];
    }
}

echo Yaml::dump(['Test-Cases' => $cases], PHP_INT_MAX, 2, Yaml::DUMP_MULTI_LINE_LITERAL_BLOCK);

function isTestCaseSectionHeader(DOMNode $el) : bool {
    if (!($el instanceof DOMElement)) return false;
    if ('h1' != $el->localName) return false;

    $title = trim(preg_replace('/[ \t\r\n]+/', ' ', $el->textContent));

    return (1 == preg_match('/^Test Case ([^:]+):/i', $title));
}
