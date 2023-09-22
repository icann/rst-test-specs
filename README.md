The `rst-test-specs.yaml` file in this repository was assembled from a set of
Word documents originally created by IIS (.SE), who created the original
Pre-Delegation Testing (PDT, now called Registry System Testing or RST) System.

The Test System consists of several *test plans*, each of which addresses a
particular scenario. The test plans follow a standard structure and methodology
derived from IEEE 829-2008 (which has since been superseded by ISO/IEC 29119).

Each *test plan* includes one or more *test suites* which in turn include
one or more *test cases*. For a test to succeed, every test case has to pass.

`rst-test-specs.yaml` describes each test plan, suite and case in the RST system
in a machine-readable format, suitable for version tracking and reliable and
repeatable (a) documentation generation, (b) code generation, and (c)
orchestrating registry system testing.
