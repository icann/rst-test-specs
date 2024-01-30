# YAML Schema for RST Test Specifications

The [`rst-test-specs.yaml` file in this repository](rst-test-specs.yaml)
conforms to the following schema.

This schema is available in YAML format in
[`rst-test-spec-schema.yaml`](rst-test-spec-schema.yaml).

# Top-level object

The top-level object has the following properties:

`RST-Test-Plan-Schema-Version`
: this is always `1.6.1`. This property conforms to the [Semantic
Versioning](https://semver.org) convention, and tracks the version of **this**
document, and is updated whenever a material change to the schema is made.

`Version`
: a string containing the semantic version number for the specification itself.

`Last-Updated`
: the date when the `Version` property was last updated, in `YYYY-MM-DD` format.

`Preamble`
: a description of the contents of the file, in Markdown format.

`ChangeLog`
: a [Change Log object](#change-log).

`Contact`
: a [Contact object](#contact-object).

`Test-Plans`
: a mapping containing one or more [Test Plan objects](#test-plan-object), keyed
by a unique ID.

`Test-Suites`
: a mapping containing one or more [Test Suite objects](#test-suite-object),
keyed by a unique ID.

`Test-Cases`
: a mapping containing one or more [Test Case objects](#test-case-object),
keyed by a unique ID.

`Input-Parameters`
: a mapping containing one or more [Input Parameter
objects](#input-parameter-object), keyed by a unique ID.

`Resources`
: a mapping containing one or more [Resource objects](#resource-object), keyed
by a unique ID.

`Errors`
: a mapping containing one or more [Error objects](#error-object), keyed by a
unique ID.

# ChangeLog object

A **ChangeLog** object contains a chronological narrative of changes to the test
specifications.

Its property names are dates in `YYYY-MM-DD` format, and the property values are
collections of changes in Markdown format.

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

`Order`
: an integer containing the canonical order of the plan in the spec.

`Description`
: a description of the plan, in Markdown format.

`Test-Suites`
: a collection of [Test Suite object](#test-suite-object) IDs, which must match
a key in the `Test-Suites` property of the [top-level
object](#top-level-object).

# Test Suite object

A **Test Suite** object has the following properties:

`Name`
: the name of the suite.

`Order`
: an integer containing the canonical order of the suite in the spec.

`Description`
: a description of the suite, in Markdown format.

`Test-Cases`
: either an collection of [Test Case object](#test-case-object) IDs, which must
match a key in the `Test-Cases` property of the [top-level
object](#top-level-object), or a string containing a regular expression to match
Test Case IDs against.

`Input-Parameters`
: a collection of [Input Parameter object](#input-parameter-object) IDs which
must be provided in addition to the input parameters specified by the test cases
for the suite.

`Resources`
: a collection of [Resource object](#resource-object]) IDs which may be used to
prepare for the tests in this test suite, in addition to those specified by the
test cases for the suite.

`Errors`
: a collection of [Error object](#error-object]) IDs which may be produced by
this test suite, in addition to those specified by the test cases for the suite.

# Test Case object

A **Test Case** object has the following properties:

`Summary`
: a short description of the test case.

`Description`: a detailed description of the test case in Markdown format.

`Maturity`: one of `ALPHA`, `BETA` or `GAMMA`.

`Dependencies`
: an **OPTIONAL** array of [Test Case object](#test-case-object) IDs, which must
match a key in the  `Test-Cases` property of the [top-level
object](#top-level-object).

`Input-Parameters`
: a collection of [Input Parameter object](#input-parameter-object) IDs, which
must match a key in the `Input-Parameters` property of the [top-level
object](#top-level-object).

`Resources`
: a collection of [Resource object](#resource-object]) IDs which may be used to
prepare for this test case.

`Errors`
: a collection of [Error object](#error-object]) IDs which this test case may
produce.

# Input Parameter object

An **Input Parameter** object has the following properties:

`Type`
: one of `file`, `string`, `integer`, `number`, `boolean`, `null`, `object` or
`array`.

`Description`
: a description of the input parameter in Markdown format.

`Schema`
: an [OpenAPI `Schema`
object](https://spec.openapis.org/oas/latest.html#schemaObject) which can be
used to validate this parameter.

`Example`
: an example value in JSON format.

# Resource object

A **Resource** object has the following properties:

`Description`
: a description of the resource in Markdown format.

`URL`
: the URL where the resource may be found.

# Error object

An **Error** object has the following properties:

`Severity`
: one of `INFO`, `NOTICE`, `WARNING`, `ERROR` or `CRITICAL`.

`Description`
: a description of the error in Markdown format.
