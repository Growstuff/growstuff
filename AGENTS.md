# Notes for coding agents

## UI changes

Where possible if creating a pull request, include screenshots or other visual test evidence if your changes are design oriented.

### i18n

For user facing screens, prefer i18n translations (locale/en.yml) rather than inline text.
Use an appropriate level of formality for a user interface, pay attention to gender of terms.
Avoid adding test coverage dependent on string content that may change with an updated translation, unless it is really crucial to the tests.
Avoid picking YAML translation keys that require quotation or escaping (such as `on`/`off`, `yes`/`no`, or `true`/`false`, which are boolean literals in YAML 1.1; prefer descriptive alternatives like `enabled`/`disabled`).

## Dependencies

Do not commit or publish changes to ruby versions, gemfiles data or similar if you have had to make changes to the application to run in your sandbox environment/a user has not asked you to.

## Specs

Follow the layout advice at https://www.betterspecs.org/:

- One expectation per example. Name the example for the behaviour it checks.
- `describe` for the thing under test, `context` for a situation, phrased
  "when ...", "with ..." or "without ...".
- Keep `it` descriptions short, and don't start them with "should".
- Prefer lazy `let` over instance variables and `let!`/`before` setup, and use
  `subject` when the thing under test is the same across examples.
- Use `described_class` rather than repeating the class name.
- Extract repeated behaviour into shared examples.
- Don't mark a feature spec `:js` unless it needs JavaScript. Without it the
  spec runs under rack_test, which is much faster than a browser.

Avoid tests simply for the sake of tests - for example, if a feature test broadly covers an area a view test for a partial may simply increase maintenance and build fragility. If a view or component has significant complexity or branching logic, prefer test coverage of helpers and moving as much of the complexity there.

When adding new coverage, ensure it is executed to validate it. Check carefully for common causes of flaky test behaviour - timezones, factory content that differs due to randomness, etc.
