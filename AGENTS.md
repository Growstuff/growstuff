# Notes for coding agents

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
