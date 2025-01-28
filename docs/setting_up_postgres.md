## Setup guide for postgres 
1. Copy the `config/database.postgres.yml` to `config/database.yaml`
2. Run `rails db:create` to create the database
3. Run `SCHEMA=db/schema.postgres.rb rails db:schema:load` to populate the schema
4. Run `rails db:seed` to generate some data.
5. Run `rails fake_data` to populate the data into the database. 
