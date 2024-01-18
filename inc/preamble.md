This file describes each test [plan](#test-plans), [suite](#test-suites) and
[case](#test-cases) in the RST system, as well as the
[input parameters](#input-parameters) required for each, relevant
[resources](#resources), any inter-case dependencies, and the
[errors](#errors) that might occur during testing.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in [RFC
2119](https://www.rfc-editor.org/rfc/rfc2119.html) when, and only when, they
appear in all capitals, as shown here.

# 2.1. Test plans

An individual *Test Plan* addresses a particular scenario (for example, RSP
evaluation or Pre-Delegation Testing). Each plan consists of one or more *test
suites*, which in turn include one or more *test cases*.

## 2.1.1. Test plan types

There are two types of test plan described in this document:

* **Business as usual** plans, which are used as part of the lifecycle of a
gTLD (Pre-Delegion Test, RSP/DNS RSP change Test, IDN Test, SRS Gateway
Test)
* **RSP evaluation** plans, which are used as part of the RSP evaluation
program.

# 2.2. Test suites

A *Test Suite* is a collection of *test cases* with a common theme or subject
matter, for example, Authoritative DNS or Registry Data Escrow.

# 2.3. Test cases

A *Test Case* describes a process for determining the conformance or
acceptability of a certain element of the system.

A test case consists of a *test procedure* which accepts zero or more **input
parameters**, and generates one or more **test results**.

## 2.3.1. Input parameters

All test cases require some information about the subject of the test, for
example, service hostnames, credentials, and functional parameters. These
*input parameters* may be shared across multiple test cases.

## 2.3.2. Test environments

Each test plan indicates whether the test is to be carried out in the
production environment, or whether a test, staging or OT&E environment may be
used. In general, test plans which are designed for "business as usual" use
during the lifecycle of a TLD **MUST** be carried out in the production
registry infrastructure, while RSP evaluation tests **MAY** be carried out in
test, staging or OT&E environments.

## 2.3.3. Test results

Test cases will generate one or more *test results*. Test results indicate the
outcome of the test and other relevant information.

## 2.3.4. General pass/fail criteria

In general, for a test to pass, **all** the test cases specified in the test
suite(s) for the test plan **MUST** pass: if *any* fail, then the test as a
whole will fail.

A test case will fail if it produces one or more [errors](#errors) with the
`ERROR` or `CRITICAL` severities.

## 2.3.5. Error severity levels

The supported severity levels are a subset of the values defined in RFC 5424.

2. `WARNING` - an issue which does not prevent the test from *passing*, but
 which may benefit from further investigation.
1. `ERROR` - an issue which prevents the test case from *passing*, but does not
 prevent the test case from *continuing*. A test case may produce multiple
 `ERROR` results.
2. `CRITICAL` - an issue which prevents the test case from continuing any
 further. A test case will only produce a single `CRITICAL` result and it
 will always be the last result in the log.

## 2.3.6. Common errors

For each test case, various errors and critical errors are defined which will
be used to signal why that the case might have failed.

In addition to these, there are a number of errors which any test case may
produce, which are:

* [TBA]

# 2.4. Key acronyms and terms

RST
: Registry System Testing. This system.

PDT
: Pre-Delegation Test. A test carried out prior to the delegation of a new TLD
into the DNS root zone.

RSP
: Registry Service Provider. A specialist provider of critical registry
services.

DNS
: Domain Name System. The internet's system of globally unique identifiers.

TLD
: Top-level domain. The highest level of the DNS namespace hierarchy.

gTLD
: generic top-level domain.

DNSSEC
: DNS Security Extensions. DNSSEC is described in [BCP
237](https://www.rfc-editor.org/info/bcp237).

EPP
: Extensible Provisioning Protocol. The protocol used by registrars to create
and manage domain name registrations in an SRS. EPP is defined in [STD
69](https://www.rfc-editor.org/info/std69).

SRS
: Shared Registry System. A TLD registry in which registrations are managed
by one or more registrars, using EPP.

RDDS
: Registration Data Directory Services. A service to provide access to
data about domain registrations to third parties.

RDAP
: Registration Data Access Protocol. The protocol used to deliver the RDDS.
RDAP is defined in [STD 95](https://www.rfc-editor.org/info/std95).

RDE
: Registry Data Escrow. A system whereby the registration data stored in a
Shared Registry System is backed up to a trusted third party. RDE is defined
in [RFC 8909](https://www.rfc-editor.org/info/rfc8909) and [RFC
9022](https://www.rfc-editor.org/info/rfc9022).

IDN
: Internationalized Domain Name. A domain name that contains characters not in
the ASCII character set. The technical specification for IDNs may be found in
[RFC 5890](https://www.rfc-editor.org/info/rfc5890). All gTLDs must comply
with ICANN's [IDN
Guidelines](https://www.icann.org/resources/pages/implementation-guidelines-2012-02-25-en).

LGR
: Label Generation Ruleset. The rules by which IDNs are validated. LGRs are
described in [RFC 7940](https://www.rfc-editor.org/info/rfc7940).

RO
: Registry Operator. The entity to which ICANN has granted the right to
operate a gTLD.

RA
: Registry Agreement. The contract between a Registry Operator and ICANN. The
base Registry Agreement may be reviewed at
<https://www.icann.org/en/registry-agreements/base-agreement>.

KSK
: Key Signing Key. A cryptographic key which acts as the Secure Entry Point
for a DNS zone, and which signs a DNS zone's ZSKs. A digest of this key is
published in the parent zone (ie. the root zone for a TLD).

ZSK
: Zone Signing Key. A cryptographic key which signs a DNS zone's resource
records.

CSK
: Combined Signing Key. A cryptographic key used as **both** a KSK and a ZSK.

RPMs
: Rights Protection Mechanisms, intended to discourage or prevent registration
of domain names that violate or abuse another party’s legal rights. These
**MUST** include (but are not limited to): (1) Sunrise Periods, and (2)
Trademark Claims Periods (see [Specification 7 of the Registry
Agreement](https://itp.cdn.icann.org/en/files/registry-agreements/base-registry-agreement-30-04-2023-en.html#specification7)).

TMCH
: Trademark Clearinghouse. The system established by ICANN to maintain a
database of validated and registered trademarks which is used to enforce
Rights Protection Mechanisms (RPMs) in gTLDs. The functional specifications of
the TMCH are defined in [RFC 9361](https://www.rfc-editor.org/info/rfc9361).

SLA
: Service Level Agreement. The registry performance specifications laid out in
[Specification 10 of the Registry
Agreement](https://itp.cdn.icann.org/en/files/registry-agreements/base-registry-agreement-30-04-2023-en.html#specification10).

RRI
: Registration Reporting Interfaces. The interfaces provided by ICANN to
contracted parties including Registry Operators to fulfill and monitor their
applicable reporting requirements, including per-registrar transaction
reports; registry functions activity reports; data escrow deposits reports and
data escrow deposits notifications. For registry operators, the relevant
interfaces are defined in [draft-lozano-icann-registry-interfaces](https://datatracker.ietf.org/doc/html/draft-lozano-icann-registry-interfaces).
