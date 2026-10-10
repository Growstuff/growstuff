# 🌱 Growstuff

![Build status](https://github.com/Growstuff/growstuff/workflows/CI/badge.svg)

Welcome to the Growstuff project.

You can find our app at https://www.growstuff.org

Growstuff is an open source/open data project for food gardeners.  We
crowdsource information on what our members are growing and harvesting,
aggregate it, and make it available as open data via our API.

Growstuff was founded in 2012 and has been built by dozens of
[contributors](CONTRIBUTORS.md).  We are an inclusive, welcoming project, and
encourage participation from people of all backgrounds and skill levels.

## Want to contribute?

Don't ask to ask, the best way to get started is to fork the project, start a codespace and get hacking.
Dive on in and submit your PRs!

Vibe Coding is more than okay, just make sure you indicate if you have done so and ensure there are tests.

## Important links

* [Issues](https://github.com/orgs/Growstuff/projects/1) (features we're
  working on, known bugs, etc)
* [Wiki](https://github.com/Growstuff/growstuff/wiki) (general documentation, etc.)

## For coders

Growstuff is built in Ruby on Rails and also uses JavaScript for
frontend features. We welcome contributions -- see
[CONTRIBUTING](CONTRIBUTING.md) for details.

* To set up your development environment, see [Getting started](https://github.com/Growstuff/growstuff/wiki/New-contributor-guide).
* You may also be interested in our [API](https://github.com/Growstuff/growstuff/wiki/API).

### Running Rails natively against Dockerized services

If you'd rather run `rails server` directly on your machine (instead of
inside the `web` container) while still using Docker for Postgres and
Elasticsearch, here's the full setup:

1. **Get the pinned Ruby and Node versions.** [`mise.toml`](mise.toml) pins
   both (matching `.ruby-version` and the Node 24 used in CI). If you use
   [mise](https://mise.jdx.dev/), just run:

   ```bash
   mise install
   ```

   rbenv/asdf/nvm users can read the versions from `mise.toml` (or
   `.ruby-version`) and install them the usual way instead.

2. **Start the backing services** (Postgres and Elasticsearch, skipping the
   `web` container):

   ```bash
   docker compose up -d db elasticsearch
   ```

3. **Make the `db` hostname resolve on your host machine.** `config/database.yml`
   points at host `db`, which only exists inside the Compose network. Add
   this line to `/etc/hosts` so both Docker and native runs work against the
   same config:

   ```text
   127.0.0.1 db
   ```

4. **Install gems:**

   ```bash
   bundle install
   ```

5. **Set up your local config.** The app reads settings like
   `GROWSTUFF_SITE_NAME` from a git-ignored `.env` file (via `dotenv-rails`).
   Copy the example to get started:

   ```bash
   cp env-example .env
   ```

6. **Install Yarn and JS dependencies.** Yarn isn't bundled with Node —
   enable it via Node's built-in Corepack, then install:

   ```bash
   corepack enable
   yarn install
   ```

7. **Create and load the database:**

   ```bash
   bundle exec rails db:create db:schema:load
   ```

8. **Build the search index** (Elasticsearch starts empty):

   ```bash
   bundle exec rails runner "Crop.reindex"
   ```

9. **Start the app:**

   ```bash
   bundle exec rails s
   ```

### For Home Automation enthusiasts

https://github.com/Growstuff/homeassistant-growstuff/

## For designers, writers, researchers, data wranglers, and other contributors

There are heaps of ways to get involved and contribute no matter what
your skills and interests.

You might like to check out:

* The [New Contributor Guide](https://github.com/Growstuff/growstuff/wiki/New-contributor-guide)
  page on our wiki, which has lots of detail for different areas

Here on Github, you might find these useful:

* [Github Project Board](https://github.com/orgs/Growstuff/projects/1) has stories in "ready" that can be worked on.
* [needs: design](https://github.com/Growstuff/growstuff/labels/needs:%20design) - tasks requiring high-level design
* [needs: visual design](https://github.com/Growstuff/growstuff/labels/needs:%20visual+design) - tasks requiring visual/graphical design
* [needs: documentation](https://github.com/Growstuff/growstuff/labels/needs:%20documentation)
* [needs: data](https://github.com/Growstuff/growstuff/labels/needs:%20data) - tasks requiring data entry, data design, data import, or similar
* [curated:beginner](https://github.com/Growstuff/growstuff/labels/curated:%20beginner) - tasks that are ideal for beginner programmers or people new to the project

Feel free to comment on any of the issues on [Github](https://github.com/Growstuff/growstuff/issues).

## Contact

For more information about this project, contact [info@growstuff.org](mailto:info@growstuff.org).

Security Issues: If you find an authorization bypass or data breach, please contact our maintainers directly at [maintainers@growstuff.org](mailto:maintainers@growstuff.org).

