# Notes for coding agents

## UI changes

Where possible if creating a pull request, include screenshots or other visual test evidence if your changes are design oriented.

## Localization

We localize our user interfaces. Don't hard-code English text in views, helpers,
controllers or React components: put it in `config/locales/en.yml` and add the
translations to the other locales (de, es, fr, ja, zh) in the same change. In
views use relative keys, `t('.key')`. React components have no translation
library, so Rails passes them their text as props.

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
