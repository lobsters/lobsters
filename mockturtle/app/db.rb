require "sqlite3"

def setup_db_conn
  db = SQLite3::Database.new "test.db"
  db.execute <<-SQL
    create table if not exists rss (
      name varchar(50),
      date int
    );
    create table if not exists seen (
      name varchar(50),
    );
    create table if not exists tell (
      name varchar(50),
    );
  SQL
  return db
end
