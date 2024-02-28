This repository contains the specifications for the RST v2.0 service.

## Repository Contents

* The files in [inc/](inc/) are what you need to edit if you want to make
  changes to the test specifications.

* [rst-test-spec-schema.yaml](rst-test-spec-schema.yaml) is a schema for the
  YAML spec file.

* [zonemaster-test-policies.yaml](zonemaster-test-policies.yaml) contains 
  policies that are applied to Zonemaster tests when generating the spec files
  and the Zonemaster profile.

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

## Copyright Statement

This repository is (c) 2024 Internet Corporation for Assigned Names and Numbers
(ICANN). All rights reserved.
