This repository contains the specifications for the RST v2.0 service.

This system will replace the original Pre-Delegation Testing (later renamed to
Registry System Testing) service. Unlike its predecessor, the new system is
fully automated. All interaction with the system is via the RST-API, which is
documented at [icann/rst-api-spec](https://icann.github.io/rst-api-spec).

* **[rst-test-specs.html](https://icann.github.io/rst-test-specs/rst-test-specs.html)
  is the human-readable version of the RST test specification.** This is updated
  once per week.

* [rst-test-specs.yaml](https://icann.github.io/rst-test-specs/rst-test-specs.yaml)
  is the machine-readable version, intended to be consumed by internal ICANN
  clients. Like the HTML file above, this file is a build artefact and is
  updated once per week. The YAML file is the normative reference, other
  representations are informational only.

* [rst-test-specs.json](https://icann.github.io/rst-test-specs/rst-test-specs.json)
  is the above file in JSON. Note that the conversion from YAML causes keys in
  dictionaries to be reordered. As with the HTML and YAML versions, this is
  updated once per week.

* [rst.json](https://icann.github.io/rst-test-specs/rst.json) is a Zonemaster
  [profile](https://github.com/zonemaster/zonemaster/blob/master/docs/public/configuration/profiles.md)
  that's generated once per week.

## Repository Contents

* The files in [inc/](inc/) are what you need to edit if you want to make
  changes to the test specifications.

* [rst-test-spec-schema.yaml](rst-test-spec-schema.yaml) is a schema for the
  YAML spec file.

* [zonemaster-test-policies.yaml](zonemaster-test-policies.yaml) contains 
  policies that are applied to Zonemaster tests when generating the spec files
  and the Zonemaster profile.

## Building the specification

The simplest way to build the specification is to run `docker compose up spec`
(you obviously need Docker). The first run will take a while as it needs to
build the image, but it will be quite fast after that.

## Branches

The [`main`](https://icann.github.io/rst-api-spec/tree/main) branch is the
"stable" version of the specification. All development is done on the
[`dev`](https://icann.github.io/rst-api-spec/tree/dev) branch. `main` is updated
every Wednesday from the `dev` branch.

## See Also

* [RST API Specification](https://icann.github.io/rst-api-spec) ([GitHub repository](https://github.com/icann/rst-api-spec))

## Copyright Statement

This repository is (c) 2024 Internet Corporation for Assigned Names and Numbers
(ICANN). All rights reserved.
