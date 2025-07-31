### Lobsters Rails Project [![build status](https://github.com/lobsters/lobsters/actions/workflows/check.yml/badge.svg)](https://github.com/lobsters/lobsters/actions/workflows/check.yml)

[Lobsters](https://lobste.rs) is a Rails codebase and uses a SQL (MariaDB in production) backend for the database.
The code is open source as part of our [commitment to transparency](https://lobste.rs/about#transparency).
It's been used to run [sister sites](https://github.com/lobsters/lobsters/blob/main/sister_sites.md), but mostly we want people to be able to understand and improve what's happening on Lobsters itself.

(Despite the site being a [ghost town](https://xcancel.com/webshitweekly/status/1399935275057389571) running on a [quite sad codebase](https://web.archive.org/web/20230213161624/https://old.reddit.com/r/rails/comments/6jz7tq/source_code_lobsters_a_hacker_news_clone_built/), at least we have [no relation](https://lobste.rs/about#michaelbolton) to the self-help guru.)


#### Contributing bugfixes and new features

We'd love to have your help.
Please see the [CONTRIBUTING](https://github.com/lobsters/lobsters/blob/main/CONTRIBUTING.md) file for details.
If you have questions, there is usually someone in [our chat room](https://lobste.rs/chat) who's familiar with the code.

Lobsters is a volunteer project with limited development time and a long time horizon, we hope to be running for decades.
So our design philosophy is a little different than a typical commercial product:

 * We started with Rails 3.2.2 in 2012, so we have a few dusty corners and places where we don't take advantage of features that were introduced since we started.
 * We lean into using Rails features instead of custom code, and we'll write a couple dozen lines of narrow code for a feature rather than add a dependency that might require maintenance.
 * We are especially reluctant to add new production services like queues, caches, databases, or SAAS services.
 * We test to ensure functionality, but testing is a lot lighter for moderator and other non-core features.
   We're trying to maximize the return on investment of testing rather than minimize errors.
 * We're willing to take downtime for big code changes rather than try to make them seamless.


#### Development setup

We have a [Docker setup guide](./docs/setup_with_docker.md) if you use that for development, but you can also set up directly on your machine:

* Install and start MariaDB.
  On Linux use [your package manager](https://mariadb.com/kb/en/distributions-which-include-mariadb/).
  On MacOS you can [install with brew](https://mariadb.com/kb/en/installing-mariadb-on-macos-using-homebrew/).
  On Windows there's an [installer](https://mariadb.org/download/?t=mariadb&p=mariadb&r=11.5.2&os=Linux&cpu=x86_64&pkg=tar_gz&i=systemd&mirror=starburst_stlouis).

* Start the mariadb server using one of the [methods mentioned in the mariadb knowledge base](https://mariadb.com/kb/en/starting-and-stopping-mariadb-automatically/).

* Open the console using `mariadb`, and set the `root` user password (type `ctrl-d` to exit afterwards)

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'localdev';
```

* Install the Ruby version specified in [.ruby-version](https://github.com/lobsters/lobsters/blob/main/.ruby-version)

* Checkout the lobsters git tree from Github
    ```sh
    $ git clone git@github.com:lobsters/lobsters.git
    $ cd lobsters
    lobsters$
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

## Production

You are free to use this code to start your own [sister site](/sister_sites.md)
because the code is available under a [permissive license](https://github.com/lobsters/lobsters/blob/main/LICENSE) (3-clause BSD).
We welcome bug reports and code contributions that help use improve [lobste.rs](https://lobste.rs).
As a volunteer project we're reluctant to take on work that's not useful to our site, so please understand if we don't want to adopt your custom feature.
These instructions assume you know the basics of web development with Ruby on Rails on a Linux server.

Important: the hard part about starting an online community is not the codebase.
A new social site has to solve a chicken-and-egg problem:
nobody will want to participate on a new site until other people are participating.
Before you start working with the code, make a plan for how you'll reach potential community members and what they'll find engaging about the early days.
If you don't attract enough early users to reach a self-sustaining level of activity, the code doesn't matter!

As of February 2025 we have a [Zulip-based chat room](https://lobsters.zulipchat.com) to discuss the codebase and offer limited support to owners of sister sites like warnings about breaking changes and vulnerability announcements.
If you run a site using the codebase, you will benefit from joining.

Setup:

1. Fork the repo, clone it to your local computer.
   You should add lobsters as a git remote so you can continue to pull our changes.

2. Edit `config/application.rb` to put in your site's name and domain name.

3. We use a paid service called [Hatchbox](https://hatchbox.io) to set up and deploy the server.
   Reusing this config will be much easier than Heroku/Render/etc.
...Hatchbox has a clever wizard-style flow for getting started.
   I'm going to explain what our final settings are rather than try to stay current with the wizard setup.
   This should be all the info you need, just in a slightly different order.

  * Follow the [Hatchbox Docs](https://hatchbox.relationkit.io/) to create an account and connect a Hosting Provider.
    We use DigitalOcean because I was already familiar with it.
  * Create a Cluster, ours is called `lobsters`.
    We don't have any Cluster settings customized.
  * In your Cluster, create a Server.
    There's a [DO limitation](https://www.digitalocean.com/community/questions/how-do-i-create-a-reverse-dns-ptr-record) that the server name must match your domain name for them to create a reverse DNS PTR record that you'll need for email.
    We don't have any Server settings customized.
  * When a server is created, check if its [IP address is blacklisted for sending email](https://dnschecker.org/ip-blacklist-checker.php?query=68.183.100.95).
    Email spammers constantly try to create servers on every hosting provider.
    The providers ban them, but the IP address gets a bad reputation and may be on blocklists when it's assigned to you.
    Check your server's IP ASAP; it's much easier to delete and recreate than get off the blocklists, especially because outsiders don't have any insight into the internal blocklists of big email providers like Google, Apple, and Microsoft.
  * You'll need to create a Database.
    We use MariaDB in prod but are working to [migrate to SQLite](https://github.com/lobsters/lobsters/issues/539).
  * Create an App. Running through the Settings sections:
    * Processes: Add a `solid_queue` process, command `bundle exec rails solid_queue:start`.
    * Activity: This is logs, nothing to change.
    * Repository: Connect your GitHub repo.
    * Domains & SSL: Add your domain names, include both `example.org` and `www.example.org`.
    * Environment:

      ```
      BUNDLE_WITHOUT      development:test
      DATABASE_URL        trilogy://[username]:[password]@[1.2.3.4]/lobsters
      INGRESS_PASSWORD    [random generated key]
      PORT                9000
      RACK_ENV            production
      RAILS_ENV           production
      RAILS_LOG_TO_STDOUT true
      RAILS_MAX_THREADS   10
      SECRET_KEY_BASE     [random generated key]
      ```

      Search the codebase for uses of the `ENV` global for more that can be easily configured.

    * Databases: We manage this independely of Hatchbox for historic reasons, see `#539`.
    * Cron Jobs:

      ```
      expire_page_cache         * * * * *      script/expire_page_cache
      script/lobsters-cron    */5 * * * *      bundle exec script/lobsters-cron
      ```

    * Settings:
      We have tweaks of production config files and we want those [tracked in our git repo](https://github.com/lobsters/lobsters/tree/main/hatchbox).
      We have rigged up settings to run an (unfortunately) clever hook to update those on deploy, see below.

      Pre-build script: `hatchbox/pre-build`
      Custom build script: blank
      Post-build script: blank
      Post-deploy script: `hatchbox/post-deploy`
      Failed deploy script: blank
      Caddyfile: copy the text of the file `hatchbox/Caddyfile` from this repo.
        As it says, you have to manually paste it in on changes and click 'Update Caddy'.

  * Make a deployment with Hatchbox. Whew!

4. SSH into your server as the `root` user to set up the deploy hook.

    ```
    ln -s /home/deploy/lobsters/current/hatchbox/root-deploy.service /etc/systemd/system
    ln -s /home/deploy/lobsters/current/hatchbox/root-deploy.path /etc/systemd/system
    systemctl daemon-reload
    systemctl enable --now root-deploy.service # first backup takes 10ish min
    systemctl enable --now root-deploy.path
    ```

5. Deploy again with Hatchbox to run the hook and finish the server provisioning.

6. SSH into your server as the `deploy` user

   1. Run `rails credentials:edit` to set up credentials there, like you did for development.
      Use `config/credentials.yml.sample` for a template.
      On setup, Rails will give you new random value for `secret_key_base` and you can use `rails secret` any time you need to generate another.
      Never `git commit` or share your `config/credentials.yml.enc` or `config/master.key`.
   2. [Test your mail config for spamminess](https://www.mail-tester.com/).
      Run `echo "Test Postfix email, visit scnenic https://example.com" | mail -s "Postfix Test" test-whatever@srv1.mailtester.com`
   3. Run `rails console` and create a `User` for yourself, set `is_admin = true`.
      You'll probably also have to create a `Category` and one `Tag` for the site to run at all.
   4. See logs in `~deploy/sitename/shared/log`.

If everything worked, you should have a running instance now.


#### Administration

Basic moderation happens on-site, but some administrative tasks require use of the rails console in production.
Administrators can create and edit tags at `/tags`, the mod dashboard is at `/mod`.
