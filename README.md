###Lobsters Rails Project

This is the source code to the site operating at [https://lobste.rs](https://lobste.rs).  It is a Rails 3 codebase and uses a SQL (MySQL in production) backend for the database and Sphinx for the search engine.

####Initial setup

- Install Ruby 1.9.3.

- Checkout the lobsters git tree from Github

    $ `git clone git://github.com/jcs/lobsters.git`
    $ `cd lobsters`
    lobsters$ 

- Run Bundler to install/bundle gems needed by the project:

    lobsters$ `bundle`

- Create a MySQL (other DBs supported by ActiveRecord may work, only MySQL has been tested) database, username, and password and put them in a `config/database.yml` file:

     development:
       adapter: mysql2
       encoding: utf8
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

- Load the schema into the new database:

     lobsters$ `rake db:schema:load`

- Create a `config/initializers/secret_token.rb` file:

     Lobsters::Application.config.secret_token = '*some 128-bit hexadecimal secret*'

- (Optional, only needed for search engine) Install Sphinx.  Build Sphinx config and start server:

     lobsters$ `rake thinking_sphinx:rebuild`

- Run the Rails server in development mode:

     lobsters$ `rails server`
