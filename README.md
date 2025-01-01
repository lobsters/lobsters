### Lobsters Rails Project [![build status](https://github.com/lobsters/lobsters/actions/workflows/check.yml/badge.svg)](https://github.com/lobsters/lobsters/actions/workflows/check.yml)

This is the
[quite sad](https://web.archive.org/web/20230213161624/https://old.reddit.com/r/rails/comments/6jz7tq/source_code_lobsters_a_hacker_news_clone_built/)
source code to the
[ghost town](https://twitter.com/webshitweekly/status/1399935275057389571) at
[https://lobste.rs](https://lobste.rs).
It is a Rails codebase and uses a SQL (MariaDB in production) backend for the database.

You are free to use this code to start your own [sister site](https://github.com/lobsters/lobsters/wiki)
because the code is available under a [permissive license](https://github.com/lobsters/lobsters/blob/master/LICENSE) (3-clause BSD).
We welcome bug reports and code contributions that help use improve [lobste.rs](https://lobste.rs).
As a volunteer project we're reluctant to take on work that's not useful to our site, so please understand if we don't want to adopt your custom feature.


#### Contributing bugfixes and new features

We'd love to have your help.
Please see the [CONTRIBUTING](https://github.com/lobsters/lobsters/blob/master/CONTRIBUTING.md) file for details.
If you have questions, there is usually someone in [our chat room](https://lobste.rs/chat) who's familiar with the code.


#### Development setup

Use the steps below for a local install or
[lobsters-ansible](https://github.com/lobsters/lobsters-ansible) for our production deployment config.
There's an external project [docker-lobsters](https://github.com/utensils/docker-lobsters) if you want to use Docker.

* Install and start MariaDB.
  On Linux use [your package manager](https://mariadb.com/kb/en/distributions-which-include-mariadb/).
  On MacOS you can [install with brew](https://mariadb.com/kb/en/installing-mariadb-on-macos-using-homebrew/).
  On Windows there's an [installer](https://mariadb.org/download/?t=mariadb&p=mariadb&r=11.5.2&os=Linux&cpu=x86_64&pkg=tar_gz&i=systemd&mirror=starburst_stlouis).

* Start the mariadb server using one of the [methods mentioned in the mariadb knowledge base](https://mariadb.com/kb/en/starting-and-stopping-mariadb-automatically/).

* Open the console using `mariadb`, and set the `root` user password (type `ctrl-d` to exit afterwards)

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'localdev';
```

* Install the Ruby version specified in [.ruby-version](https://github.com/lobsters/lobsters/blob/master/.ruby-version)

* Checkout the lobsters git tree from Github
    ```sh
    $ git clone git@github.com:lobsters/lobsters.git
    $ cd lobsters
    lobsters$
    ```

* Install Nodejs, needed (or other execjs) for uglifier
    ```sh
    Fedora: sudo yum install nodejs
    Ubuntu: sudo apt-get install nodejs
    OSX: brew install nodejs
    ```

* Run `rails credentials:edit` to create and edit your encrypted credentials file.
  This is where you store API keys for external services and features like linking accounts.
  Copy and paste the contents of `config/credentials.yml.enc.sample` in.
  On setup, Rails will give you new random value for `secret_key_base` and you can use `rails secret` any time you need to generate another.

* Run `bin/setup` to install dependencies and set up db

    ```sh
    lobsters$ bin/setup
    ```

* On your production server, copy `config/initializers/production.rb.sample`
  to `config/initalizers/production.rb` and customize it with your site's
  `domain` and `name`. (You don't need this on your dev machine).

* On your personal computer, you probably want to add some sample data.

    ```sh
    lobsters$ rails fake_data
    ```

* Run the Rails server in development mode.
  You should be able to login to `http://localhost:3000` with your new `test` user:

    ```sh
    lobsters$ rails server
    ```

* Deploying the site in production requires setting up a web server and running the app in production mode.
  There are more tools and options available than we can describe; find a guide or an expert.
  The lobsters-ansible repo has our config files to crib from. Some app-specific notes:

* Set up crontab or another scheduler to run regular jobs:

    ```
    */5 * * * *  cd /path/to/lobsters && env RAILS_ENV=production sh -c 'bundle exec ruby script/mail_new_activity; bundle exec ruby script/mastodon_sync.rb; bundle exec ruby script/traffic_range'
    ```

* On production, run `rails credentials:edit` to set up the credentials there,
  like you did for development.
  On setup, Rails will give you new random value for `secret_key_base` and you can use `rails secret` any time you need to generate another.
  Never `git commit` or share your `config/credentials.yml.enc`!

* You probably want to use [git-imerge](https://lobste.rs/s/dbm2d4) to pull in
  changes from Lobsters to your site.

#### Administration

Basic moderation happens on-site, but many administrative tasks require use of the rails console in production.
Administrators can create and edit tags at `/tags`.
