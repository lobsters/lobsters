require 'rails_helper'

RSpec.describe MastodonInstance, type: :model do
  required_fields = [:name, :client_id, :client_secret]

  required_fields.each do |field|
    it "has a #{field} field" do
      instance = MastodonInstance.new(
        name: field == :name ? nil : 'mastodon.test',
        client_id: field == :client_id ? nil : '123',
        client_secret: field == :client_secret ? nil : 'abc123'
      )
      expect(instance).to_not be_valid
    end
  end
end

