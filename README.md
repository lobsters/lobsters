### Lobsters Rails Project [![Build Status](https://travis-ci.org/lobsters/lobsters.svg?branch=master)](https://travis-ci.org/lobsters/lobsters)

This is the
[quite sad](https://www.reddit.com/r/rails/comments/6jz7tq/source_code_lobsters_a_hacker_news_clone_built/)
source code to the site operating at
[https://lobste.rs](https://lobste.rs).
It is a Rails 5 codebase and uses a SQL (MariaDB in production) backend for the database.

While you are free to fork this code and modify it (according to the [license](https://github.com/lobsters/lobsters/blob/master/LICENSE))
to run your own link aggregation website, this source code repository and bug
tracker are only for the site operating at [lobste.rs](https://lobste.rs/).
Please do not use the bug tracker for support related to operating your own
site unless you are contributing code that will also benefit [lobste.rs](https://lobste.rs/).

#### Contributing bugfixes and new features

Please see the [CONTRIBUTING](https://github.com/lobsters/lobsters/blob/master/CONTRIBUTING.md)
file.

#### Initial setup

Use the steps below for a local install or
[lobsters-ansible](https://github.com/lobsters/lobsters-ansible) for our production deployment config.
There's an external project [docker-lobsters](https://github.com/jamesbrink/docker-lobsters) if you want to use Docker.

* Install Ruby 2.3.

* Checkout the lobsters git tree from Github
    ```sh
    $ git clone git://github.com/lobsters/lobsters.git
    $ cd lobsters
    lobsters$
    ```

* Install Nodejs, needed (or other execjs) for uglifier
    ```sh
    Fedora: sudo yum install nodejs
    Ubuntu: sudo apt-get install nodejs
    OSX: brew install nodejs
    ```

* Run Bundler to install/bundle gems needed by the project:

    ```sh
    lobsters$ bundle
    ```

* Create a MySQL (other DBs supported by ActiveRecord may work, only MySQL and
MariaDB have been tested) database, username, and password and put them in a
`config/database.yml` file.  You will also want a separate database for
running tests:

    ```yaml
    development:
      adapter: mysql2
      encoding: utf8mb4
      reconnect: false
      database: lobsters_dev
      socket: /tmp/mysql.sock
      username: *dev_username*
      password: *dev_password*
      
    test:
      adapter: mysql2
      encoding: utf8mb4
      reconnect: false
      database: lobsters_test
      socket: /tmp/mysql.sock
      username: *test_username*
      password: *test_password*
    ```

* Load the schema into the new database:

    ```sh
    lobsters$ rails db:schema:load
    ```
    
* Define your site's name and default domain, which are used in various places,
in a `config/initializers/production.rb` or similar file:

    ```ruby
    class << Rails.application
      def domain
        "example.com"
      end

      def name
        "Example News"
      end
    end

    Rails.application.routes.default_url_options[:host] = Rails.application.domain
    ```

* Put your site's custom CSS in `app/assets/stylesheets/local`.

* Seed the database to create an initial administrator user, the `inactive-user`, and at least one tag:

    ```sh
    lobsters$ rails db:seed
    ```

* On your personal computer, you can add some sample data and run the Rails server in development mode.
  You should be able to login to `http://localhost:3000` with your new `test` user:

    ```sh
    lobsters$ rails fake_data
    lobsters$ rails server
    ```

* Deploying the site in production requires setting up a web server and running the app in production mode.
  There are more tools and options available than we can describe; find a guide or an expert.
  The lobsters-ansible repo has our config files to crib from. Some app-specific notes:

* Set up crontab or another scheduler to run regular jobs:

    ```
    */5 * * * *  cd /path/to/lobsters && env RAILS_ENV=production sh -c 'bundle exec ruby script/mail_new_activity; bundle exec ruby script/post_to_twitter'
    ```

* See `config/initializers/production.rb.sample` for GitHub/Twitter integration help.

#### Administration

Basic moderation happens on-site, but most other administrative tasks require use of the rails console in production.
Administrators can create and edit tags at `/tags`.
