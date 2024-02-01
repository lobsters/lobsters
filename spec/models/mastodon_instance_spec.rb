# typed: false

RSpec.describe MastodonInstance, type: :model do
  it "is not valid without a name" do
    instance = MastodonInstance.new(client_id: "123", client_secret: "abc123")
    expect(instance).to_not be_valid
  end

  it "is not valid without a client_id" do
    instance = MastodonInstance.new(name: "mastodon.test", client_secret: "abc123")
    expect(instance).to_not be_valid
  end

  it "is not valid without a client_secret" do
    instance = MastodonInstance.new(name: "mastodon.test", client_id: "123")
    expect(instance).to_not be_valid
  end

  it "is valid with all required fields" do
    instance = MastodonInstance.new(
      name: "mastodon.test", client_id: "123", client_secret: "abc123"
    )
    expect(instance).to be_valid
  end
end
