# Registry System Testing v2.0 Test Specifications

This repository contains the specifications for the RST v2.0 system.

This system will replace the original Pre-Delegation Testing (later renamed to Registry System
Testing). Unlike its predecessor, the new system is fully automated. All interaction with the system 
is via the RST-API, which is documented at [icann/rst-api-spec](https://github.com/icann/rst-api-spec)

## Repository Contents

* [rst-api-specs.html](rst-api-specs.html) is the human-readable version of the RST test specification.

* [rst-api-specs.yaml](rst-api-specs.yaml) is the machine-readable version, intended to be consumed by the Test Orchestration System (TOS). Like the HTML file above, this file is a build artefact.

* [rst-api-specs.yaml.in](rst-api-specs.yaml.in) is what you need to edit if you want to make changes to the test specifications.

* [Schema.md](Schema.md) documents the schema for the YAML files.

* [Makefile](Makefile) provides a way to generate the build artefacts. It uses [gpp](https://logological.org/gpp) to create the YAML file, and [tools/generate-html.pl](tools/generate-html.pl) to render the HTML file.

## Copyright Statement

This repository is (c) 2023 Internet Corporation for Assigned Names and Numbers (ICANN). All rights reserved.