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

####Initial setup

* Install Ruby. Supported Ruby versions include 1.9.3, 2.0.0 and 2.1.0.

* Checkout the lobsters git tree from Github

         $ git clone git://github.com/jcs/lobsters.git
         $ cd lobsters
         lobsters$ 

* Run Bundler to install/bundle gems needed by the project:

         lobsters$ bundle

* Create a MySQL (other DBs supported by ActiveRecord may work, only MySQL and
MariaDB have been tested) database, username, and password and put them in a
`config/database.yml` file:

          development:
            adapter: mysql2
            encoding: utf8mb4
            reconnect: false
            database: lobsters_dev
            socket: /tmp/mysql.sock
            username: *username*
            password: *password*
            
          test:
            adapter: sqlite3
            database: db/test.sqlite3
            pool: 5
            timeout: 5000

* Load the schema into the new database:

          lobsters$ rake db:schema:load

* Create a `config/initializers/secret_token.rb` file, using a randomly
generated key from the output of `rake secret`:

          Lobsters::Application.config.secret_token = 'your random secret here'

* For use with Heroku:

          Lobsters::Application.config.secret_token = ENV['SECRET_TOKEN']

    In order for the token to be used by local environment you will need to add it. Here we use [foreman gem](https://github.com/ddollar/foreman) along with a ```.env``` file that has a secret_token

          SECRET_TOKEN=c4ff17f668c33c1...

    Do not forget to add ```.env``` into ```.gitignore``` so that your source control does not have the secret_token.

* (Optional, only needed for the search engine) Install Sphinx.  Build Sphinx
config and start server:

          lobsters$ rake ts:rebuild

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

* Create an initial administrator user and at least one tag:

          lobsters$ rails console
          Loading development environment (Rails 3.2.6)
          irb(main):001:0> u = User.new(:username => "test", :email => "test@example.com", :password => "test", :password_confirmation => "test")
          irb(main):002:0> u.is_admin = true
          irb(main):003:0> u.is_moderator = true
          irb(main):004:0> u.save

          irb(main):005:0> t = Tag.new
          irb(main):006:0> t.tag = "test"
          irb(main):007:0> t.save

* Run the Rails server in development mode.  You should be able to login to
`http://localhost:3000` with your new `test` user:

          lobsters$ rails server

    If you are using the foreman gem:

          lobsters$ foreman run rails server
