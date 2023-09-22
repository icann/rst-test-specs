# YAML Schema for RST Test Specifications

`rde-test-specs.yaml` confirms to the following schema:

# Top-level object

The top-level object has the following properties:

* `RST-Test-Plan`: this is always `1.0`.
* `Version`: a string containing a version number, conforming to Semantic Versioning.
* `Last-Updated`: the date when the document was last updated, in `YYYY-MM-DD` format.
* `Preamble`: a description of the contents of the file, in Markdown format.
* `Contact`: a `Contact` object.
* `Plans`: a `Test Plan List` object.
* `Test-Cases`: a `Test Case List` object.

# `Contact` object

The `Contact` object has the following properties:

* `Name`: contact name.
* `Organization`: contact organization.
* `Email`: contact email address.

# `Test Plan List` object

The `Test Plan List` object has the following properties:

* `StandardPreDelegationTest` - a `Test Plan` object for standard PDT.
* `StandardRSPChangeTest` - a `Test Plan` object for standard RSP changes.
* `DNSRSPChangeTest` - a `Test Plan` object for DNS RSP changes.
* `IDNTest` - a `Test Plan` object for IDN requests.
* `SRSGatewayTest` - a `Test Plan` object for SRS Gateway requests.

# `Test Plan` object

A `Test Plan` object has the following properties:

* `Name`: the name of the plan
* `Description`: a description of the plan, in Markdown format.
* `Test-Suites`: a `Test Suite List` object.

# `Test Suite List` object

A `Test Suite List` object has the following properties:

* `DNS`: An array of test IDs for DNS-related tests.
* `RDDS`: An array of test IDs for RDDS-related tests.
* `EPP`: An array of test IDs for EPP-related tests.
* `IDN`: An array of test IDs for IDN-related tests.
* `RDE`: An array of test IDs for RDEW-related tests.

A test ID must match a key in the `Test-Cases` property of the top-level object.

# `Test Case List` object.

A `Test Case List` is an object whose property names correspond to test IDs referenced in the properties of `Test Suite List` objects.

Each property is a `Test Case` object.

# `Test Case` object.

A `Test Case` object has the following properties:

* `Summary`: a short description of the test case
* `Description`: a detailed description of the test case in Markdown format.
