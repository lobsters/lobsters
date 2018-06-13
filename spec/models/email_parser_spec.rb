require "rails_helper"

describe EmailParser do
  before(:each) do
    @user = create(:user)
    @story = create(:story, :user => @user)

    @commentor = create(:user)
    @comment = create(:comment, :story => @story, :user => @commentor)

    @emailer = create(:user, :mailing_list_mode => 1)

    @emails = {}
    Dir.glob("#{Rails.root}/spec/fixtures/inbound_emails/*.eml")
    .each do |f|
      @emails[File.basename(f).gsub(/\..*/, "")] = File.read(f)
        .gsub(/##SHORTNAME##/, Rails.application.shortname)
        .gsub(/##MAILING_LIST_TOKEN##/, @emailer.mailing_list_token)
        .gsub(/##COMMENT_ID##/, @comment.short_id)
    end
  end

  it "can parse a valid e-mail" do
    parser = EmailParser.new(
      "user@example.com",
      Rails.application.shortname +
      "-#{@emailer.mailing_list_token}@example.org",
      @emails["1"])

    expect(parser).to_not be_nil
    expect(parser.email).to_not be_nil

    expect(parser.user_token).to eq(@emailer.mailing_list_token)
    expect(parser.been_here?).to be false
    expect(parser.sending_user.id).to eq(@emailer.id)

    expect(parser.parent.class).to be Comment
  end

  it "rejects mailing loops" do
    parser = EmailParser.new(
      "user@example.com",
      Rails.application.shortname +
      "-#{@emailer.mailing_list_token}@example.org",
      @emails["2"])

    expect(parser.email).to_not be_nil
    expect(parser.been_here?).to be true
  end

  it "strips signatures" do
    parser = EmailParser.new(
      "user@example.com",
      Rails.application.shortname +
      "-#{@emailer.mailing_list_token}@example.org",
      @emails["3"])

    expect(parser.email).to_not be_nil
    expect(parser.body)
      .to eq("It hasn't decreased any measurable amount but since the traffic to\n" <<
             "the site is increasing a bit each week, it's hard to tell.")
  end

  it "strips quoted lines with attribution" do
    parser = EmailParser.new(
      "user@example.com",
      Rails.application.shortname +
      "-#{@emailer.mailing_list_token}@example.org",
      @emails["4"])

    expect(parser.email).to_not be_nil
    expect(parser.body)
      .to eq("It hasn't decreased any measurable amount but since the traffic to\n" <<
             "the site is increasing a bit each week, it's hard to tell.")
  end
end
