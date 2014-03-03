require "spec_helper"

describe EmailParser do
  before(:each) do
    @user = User.make!
    @story = Story.make!(:user => @user)

    @commentor = User.make!
    @comment = Comment.make!(:story => @story, :user => @commentor)

    @emailer = User.make!(:mailing_list_mode => 1)

    @emails = {}
    Dir.glob("#{Rails.root}/spec/fixtures/inbound_emails/*.eml").
    each do |f|
      @emails[File.basename(f).gsub(/\..*/, "")] = File.read(f).
        gsub(/##SHORTNAME##/, Rails.application.shortname).
        gsub(/##MAILING_LIST_TOKEN##/, @emailer.mailing_list_token).
        gsub(/##COMMENT_ID##/, @comment.short_id)
    end
  end

  it "can parse a valid e-mail" do
    parser = EmailParser.new(
      "user@example.com",
      Rails.application.shortname +
      "-#{@emailer.mailing_list_token}@example.org",
      @emails["1"])

    parser.should_not == nil
    parser.email.should_not == nil

    parser.user_token.should == @emailer.mailing_list_token
    parser.been_here?.should == false
    parser.sending_user.id.should == @emailer.id

    parser.parent.class.should == Comment
  end

  it "rejects mailing loops" do
    parser = EmailParser.new(
      "user@example.com",
      Rails.application.shortname +
      "-#{@emailer.mailing_list_token}@example.org",
      @emails["2"])

    parser.email.should_not == nil
    parser.been_here?.should == true
  end

  it "strips signatures" do
    parser = EmailParser.new(
      "user@example.com",
      Rails.application.shortname +
      "-#{@emailer.mailing_list_token}@example.org",
      @emails["3"])

    parser.email.should_not == nil
    parser.body.should == "It hasn't decreased any measurable amount but since the traffic to\nthe site is increasing a bit each week, it's hard to tell."
  end

  it "strips quoted lines with attribution" do
    parser = EmailParser.new(
      "user@example.com",
      Rails.application.shortname +
      "-#{@emailer.mailing_list_token}@example.org",
      @emails["4"])

    parser.email.should_not == nil
    parser.body.should == "It hasn't decreased any measurable amount but since the traffic to\nthe site is increasing a bit each week, it's hard to tell."
  end
end
