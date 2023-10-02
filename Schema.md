# YAML Schema for RST Test Specifications

The `rde-test-specs.yaml` file in this repository conforms to the following schema.

# Top-level object

The top-level object has the following properties:

* `RST-Test-Plan-Schema-Version`: this is always `1.1`.
* `Version`: a string containing a version number, conforming to Semantic Versioning.
* `Last-Updated`: the date when the document was last updated, in `YYYY-MM-DD` format.
* `Preamble`: a description of the contents of the file, in Markdown format.
* `Contact`: a `Contact` object.
* `Test-Plans`: an object containing one or more `Test Plan` objects, keyed by a unique ID.
* `Test-Suites`: an object containing one or more `Test Suite` objects, keyed by a unique ID.
* `Test-Cases`: an object containing one or more `Test Cases` objects, keyed by a unique ID.

# `Contact` object

The `Contact` object has the following properties:

* `Name`: contact name.
* `Organization`: contact organization.
* `Email`: contact email address.

# `Test Plan` object

A `Test Plan` object has the following properties:

* `Name`: the name of the plan.
* `Description`: a description of the plan, in Markdown format.
* `Test-Suites`: an array of Test Suite IDs, which must match a key in the `Test-Suites` property of the top-level object.

# `Test Suite` object

A `Test Suite` object has the following properties:

* `Name`: the name of the suite.
* `Description`: a description of the suite, in Markdown format.
* `Test-Cases`: an array of Test Case IDs, which must match a key in the `Test-Cases` property of the top-level object.

# `Test Case` object

A `Test Case` object has the following properties:

* `Summary`: a short description of the test case.
* `Description`: a detailed description of the test case in Markdown format.
* `Dependencies`: an **OPTIONAL** array of Test Case IDs, which must match a key in the `Test-Cases` property of the top-level object.