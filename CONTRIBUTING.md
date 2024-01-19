### Licensing

The `quantumnews` codebase is under a [MIT](https://github.com/aqora-io/quantumnews/blob/main/LICENSE).

### Making Changes

* Fork [aqora-io/quantumnews](https://github.com/aqora-io/quantumnews) on Github.

* (Optional) Create a branch to house your changes.

* Run `bundle exec standardrb` to check the style of your Ruby.
    No messages means success.
    Adding `--fix` will take care of most issues automatically, and there's excellent
    <a href="https://github.com/standardrb/standard#user-content-editor-support">editor integration available</a>.
  (3rd party, externally-maintained code such as Javascript libraries can remain in their own style.)

* Check for unnecessary whitespace with `git diff --check` before committing.
Commit whitespace and other code cleanups separately so that your actual
changes can be easily understood.

* Write a proper commit message with the first line being a short,
present-tense explanation of the change.  Wrap message lines at 80 characters.

* If applicable, add tests for your changes.  Not all changes require tests,
and tests should not be added just for the sake of code coverage.

* Run _all_ tests (with `bundle exec rspec` in the root directory) to ensure
nothing has been broken by your changes.

### Submitting Changes

* Push your changes to your fork of the repository (to your branch if you
created one).

* Submit a pull request to [aqora-io/quantumnews](https://github.com/aqora-io/quantumnews).
