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

While this project's license allows for modification and use to run your own website,
this source code repository is specifically for the code running the website at [lobste.rs](https://lobste.rs/).

We're very deliberate about new features and behavior changes because they have difficult-to-forsee social effects or maintenance costs.
If you have ideas, please come discuss them on [/t/meta](https://lobste.rs/t/meta),
in [the chat room](https://lobste.rs/chat),
or as a [Github issue](https://github.com/lobsters/lobsters/issues) to avoid wasted effort.

### Making your change

* Fork [lobsters/lobsters](https://github.com/lobsters/lobsters) on Github.

* Run through the setup steps in `README.md`

* Create a branch to work on: `git checkout -b ...'

* Write your commit messages in present tense ("fix foo", not "fixed foo").
  [Mention a GitHub issue number](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/using-keywords-in-issues-and-pull-requests) if there is one.
  Don't sweat messages too much, I am weirdly picky about commit messages so expect that I'll rewrite the message that merges/squashes the PR.

* Our testing goal is to get good information and reasonable reliability with pretty low maintenance and runtime costs.
  We try to have a smoke test for the happy path of user-facing features and then test at least a few paths through more complicated functions.
  Not all changes require tests, but most bug fixes benefit from it.

* You can "run the build" (see `.github/workflows/check.yml`) locally with
  `bundle exec rspec && bundle exec standardrb --fix-unsafely && brakeman -q`.

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

### Sharing your work

* Push your changes to your fork of the repository: `git push origin`

* Open a pull request to [lobsters/lobsters](https://github.com/lobsters/lobsters).
  You're welcome to open a PR for a work in progress if you want to share progress or ask for help.
  It's a big help if you explicitly write in a comment when you think the code is done!
