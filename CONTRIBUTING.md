####Licensing

The `lobsters` codebase is under a [3-clause BSD
license](https://github.com/jcs/lobsters/blob/master/LICENSE).  All code
submitted must be licensed under these or more-permissive terms (2-clause BSD,
MIT, ISC, etc.).

####Before Making Changes

While this project's license allows for modification and use to run your own
website, this source code repository is for the code running the website at
[lobste.rs](https://lobste.rs/).

Not all changes or new features submitted will be accepted.  Please discuss
your proposed changes on [/t/meta](https://lobste.rs/t/meta) or as a
[Github issue](https://github.com/jcs/lobsters/issues) before working on them
to avoid wasted efforts.

###Making Changes

* Fork [jcs/lobsters](https://github.com/jcs/lobsters) on Github.

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

* Submit a pull request to [jcs/lobsters](https://github.com/jcs/lobsters).
