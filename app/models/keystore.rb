# typed: false

class Keystore < ApplicationRecord
  MAX_KEY_LENGTH = 50

  self.primary_key = "key"

  validates :key, presence: true, length: {maximum: MAX_KEY_LENGTH}

  def self.get(key)
    find_by(key: key)
  end

  def self.value_for(key)
    where(key: key).pick(:value)
  end

  def self.put(key, value)
    validate_input_key(key)
    Keystore.upsert({key: key, value: value}, returning: false)
    true
  end

  def self.increment_value_for(key, amount = 1)
    incremented_value_for(key, amount)
  end

  def self.incremented_value_for(key, amount = 1)
    validate_input_key(key)
    Keystore.transaction do
      Keystore.upsert({key: key, value: amount}, on_duplicate: Arel.sql("value = value + 1"))
      value_for(key)
    end
  end

  def self.find_or_create_key_for_update(key, init = nil)
    loop do
      found = lock(true).find_by(key: key)
      return found if found

      begin
        create! do |kv|
          kv.key = key
          kv.value = init
          kv.save!
        end
      rescue ActiveRecord::RecordNotUnique
        nil
      end
    end
  end

  def self.decrement_value_for(key, amount = -1)
    increment_value_for(key, amount)
  end

  def self.decremented_value_for(key, amount = -1)
    incremented_value_for(key, amount)
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

  def self.validate_input_key(key)
    exception = ActiveRecord::ValueTooLong.new("#{MAX_KEY_LENGTH}" \
      " characters is the maximum allowed for key")
    raise exception if key.length > MAX_KEY_LENGTH
  end
end
