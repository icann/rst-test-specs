# EPP Extension List

This directory contains metadata about EPP extensions that is needed for the RST
v2.0 service. For more information, please see the "description" in
[`epp-extensions.yaml`](epp-extensions.yaml). Due to technical limitations, this
list has to be manually maintained.

## Maintenance

The [YAML file](`epp-extensions.yaml`) is converted to JSON by the
[`build-pages` workflow](../.github/workflows/build-pages.yaml). The [JSON
version](https://icann.github.io/rst-test-specs/epp-extensions/epp-extensions.json)
is what is provided for use by consumers.

When changes are made to the YAML file, the `last-updated` property **MUST** be
updated, otherwise the `monitor-extension-registry` workflow (see below) will
generate false positives.

### Changes to the EPP Extension Registry

Entries may be added to or removed from the registry, or they may be changed.

* **New entries**: add an item to either the `uris.objects` or `uris.extensions`
  array in `epp-extensions.yaml`, depending on whether the newly-added entry is
  an _object mapping_ or an _extension_. The `name` and `ref` properties must
  match the entry in the EPP Extension Registry. The value of the `uri` property
  must be determined by reviewing the specification. Then, add the XML schema to
  the [`xsd/`](./xsd) directory.

* **Removal of existing entries:** remove the entry from `epp-extensions.yaml`
  and delete the XML schema file.

* **Changed entries**: if the namespace URI has changed, remove the old entry
  and create a new entry. If the schema has changed, update the file in `xsd/`.

## Monitoring workflow

The [`monitor-extension-registry` workflow](../.github/workflows/monitor.yaml)
runs once per week, and compares the value of the `<updated>` element of the
IANA registry to the `last-updated` property of the JSON file. If the value of
the IANA registry is higher, then the workflow creates an issue using the
template in
[epp-extenstion-registry-update.md)](../.github/epp-extenstion-registry-update.md).
If the extension list is not updated before the next scheduled run, another
issue will be created.
