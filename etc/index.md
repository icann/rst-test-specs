This site hosts the specifications for the Registry System Testing (RST) v2.0 service.

This system will replace the original Pre-Delegation Testing (later renamed to
Registry System Testing) service. Unlike its predecessor, the new system is
fully automated. All interaction with the system is via the
[RST-API](https://icann.github.io/rst-api-spec).

* **[rst-test-specs.html](rst-test-specs.html)
  is the human-readable version of the RST test specification.** This is updated
  once per week.

* [rst-test-specs.yaml](rst-test-specs.yaml)
  is the machine-readable version, intended to be consumed by internal ICANN
  clients. Like the HTML file above, this file is a build artefact and is
  updated once per week. The YAML file is the normative reference, other
  representations are informational only.

* [rst-test-specs.json](rst-test-specs.json)
  is the above file in JSON. Note that the conversion from YAML causes keys in
  dictionaries to be reordered. As with the HTML and YAML versions, this is
  updated once per week.

* [rst.json](rst.json) is a Zonemaster
  [profile](https://github.com/zonemaster/zonemaster/blob/master/docs/public/configuration/profiles.md)
  that's generated once per week.

## See Also

* [RST API Specification](https://icann.github.io/rst-api-spec) ([GitHub repository](https://github.com/icann/rst-api-spec))

## Copyright Statement

This repository is (c) 2024 Internet Corporation for Assigned Names and Numbers
(ICANN). All rights reserved.
