# EPP Extension List

This directory contains metadata about EPP extensions that is needed for the RST
v2.0 service. For more information, please see the "description" in
[epp-extensions.yaml](epp-extensions.yaml). Due to technical limitations, this
list has to be manually maintained.

## Maintenance

The [YAML file](epp-extensions.yaml) is the source, the [JSON
file](epp-extensions.json) is a compiled artifact. Only ever edit the YAML file.

When changes are made to the YAML file, run `make` in this directory to generate
the JSON version. The `last-updated` **MUST** be updated during updates,
otherwise the `monitor-extension-registry` workflow (see below) will generate
false positives.

## Monitoring workflow

The [`monitor-extension-registry` workflow](../.github/workflows/monitor.yaml)
runs once per week, and compares the value of the `<updated>` element of the
IANA registry to the `last-updated` property of the JSON file. If the value of
the IANA registry is higher, then the workflow creates an issue using the
template in [epp-extenstion-registry-update.md)](../.github/epp-extenstion-registry-update.md).
If the extension list is not updated before the next scheduled run, another
issue will be created.
