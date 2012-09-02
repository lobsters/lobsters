###Lobsters Rails Project

This is the source code to the site operating at [https://lobste.rs](https://lobste.rs).  It is a Rails 3 codebase and uses a SQL (MySQL in production) backend for the database and Sphinx for the search engine.

####Initial setup

- Install Ruby 1.9.3.

- Checkout the lobsters git tree from Github

         $ git clone git://github.com/jcs/lobsters.git
         $ cd lobsters
         lobsters$ 

- Run Bundler to install/bundle gems needed by the project:

         lobsters$ bundle

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

          lobsters$ rake db:schema:load

- Create a `config/initializers/secret_token.rb` file:

          Lobsters::Application.config.secret_token = 'some 128-bit hexadecimal secret here'

- (Optional, only needed for search engine) Install Sphinx.  Build Sphinx config and start server:

          lobsters$ rake thinking_sphinx:rebuild

- Create an initial administrator user and at least one tag:

          lobsters$ rails console
          Loading development environment (Rails 3.2.6)
          irb(main):001:0> u = User.new(:username => "test", :email => "test@example.com", :password => "test")
          irb(main):002:0> u.is_admin = true
          irb(main):002:0> u.is_moderator = true
          irb(main):003:0> u.save

          irb(main):004:0> t = Tag.new
          irb(main):005:0> t.tag = "test"
          irb(main):006:0> t.save

- The default development hostname is defined as `lobsters.localhost:3000`.  You should define this in `/etc/hosts` (or through DNS) to point to `127.0.0.1`.

- Run the Rails server in development mode.  You should be able to login to `http://lobsters.localhost:3000` with your `test` user:

          lobsters$ rails server
