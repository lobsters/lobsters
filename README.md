### Barnacles

is a way for Jack to talk to Trello people about Haskell. It's since
evolved into something weirder and better.

Our tech stack is:

* MariaDB
* Rails

### Please constribute

You can constribute by installing Barnacles. If you're on Linux, this
is pretty simple:

* `sudo pacman -Syu`
* `git clone git@github.com:hlian/barnacles.git`
* `cd barnacles`
* `bundle --jobs=4`

If you're on OS X, this is considerably more involved:

* `brew install ruby`
* `sudo ln -s /usr/local/bin/ruby /usr/bin/ruby`
* `sudo ln -s /usr/local/bin/gem /usr/bin/gem`
* reinstall all your preexisting system gems

(You can skip this part, but you better make sure your PATH is set up
correctly from now until the end of time. This is what happens when
you use an OS that comes with packages but not a package manager.)

* `gem update`
* `gem install bundler`
* `git clone git@github.com:hlian/barnacles.git`
* `cd barnacles`
* `bundle --jobs=4`

This concludes the Barnacles-specific part of the README. I'm going to
hand it over to Lobsters now. (We forked from Lobsters.)

## Goodbye!

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

          Lobsters::Application.config.secret_key_base = 'your random secret here'

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

## Postscript from Barnacles

If you want the search to work, you should set up a systemd-timer that
runs `bundle exec rake ts:rebuild`. See `etc/` for an example (an
incorrect example that doesn't `bundle exec` -- sorry guys, I'm
learning Ruby as I go along).
