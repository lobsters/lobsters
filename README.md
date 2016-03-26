###Lobsters Rails Project

This is the source code to the site operating at
[https://lobste.rs](https://lobste.rs).  It is a Rails 4 codebase and uses a
SQL (MariaDB in production) backend for the database and Sphinx for the search
engine.

While you are free to fork this code and modify it (according to the [license](https://github.com/jcs/lobsters/blob/master/LICENSE))
to run your own link aggregation website, this source code repository and bug
tracker are only for the site operating at [lobste.rs](https://lobste.rs/).
Please do not use the bug tracker for support related to operating your own
site unless you are contributing code that will also benefit [lobste.rs](https://lobste.rs/).

####Contributing bugfixes and new features

Please see the [CONTRIBUTING](https://github.com/jcs/lobsters/blob/master/CONTRIBUTING.md)
file.

####Development setup

Prerequisites:
* A supported ruby (1.9.3, 2.0.0, 2.1.0)
* MySQL
* Sphinx (if you want to use full-text search in development).

Checkout the lobsters git tree from Github

    $ git clone git://github.com/jcs/lobsters.git
    $ cd lobsters
    lobsters$

Run `bin/setup` to install gem dependencies, initialize a secret key, setup the
local database, and seed with test users.

To use full-text search capabilities, run Sphinx with:

    lobsters$ rake ts:rebuild

Run the Rails server in development mode.  You should be able to login to
`http://localhost:3000` with your new `test` user:

    lobsters$ rails server

####Customizing for your own deployment of Lobsters

* Create a `config/initializers/secret_token.rb` file, using a randomly
generated key from the output of `rake secret`:

    Lobsters::Application.config.secret_key_base = 'your random secret here'

* Define your site's name and default domain, which are used in various places,
in a `config/initializers/production.rb` or similar file:

    class << Rails.application
      def domain
        "example.com"
      end

      def name
        "Example News"
      end
    end

    Rails.application.routes.default_url_options[:host] = Rails.application.domain
