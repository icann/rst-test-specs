# YAML Schema for RST Test Specifications

The [`rst-test-specs.yaml` file in this repository](rst-test-specs.yaml) conforms to the following schema.

# Top-level object

The top-level object has the following properties:

`RST-Test-Plan-Schema-Version`
: this is always `1.3`. This property tracks the version of **this** document, and is updated whenever a material change to the schema is made.

`Version`
: a string containing a version number of the schema itself, conforming to Semantic Versioning.

`Last-Updated`
: the date when the `Version` property was last updated, in `YYYY-MM-DD` format.

`Preamble`
: a description of the contents of the file, in Markdown format.

`Contact`
: a [Contact object](#contact-object).

`Test-Plans`
: an object containing one or more [Test Plan objects](#test-plan-object), keyed by a unique ID.

`Test-Suites`
: an object containing one or more [Test Suite objects](#test-suite-object), keyed by a unique ID.

`Test-Cases`
: an object containing one or more [Test Case objects](#test-case-object), keyed by a unique ID.

`Input-Parameters`
: an object containing one or more [Input Parameter objects](#input-parameter-object), keyed by a unique ID.

# Contact object

A **Contact** object has the following properties:

`Name`
: contact name.

`Organization`
: contact organization.

`Email`
: contact email address.

# Test Plan object

A **Test Plan** object has the following properties:

`Name`
: the name of the plan.

`Description`
: a description of the plan, in Markdown format.

`Test-Suites`
: an array of [Test Suite](#test-suite-object) IDs, which must match a key in the `Test-Suites` property of the [top-level object](#top-level-object).

# Test Suite object

A **Test Suite** object has the following properties:

`Name`
: the name of the suite.

`Description`
: a description of the suite, in Markdown format.

`Test-Cases`
: either an array of [Test Case](#test-case-object) IDs, which must match a key in the `Test-Cases` property of the [top-level object](#top-level-object), or a string containing a regular expression to match Test Case IDs against.

`Input-Parameters`
: an array of [Input Parameter](#input-parameter-object) IDs which must be provided in addition to the input parameters specified by the test cases for the suite.

# Test Case object

A **Test Case** object has the following properties:

`Summary`
: a short description of the test case.

`Description`: a detailed description of the test case in Markdown format.

`Dependencies`
: an **OPTIONAL** array of [Test Case](#test-case-object) IDs, which must match a key in the 
`Test-Cases` property of the [top-level object](#top-level-object).

`Input-Parameters`
: an array of [Input Parameter](#input-parameter-object) IDs, which must match a key in the `Input-Parameters` property of the [top-level object](#top-level-object).

# Input Parameter object

An **Input Parameter** object has the following properties:

`Type`
: one of `file`, `string`, `integer`, `number`, `boolean`, `null` or `array`.

`Description`
: a description of the input parameter in Markdown format.

`Example`
: an example value.
