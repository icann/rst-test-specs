> [!TIP]
> [Click here to go directly to the current RST test specifications.](https://icann.github.io/rst-test-specs/rst-test-specs.html)

This repository contains the specifications for ICANN's [Registry System Testing
(RST)](https://icann.org/resources/registry-system-testing-v2.0) v2.0 service.

## Repository Contents

* The files in [inc/](inc/) are what you need to edit if you want to make
  changes to the test specifications.

* [rst-test-spec-schema.yaml](rst-test-spec-schema.yaml) is a schema for the
  YAML spec file.

* [zonemaster-test-policies.yaml](zonemaster-test-policies.yaml) contains
  policies that are applied to Zonemaster tests when generating the spec files
  and the Zonemaster profile.

* The [data](data) directory contains the XLSX files from which the [data
  providers](https://icann.github.io/rst-test-specs/rst-test-specs.html#Preamble-2.3.2.-Data-providers)
  are generated.

* The [resources](resources) directory contains static
  [resources](https://icann.github.io/rst-test-specs/rst-test-specs.html#Preamble-2.3.3.-Resources).

* The [.env](.env) file specifies which version of Zonemaster should be used to
  generate DNS and DNSSEC test cases, and their associated error codes.
  [zonemaster-test-policies.yaml](zonemaster-test-policies.yaml) controls how
  the Zonemaster test cases and documentation should be incorporated into the
  RST specs.

## Building the specification

The simplest way to build the specification is to run `docker compose run spec`
(you obviously need Docker). The first run will take a while as it needs to
build the image, but it will be quite fast after that.

## Releasing a new version

1. Make the changes you want to make.
2. Once committed, tag the commit. The tag **MUST** take the form `vYYYY.DD`
   where `YYYY` is the current year and `DD` is a two-digit serial number that
   resets to `01` at the start of each year. Then push the tag to GitHub using
   `git push --tags.
3. Create a new [release](https://github.com/icann/rst-test-specs/releases/new)
   using the tag.

Since the [RST API spec](https://github.com/icann/rst-api-spec) includes data
elements from the test specs, every time a new version of the RST spec is
released, a [new version of the API
spec](https://github.com/icann/rst-api-spec?tab=readme-ov-file#releasing-a-new-version)
must also be released, in order to incorporate any changes to those data
elements.

## See Also

* [RST API Specification](https://icann.github.io/rst-api-spec) ([GitHub repository](https://github.com/icann/rst-api-spec))
* [IDN test labels for RST v2.0](https://github.com/icann/rst-idn-test-labels)

## Copyright Statement

This repository is (c) 2025 Internet Corporation for Assigned Names and Numbers
(ICANN). All rights reserved.
