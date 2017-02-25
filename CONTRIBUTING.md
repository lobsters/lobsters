####Licensing

The `journalduhacker` codebase is under a [AGPL 
license](https://gitlab.com/journalduhacker/journalduhacker/blob/master/LICENSE).  All code
submitted must be licensed under these terms.

[The original code](https://github.com/jcs/lobsers) is released under the [MIT license](https://opensource.org/licenses/MIT).

####Before Making Changes

While this project's license allows for modification and use to run your own
website, this source code repository is for the code running the website at
[www.journalduhacker.net](https://www.journalduhacker.net/).

Not all changes or new features submitted will be accepted.

###Making Changes

* Fork [journalduhacker/journalduhacker](https://gitlab.com/journalduhacker/journalduhacker) on Gitlab.com

* (Optional) Create a branch to house your changes.

* Wrap code at 80 characters with 2-space soft tabs for Ruby code.  For other
languages, use the existing style of the files being edited.  3rd party,
externally-maintained code such as Javascript libraries can remain in their
own style.

* Check for unnecessary whitespace with `git diff --check` before committing.
Commit whitespace and other code cleanups separately so that your actual
changes can be easily understood.

* Write a proper commit message with the first line being a short,
present-tense explanation of the change.  Wrap all lines at 80 characters.

* If applicable, add tests for your changes.  Not all changes require tests,
and tests should not be added just for the sake of code coverage.

* Run _all_ tests (with `rake` in the root directory) to ensure nothing has
been broken by your changes.

### Submitting Changes

* Push your changes to your fork of the repository (to your branch if you
created one).

* Submit a pull request to [journalduhacker/journalduhacker](https://gitlab.com/journalduhacker/journalduhacker).
