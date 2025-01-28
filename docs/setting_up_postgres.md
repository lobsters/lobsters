## Setup guide for postgres 
1. Copy the `config/database.postgres.yml` to `config/database.yaml`
2. Run `rails db:create`
3. Run `SCHEMA=db/schema.postgres.rb rails db:schema:load`
4. 
