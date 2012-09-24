Welcome to the Growstuff project.

Continuous Integration setup
============================

We use various Ruby gems to provide continuous integration and testing. They're
all installed by `bundle install`; here's how to use them.

Open a terminal window, select the growstuff gemset, and type `spork`. You
should see the message

    Using RSpec
    Preloading Rails environment
    Loading Spork.prefork block...
    Spork is ready and listening on 8989!

Minimise (but don't close!) that window; you won't need to look at it again for
the rest of the session. Spork keeps a copy of Rails preloaded so our tests
start up quickly.

Now open another window and type `rake watchr`. Keep that window somewhere you
can see it. Every time you change a file, watchr will run the spec tests
associated with it, so you catch test failures right away.

To install the pre-commit hook, type `rake hooks`. This installs a hook that
runs all the spec tests before each commit. You only need to do this
installation once.

The Rails tests take a bit longer to run, so aren't run automatically; run them
manually using `rake test`.
