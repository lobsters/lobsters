class Keystore < ApplicationRecord
  MAX_KEY_LENGTH = 50

  self.primary_key = "key"

  validates :key, presence: true, length: { maximum: MAX_KEY_LENGTH }

  def self.get(key)
    self.find_by(:key => key)
  end

  def self.value_for(key)
    self.find_by(:key => key).try(:value)
  end

  def self.put(key, value)
    validate_input_key(key)
    if Keystore.connection.adapter_name == "SQLite"
      Keystore.connection.execute("INSERT OR REPLACE INTO " <<
        "#{Keystore.table_name} (`key`, `value`) VALUES " <<
        "(#{q(key)}, #{q(value)})")
    elsif Keystore.connection.adapter_name =~ /Mysql/
      Keystore.connection.execute("INSERT INTO #{Keystore.table_name} (" +
        "`key`, `value`) VALUES (#{q(key)}, #{q(value)}) ON DUPLICATE KEY " +
        "UPDATE `value` = #{q(value)}")
    else
      kv = self.find_or_create_key_for_update(key, value)
      kv.value = value
      kv.save!
    end
    true
  end

  def self.increment_value_for(key, amount = 1)
    self.incremented_value_for(key, amount)
  end

  def self.incremented_value_for(key, amount = 1)
    validate_input_key(key)
    Keystore.transaction do
      if Keystore.connection.adapter_name == "SQLite"
        Keystore.connection.execute("INSERT OR IGNORE INTO " <<
          "#{Keystore.table_name} (`key`, `value`) VALUES " <<
          "(#{q(key)}, 0)")
        Keystore.connection.execute("UPDATE #{Keystore.table_name} " <<
          "SET `value` = `value` + #{q(amount)} WHERE `key` = #{q(key)}")
      elsif Keystore.connection.adapter_name =~ /Mysql/
        Keystore.connection.execute("INSERT INTO #{Keystore.table_name} (" +
          "`key`, `value`) VALUES (#{q(key)}, #{q(amount)}) ON DUPLICATE KEY " +
          "UPDATE `value` = `value` + #{q(amount)}")
      else
        kv = self.find_or_create_key_for_update(key, 0)
        kv.value = kv.value.to_i + amount
        kv.save!
        return kv.value
      end

      self.value_for(key)
    end
  end

  def self.find_or_create_key_for_update(key, init = nil)
    loop do
      found = self.lock(true).find_by(:key => key)
      return found if found

      begin
        self.create! do |kv|
          kv.key = key
          kv.value = init
          kv.save!
        end
      rescue ActiveRecord::RecordNotUnique
        nil
      end
    end
  end

  # deliberately no lock/transaction as TrafficHelper is on the hot path of every request
  def self.readthrough_cache(key, &blk)
    if (found = value_for(key))
      found
    else
      value = yield blk
      put(key, value)
      value
    end
  end

  def self.decrement_value_for(key, amount = -1)
    self.increment_value_for(key, amount)
  end

  def self.decremented_value_for(key, amount = -1)
    self.incremented_value_for(key, amount)
  end

  def self.validate_input_key(key)
    exception = ActiveRecord::ValueTooLong.new("#{MAX_KEY_LENGTH}" \
      " characters is the maximum allowed for key")
    raise exception if key.length > MAX_KEY_LENGTH
  end
end
