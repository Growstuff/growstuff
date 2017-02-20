Thanks for contributing to Growstuff!

When you create a pull request, please include the following:

* Mention the issue it solves (eg. #123)
* Your code should follow our [Coding style guide](https://github.com/Growstuff/growstuff/wiki/Development-process-overview#coding-practices)
* Make sure you have automated tests for your work, where possible.
* Add your name (and that of your pair partner, if any) to [CONTRIBUTORS.md](CONTRIBUTORS.md).

All pull requests should pass our automatic continuous integration and style
checks before being merged. You can run tests locally as follows:

 - `rake` to run all tests and static checks
 - `rake spec` to run all Ruby tests
 - `rake spec:models` to run Ruby model tests (or `rake spec:views` for view tests, etc)
 - `rake static` to run all static checks (code style, unfixed Git conflicts, etc)
 - `rake jasmine:ci` to run JavaScript unit tests in headless mode
 - `rake jasmine` to start a server for running JavaScript unit tests in a
   browser (eg for debugging). Point your browser at http://localhost:8888 to
   run the tests.
 - `rspec ./spec/path/to/my_spec.rb` to run all Ruby tests in the file `my_spec.rb`
 - `rspec ./spec/path/to/my_spec.rb:45` to run the Ruby test starting on line 45 of
   `my_spec.rb`. RSpec will output a list of command-lines in this form for all
   failing tests so you can easily re-run particular ones.
 - `rspec --only-failures` to re-run all Ruby tests that failed last time.

You can run `rake -T` to see a list of available Rake tasks. If you can't get
some tests to pass, please submit a pull request anyway - we'll be happy to
help you debug the failures.

If you would like to discuss an idea before submitting a pull request,
please open a [GitHub Issue](https://github.com/growstuff/growstuff/issues),
where our dev team will be happy to help you.
