require "rails_helper"

describe Keystore do
  let(:valid_key) { "a" * 50 }
  let(:invalid_key) { "a" * 51 }
  let(:value) { rand(100) }

  describe "should not raise any errors when" do
    it "send valid arguments to service class interfaces #put" do
      expect { Keystore.put(valid_key, value) }.not_to raise_error
    end

    it "send valid arguments to service class interfaces #incremented_value_for" do
      expect { Keystore.incremented_value_for(valid_key, value) }.not_to raise_error
    end
  end

  describe "#increment_value_for" do
    it "adds and subtracts" do
      Keystore.put(valid_key, 5)

      expect(Keystore.increment_value_for(valid_key)).to eq(6)
      expect(Keystore.increment_value_for(valid_key, -1)).to eq(5)
      expect(Keystore.increment_value_for(valid_key, 3)).to eq(8)
    end
  end

  describe "should raise error when" do
    it "send invalid arguments to service class interfaces #put" do
      expect { Keystore.put(invalid_key, value) }
        .to raise_error("50 characters is the maximum allowed for key")
    end

    it "send invalid arguments to service class interfaces #incremented_value_for" do
      expect { Keystore.incremented_value_for(invalid_key, value) }
        .to raise_error("50 characters is the maximum allowed for key")
    end
  end
end
