# Registry System Testing v2.0 Test Specifications

[![pages-build-deployment](https://github.com/icann/rst-test-specs/actions/workflows/pages/pages-build-deployment/badge.svg)](https://github.com/icann/rst-test-specs/actions/workflows/pages/pages-build-deployment)

This repository contains the specifications for the RST v2.0 service.

This system will replace the original Pre-Delegation Testing (later renamed to
Registry System Testing) service. Unlike its predecessor, the new system is
fully automated. All interaction with the system is via the RST-API, which is
documented at [icann/rst-api-spec](https://icann.github.io/rst-api-spec).

## Repository Contents

* **[rst-test-specs.html](https://icann.github.io/rst-test-specs/rst-test-specs.html)
  is the human-readable version of the RST test specification.**

* [rst-test-specs.yaml](https://icann.github.io/rst-test-specs/rst-test-specs.yaml)
  is the machine-readable version, intended to be consumed by internal ICANN
  clients. Like the HTML file above, this file is a build artefact.

* [rst-test-specs.json](https://icann.github.io/rst-test-specs/rst-test-specs.json)
  is the above file in JSON, in case you prefer that kind of thing. Note that
  the conversion from YAML causes keys in dictionaries to be reordered.

* The files in [inc/](inc/) are what you need to edit if you want to make
  changes to the test specifications.

* [Schema.md](Schema.md) documents the schema for the YAML files. There is a
  YAML version of this schema in [`rst-test-spec-schema.yaml`](rst-test-spec-schema.yaml).

* [zonemaster-test-policies.yaml](zonemaster-test-policies.yaml) contains the
  policies that are applied to Zonemaster tests.

* [rst.json](https://icann.github.io/rst-test-specs/rst.json) is a Zonemaster
  [profile](https://github.com/zonemaster/zonemaster/blob/master/docs/public/configuration/profiles.md)
  that's generated from the above policy file.

* [Makefile](Makefile) provides a way to generate the build artefacts. It uses
  [gpp](https://logological.org/gpp) to create the YAML file, `perl` and a
  couple of modules to create the JSON file, and
  [tools/generate-html.pl](tools/generate-html.pl) to render the HTML.

* If you don't want to install all the dependencies, but have Docker installed,
  you can use `docker compose up` to build the YAML, JSON and HTML files.

## Branches

The [`main`](https://icann.github.io/rst-api-spec/tree/main) branch is the
"stable" version of the specification. All development is done on the
[`dev`](https://icann.github.io/rst-api-spec/tree/dev) branch. `main` is updated
every Wednesday from the `dev` branch.

## See Also

* [RST API Specification](https://github.com/icann/rst-api-spec)

## Copyright Statement

This repository is (c) 2024 Internet Corporation for Assigned Names and Numbers
(ICANN). All rights reserved.
