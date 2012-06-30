class Keystore < ActiveRecord::Base
  validates_presence_of :key

  attr_accessible nil

  def self.get(key)
    Keystore.find_by_key(key)
  end

  def self.put(key, value)
    Keystore.connection.execute("INSERT INTO #{Keystore.table_name} (" +
      "`key`, `value`) VALUES (#{q(key)}, #{q(value)}) ON DUPLICATE KEY " +
      "UPDATE `value` = #{q(value)}")
    true
  end

  def self.increment_value_for(key, amount = 1)
    self.incremented_value_for(key, amount)
  end

  def self.incremented_value_for(key, amount = 1)
    new_value = nil

    Keystore.connection.execute([ "INSERT INTO #{Keystore.table_name} (" +
      "`key`, `value`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `count` = " +
      "`count` + ?", key, amount, amount ])

    return self.value_for(key)
  end
  
  def self.decrement_value_for(key, amount = -1)
    self.increment_value_for(key, amount)
  end

  def self.decremented_value_for(key, amount = -1)
    self.incremented_value_for(key, amount)
  end

  def self.value_for(key)
    self.get(key).try(:value)
  end
end
