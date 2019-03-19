###Journalduhacker Project

This is the source code of the website operating at
[https://www.journalduhacker.net](https://www.journalduhacker.net).  It is a Rails 4 codebase and uses a
SQL (MariaDB in production) backend for the database and Sphinx for the search
engine.

The new code is Carl Chenet © 2016-2017 (starting Nov 8 2016) licensed under the AGPLv3 license. See the license/LICENSE.journalduhacker for the full license.

This code is forked from the [lobste.rs](https://lobster.rs) engine, authored by Joshua Stein © 2012-2016 (until Nov 3 2016) licensed under the 3-BSD license. The current code is [available here](https://github.com/lobsters/). See the license/LICENSE.lobsters for the original license and copyright.


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

## Moderation

On-site tasks are carried out directly on the website. Console tasks are carried out through the Ruby on Rails console in production.
To start the Rails console: `rails c`. To start the Rails console and rollback on exit: `rails c --sandbox`.

Note: when moderating you should provide a moderation reason.

### On-site tasks

#### Edit/Delete a story

Click the 'edit' button under the story title. You can:
* Delete the story
* Edit the URL
* Edit the title
* Add or remove tags
* Edit the body text
* Merge the story into another

#### Delete a comment

Click the 'delete' button next to it.

#### Attach a moderation note to a user

Inside a user profile page, you can write moderation notes for that particular user. Only moderators can see them.

#### Disable invites for a user

Inside a user profile page, click the 'Disable Invites' button at the bottom.
You will be able to re-enable invites by clicking on 'Enable Invites'.

#### Ban a user

Inside a user profile page, click the 'Ban' button at the bottom. You must provide a reason.
You will be able to unban the user by clicking on 'Unban'.

#### Read the latest 10 moderation notes and moderations applied to a user

You can see them inside a user profile page. To see more than 10, you need to use the console.

#### Manage hats requests

Go to /hats/requests.

### Console tasks

A typical command to add a resource is:
```ruby
name_of_resource.create(attribute1: value1, attribute2: value2, ...)
```

To edit a resource first assign it to a variable, edit it and then save:
```ruby
story = Story.find_by(short_id: story_short_id)
story.attribute = new_attribute_value
story.save
```

To delete a resource (please see [difference between delete and destroy](https://stackoverflow.com/a/22757533/)):
```ruby
story = Story.find_by(short_id: story_short_id)
story.delete() # or story.destroy()
```

Note: all resources can be added, edited and deleted through the console. However, it will be usually used in the following cases:

#### Add/Edit/Disable tag

Available attributes:
* tag: name of the tag
* description: description of the tag
* privileged: if set to true, only moderators can post stories with this tag
* is_media: (?)
* inactive: if set to true, users cannot post stories with this tag anymore
* hotness_mod: (?)
