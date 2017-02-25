###Journalduhacker Project

This is the source code of the website operating at
[https://www.journalduhacker.net](https://www.journalduhacker.net).  It is a Rails 4 codebase and uses a
SQL (MariaDB in production) backend for the database and Sphinx for the search
engine.

This code is forked from the [lobste.rs](https://lobster.rs) engine [available here](https://github.com/lobsters/).

####Contributing bugfixes and new features

Please see the [CONTRIBUTING](https://gitlab.com/journalduhacker/journalduhacker/blob/master/CONTRIBUTING.md)
file.

####Initial setup

* Install Ruby.  This code has been tested with Ruby versions 1.9.3, 2.0.0, 2.1.0,
and 2.3.0.

* Checkout the journalduhacker git tree from Github

         $ git clone https://gitlab.com/journalduhacker/journalduhacker.git
         $ cd journalduhacker
         journalduhacker$ 

* Run Bundler to install/bundle gems needed by the project:

         journalduhacker$ bundle

* Create a MySQL (other DBs supported by ActiveRecord may work, only MySQL and
MariaDB have been tested) database, username, and password and put them in a
`config/database.yml` file:

          development:
            adapter: mysql2
            encoding: utf8mb4
            reconnect: false
            database: journalduhacker_dev
            socket: /tmp/mysql.sock
            username: *username*
            password: *password*
            
          test:
            adapter: sqlite3
            database: db/test.sqlite3
            pool: 5
            timeout: 5000

* Load the schema into the new database:

          journalduhacker$ rake db:schema:load

* Create a `config/initializers/secret_token.rb` file, using a randomly
generated key from the output of `rake secret`:

          Lobsters::Application.config.secret_key_base = 'your random secret here'

* (Optional, only needed for the search engine) Install Sphinx.  Build Sphinx
config and start server:

          journalduhacker$ rake ts:rebuild

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

* Put your site's custom CSS in `app/assets/stylesheets/local`.

* Seed the database to create an initial administrator user and at least one tag:

          journalduhacker$ rake db:seed
          created user: test, password: test
          created tag: test

* Run the Rails server in development mode.  You should be able to login to
`http://localhost:3000` with your new `test` user:

          journalduhacker$ rails server

* In production, set up crontab or another scheduler to run regular jobs:

          */20 * * * * cd /path/to/journalduhacker && env RAILS_ENV=production bundle exec rake ts:index > /dev/null
