class KeystoreBigint < ActiveRecord::Migration
  def up
    execute("ALTER TABLE keystores CHANGE value value BIGINT")
  end

  def down
  end
end
