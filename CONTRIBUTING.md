### Licensing

The `lobsters` codebase is under a [3-clause BSD
license](https://github.com/lobsters/lobsters/blob/master/LICENSE).  All code
submitted must be licensed under these or more-permissive terms (2-clause BSD,
MIT, ISC, etc.).

### The most important thing

Thanks for considering spending your time contributing to the codebase.
Drop by [the chat room](https://lobste.rs/chat) if you'd like a hand getting started.

If you're new to Rails, the [official guides](https://guides.rubyonrails.org/) are good
and there's a [complete API doc](https://api.rubyonrails.org/).

We consider contributions to be gifts, and there's no gift you can give that obligates you to give more gifts.
If you reported an issue or opened a PR but don't want to continue with it, especially when a maintainer is asking for more info or revisions, please do tell us you're done with it so we know to carry on with it ourselves.

### Getting oriented

If you're new to contributing, issues tagged [good first issue](https://github.com/lobsters/lobsters/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
require little knowledge of the codebase or community.
Ask your questions in the issue or in [our chat room](https://lobste.rs/chat), we'd love to help you get involved.

You can jump right in to issues tagged `good first issue`, you don't have to ask permission.
Please don't post a comment to "claim" an issue.
If an issue then doesn't get finished it stalls out for years because nobody wants to be rude and "steal" it.

Do not submit code written by LLM-powered coding tools because of the [uncertainty around their output's copyright](https://en.wikipedia.org/wiki/Artificial_intelligence_and_copyright).

While this project's license allows for modification and use to run your own website,
this source code repository is specifically for the code running the website at [lobste.rs](https://lobste.rs/).

We're very deliberate about new features and behavior changes because they have difficult-to-foresee social effects or maintenance costs.
If you have ideas, please come discuss them on [/t/meta](https://lobste.rs/t/meta),
in [the chat room](https://lobste.rs/chat),
or as a [Github issue](https://github.com/lobsters/lobsters/issues) to avoid wasted effort.

### Setting up your environment

* Fork [lobsters/lobsters](https://github.com/lobsters/lobsters) on Github.

* Clone your fork locally.

  ```sh
  $ git clone git@github.com:<your_gh_username>/lobsters.git
  $ cd lobsters
  lobsters$
  ```

* Setup up your development environment with [docker](/docs/setup_with_docker.md), using a [devcontainer](/docs/SETUP_DEVCONTAINER.md), or locally:

* Install MariaDB:
  * On Linux use [your package manager](https://mariadb.com/kb/en/distributions-which-include-mariadb/).
  * On MacOS you can [install with brew](https://mariadb.com/kb/en/installing-mariadb-on-macos-using-homebrew/).
  * On Windows there's an [installer](https://mariadb.org/download/?t=mariadb&p=mariadb&r=11.5.2&os=Linux&cpu=x86_64&pkg=tar_gz&i=systemd&mirror=starburst_stlouis).

* Start the MariaDB server using one of the [methods mentioned in the MariaDB knowledge base](https://mariadb.com/kb/en/starting-and-stopping-mariadb-automatically/).

* Open the console using `mariadb`, and set the `root` user password (type `ctrl-d` to exit afterwards):

  ```sql
  ALTER USER 'root'@'localhost' IDENTIFIED BY 'localdev';
  ```

* Install the Ruby version specified in [.ruby-version](https://github.com/lobsters/lobsters/blob/main/.ruby-version).

* Run `bin/setup` to install dependencies and set up the database:

  ```sh
  lobsters$ bin/setup
  ```

* Run `rails credentials:edit` to create and edit your encrypted credentials file.
  This is where you store API keys for external services and features like linking accounts.
  Copy and paste in the contents of `config/credentials.yml.enc.sample`.
  On setup, Rails will give you new random value for `secret_key_base` and you can use `rails secret` any time you need to generate another.

* If you intend to setup a production server, copy `config/initializers/production.rb.sample`
  to `config/initializers/production.rb` and customize it with your site's
  `domain` and `name`. (You don't need this on your dev machine.)

* On your personal computer, you probably want to add some sample data:

  ```sh
  lobsters$ rails fake_data
  ```

* Run the Rails server in development mode.
  You should be able to log in to `http://localhost:3000` with your new `test` user (with password `test`):

  ```sh
  lobsters$ rails server
  ```

### Making your change

* Create a branch to work on: `git checkout -b ...'

* Write your commit messages in present tense ("fix foo", not "fixed foo").
  [Mention a GitHub issue number](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/using-keywords-in-issues-and-pull-requests) if there is one.
  Don't sweat messages too much, I am weirdly picky about commit messages so expect that I'll rewrite the message that merges/squashes the PR.

* Our testing goal is to get good information and reasonable reliability with pretty low maintenance and runtime costs.
  We try to have a smoke test for the happy path of user-facing features and then test at least a few paths through more complicated functions.
  Not all changes require tests, but most bug fixes benefit from it.

* You can "run the build" (see `.github/workflows/check.yml`) locally with
  `bundle exec rake build`, which runs the following:

  * [rspec](https://rspec.info/documentation) is the test suite.
    It's a big DSL so it has a pretty steep learning curve.
    It's easiest to get started by duplicating existing tests.
  * [standardrb](https://github.com/standardrb/standard) is the linter/formatter.
    There's very nice [editor integration available](https://github.com/standardrb/standard#user-content-editor-support).
  * [brakeman](https://brakemanscanner.org/) is the security linter.
    You can run `brakeman -I` to interactively add a note if a new warning is a false positives.
    Brakeman is conservatively configured to "fail" when a new version of brakeman is released.
    If that happens when you're working on a PR, you can ping me and I'll update it.

    Brakeman also sometimes emits intimidating warnings about minor changes near known risky code.
    So if brakeman warns you about code you didn't write, don't panic, it's probably fine.
    Push your PR and @mention me, I'll help sort it out.
  * [database_consistency](https://github.com/djezzzl/database_consistency) checks for inconsistencies between the database schema and Active Record models.

### Sharing your work

* Push your changes to your fork of the repository: `git push origin`

* Open a pull request to [lobsters/lobsters](https://github.com/lobsters/lobsters).
  You're welcome to open a PR for a work in progress if you want to share progress or ask for help.
  It's a big help if you explicitly write in a comment whether the code is a draft or is ready to merge!

* If I request changes to the PR, you can add more commits or edit your existing and force-push, whatever you prefer.
  I usually squash and rebase small PRs and merge PRs where the commits are big enough to be individually useful in future debugging.
  I don't have a particularly strong opinion and I want to treat your work respectfully, so please do let me know if you prefer squash/rebase/merge.


