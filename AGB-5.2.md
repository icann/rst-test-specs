## 5.2 Pre-Delegation Testing

Each applicant will be required to complete pre-delegation technical testing as a prerequisite to delegation into the root zone. This pre-delegation test must be completed within the time period specified in the registry agreement.

The purpose of the pre-delegation technical test is to verify that the applicant has met its commitment to establish registry operations in accordance with the technical and operational criteria described in Module 2.

The test is also intended to indicate that the applicant can operate the gTLD in a stable and secure manner. All applicants will be tested on a pass/fail basis according to the requirements that follow.

The test elements cover both the DNS server operational infrastructure and registry system operations. In many cases the applicant will perform the test elements as instructed and provide documentation of the results to ICANN to demonstrate satisfactory performance. At ICANN’s discretion, aspects of the applicant’s self-certification documentation can be audited either on-site at the services delivery point of the registry or elsewhere as determined by ICANN.

### 5.2.1 Testing Procedures

The applicant may initiate the pre-delegation test by submitting to ICANN the Pre-Delegation form and accompanying documents containing all of the following information:

* All name server names and IPv4/IPv6 addresses to be used in serving the new TLD data;
* If using anycast, the list of names and IPv4/IPv6 unicast addresses allowing the identification of each individual server in the anycast sets;
* If IDN is supported, the complete IDN tables used in the registry system;
* A test zone for the new TLD must be signed at test time and the valid key-set to be used at the time of testing must be provided to ICANN in the documentation, as well as the TLD DNSSEC Policy Statement (DPS);
* The executed agreement between the selected escrow agent and the applicant; and
* Self-certification documentation as described below for each test item.

ICANN will review the material submitted and in some cases perform tests in addition to those conducted by the applicant. After testing, ICANN will assemble a report with the outcome of the tests and provide that report to the applicant.

Any clarification request, additional information request, or other request generated in the process will be highlighted and listed in the report sent to the applicant.

ICANN may request the applicant to complete load tests considering an aggregated load where a single entity is performing registry services for multiple TLDs.

Once an applicant has met all of the pre-delegation testing requirements, it is eligible to request delegation of its applied-for gTLD.

If an applicant does not complete the pre-delegation steps within the time period specified in the registry agreement, ICANN reserves the right to terminate the registry agreement.

### 5.2.2 Test Elements: DNS Infrastructure

The first set of test elements concerns the DNS infrastructure of the new gTLD. In all tests of the DNS infrastructure, all requirements are independent of whether IPv4 or IPv6 is used. All tests shall be done both over IPv4 and IPv6, with reports providing results according to both protocols.

**UDP Support --** The DNS infrastructure to which these tests apply comprises the complete set of servers and network infrastructure to be used by the chosen providers to deliver DNS service for the new gTLD to the Internet. The documentation provided by the applicant must include the results from a system performance test indicating available network and server capacity and an estimate of expected capacity during normal operation to ensure stable service as well as to adequately address Distributed Denial of Service (DDoS) attacks.

Self-certification documentation shall include data on load capacity, latency and network reachability.

Load capacity shall be reported using a table, and a corresponding graph, showing percentage of queries responded against an increasing number of queries per second generated from local (to the servers) traffic generators. The table shall include at least 20 data points and loads of UDP-based queries that will cause up to 10% query loss against a randomly selected subset of servers within the applicant’s DNS infrastructure. Responses must either contain zone data or be `NXDOMAIN` or `NODATA` responses to be considered valid.

Query latency shall be reported in milliseconds as measured by DNS probes located just outside the border routers of the physical network hosting the name servers, from a network topology point of view.

Reachability will be documented by providing information on the transit and peering arrangements for the DNS server locations, listing the AS numbers of the transit providers or peers at each point of presence and available bandwidth at those points of presence.

**TCP support --** TCP transport service for DNS queries and responses must be enabled and provisioned for expected load. ICANN will review the capacity self-certification documentation provided by the applicant and will perform TCP reachability and transaction capability tests across a randomly selected subset of the name servers within the applicant’s DNS infrastructure. In case of use of anycast, each individual server in each anycast set will be tested.

Self-certification documentation shall include data on load capacity, latency and external network reachability.

Load capacity shall be reported using a table, and a corresponding graph, showing percentage of queries that generated a valid (zone data, `NODATA`, or `NXDOMAIN`) response against an increasing number of queries per second generated from local (to the name servers) traffic generators. The table shall include at least 20 data points and loads that will cause up to 10% query loss (either due to connection timeout or connection reset) against a randomly selected subset of servers within the applicant’s DNS infrastructure.

Query latency will be reported in milliseconds as measured by DNS probes located just outside the border routers of the physical network hosting the name servers, from a network topology point of view.

Reachability will be documented by providing records of TCP-based DNS queries from nodes external to the network hosting the servers. These locations may be the same as those used for measuring latency above.

**DNSSEC support --** Applicant must demonstrate support for EDNS(0) in its server infrastructure, the ability to return correct DNSSEC-related resource records such as `DNSKEY`, `RRSIG`, and `NSEC`/`NSEC3` for the signed zone, and the ability to accept and publish DS resource records from second-level domain administrators. In particular, the applicant must demonstrate its ability to support the full life cycle of KSK and ZSK keys. ICANN will review the self-certification materials as well as test the reachability, response sizes, and DNS transaction capacity for DNS queries using the EDNS(0) protocol extension with the “DNSSEC OK” bit set for a randomly selected subset of all name servers within the applicant’s DNS infrastructure. In case of use of anycast, each individual server in each anycast set will be tested.

Load capacity, query latency, and reachability shall be documented as for UDP and TCP above.

### 5.2.3 Test Elements: Registry Systems

As documented in the registry agreement, registries must provide support for EPP within their Shared Registration System, and provide Whois service both via port 43 and a web interface, in addition to support for the DNS. This section details the requirements for testing these registry systems.

**System performance --** The registry system must scale to meet the performance requirements described in Specification 10 of the registry agreement and ICANN will require self-certification of compliance. ICANN will review the self-certification documentation provided by the applicant to verify adherence to these minimum requirements.

**Whois support --** Applicant must provision Whois services for the anticipated load. ICANN will verify that Whois data is accessible over IPv4 and IPv6 via both TCP port 43 and via a web interface and review self-certification documentation regarding Whois transaction capacity. Response format according to Specification 4 of the registry agreement and access to Whois (both port 43 and via web) will be tested by ICANN remotely from various points on the Internet over both IPv4 and IPv6.

Self-certification documents shall describe the maximum number of queries per second successfully handled by both the port 43 servers as well as the web interface, together with an applicant-provided load expectation.

Additionally, a description of deployed control functions to detect and mitigate data mining of the Whois database shall be documented.

**EPP Support --** As part of a shared registration service, applicant must provision EPP services for the anticipated load. ICANN will verify conformance to appropriate RFCs (including EPP extensions for DNSSEC). ICANN will also review self-certification documentation regarding EPP transaction capacity.

Documentation shall provide a maximum Transaction per Second rate for the EPP interface with 10 data points corresponding to registry database sizes from 0 (empty) to the expected size after one year of operation, as determined by applicant.

Documentation shall also describe measures taken to handle load during initial registry operations, such as a land-rush period.

**IPv6 support --** The ability of the registry to support registrars adding, changing, and removing IPv6 DNS records supplied by registrants will be tested by ICANN. If the registry supports EPP access via IPv6, this will be tested by ICANN remotely from various points on the Internet.

**DNSSEC support --** ICANN will review the ability of the registry to support registrars adding, changing, and removing DNSSEC-related resource records as well as the registry’s overall key management procedures. In particular, the applicant must demonstrate its ability to support the full life cycle of key changes for child domains. Inter-operation of the applicant’s secure communication channels with the IANA for trust anchor material exchange will be verified.

The practice and policy document (also known as the DNSSEC Policy Statement or DPS), describing key material storage, access and usage for its own keys is also reviewed as part of this step.

**IDN support --** ICANN will verify the complete IDN table(s) used in the registry system. The table(s) must comply with the guidelines in <http://iana.org/procedures/idn-repository.html>.

Requirements related to IDN for Whois are being developed. After these requirements are developed, prospective registries will be expected to comply with published IDN-related Whois requirements as part of pre-delegation testing.

**Escrow deposit --** The applicant-provided samples of data deposit that include both a full and an incremental deposit showing correct type and formatting of content will be reviewed. Special attention will be given to the agreement with the escrow provider to ensure that escrowed data can be released within 24 hours should it be necessary. ICANN may, at its option, ask an independent third party to demonstrate the reconstitutability of the registry from escrowed data. ICANN may elect to test the data release process with the escrow agent.
