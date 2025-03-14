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

## Building the specification

The simplest way to build the specification is to run `docker compose run spec`
(you obviously need Docker). The first run will take a while as it needs to
build the image, but it will be quite fast after that.

## Branches

The [`main`](https://icann.github.io/rst-api-spec/tree/main) branch is the
"stable" version of the specification. All development is done on the
[`dev`](https://icann.github.io/rst-api-spec/tree/dev) branch. `main` is updated
every Wednesday from the `dev` branch.

## See Also

* [RST API Specification](https://icann.github.io/rst-api-spec) ([GitHub repository](https://github.com/icann/rst-api-spec))
* [IDN test labels for RST v2.0](https://github.com/icann/rst-idn-test-labels)

## Copyright Statement

This repository is (c) 2025 Internet Corporation for Assigned Names and Numbers
(ICANN). All rights reserved.
