require "rails_helper"

RSpec.feature "Checking messages" do
  context "see that there are unread messages and read them" do
    scenario "as the conversation author" do
      author = create(:user)
      stub_login_as author
      recipient = create(:user, username: "seafood")
      conversation = create(:conversation, author: author, recipient: recipient)
      create(
        :message,
        conversation: conversation,
        author: author,
        recipient: recipient,
      )
      create(
        :message,
        :unread,
        conversation: conversation,
        body: "testing one two three",
        author: recipient,
        recipient: author,
      )

      visit root_path
      click_on "1 Message"

      expect(current_path).to eq(conversations_path)
      expect(page).to have_css(".conversation.unread", text: "seafood")

      click_on "seafood"

      expect(page).to have_css(".message_text", text: "testing one two three")
    end

    scenario "as the conversation recipient" do
      author = create(:user, username: "seafood")
      recipient = create(:user)
      stub_login_as recipient
      conversation = create(:conversation, author: author, recipient: recipient)
      create(
        :message,
        :unread,
        body: "testing one two three",
        conversation: conversation,
        author: author,
        recipient: recipient
      )

      visit root_path
      click_on "1 Message"

      expect(current_path).to eq(conversations_path)
      expect(page).to have_css(".conversation.unread", text: "seafood")

      click_on "seafood"

      expect(page).to have_css(".message_text", text: "testing one two three")
    end
  end

  scenario "start a new conversation" do
    user = create(:user)
    stub_login_as user
    other_user = create(:user, username: "seafood")

    visit root_path
    click_on "Messages"
    within(".new_conversation") do
      fill_in "To", with: other_user.username
      fill_in "Subject", with: "Ahoy!"
      fill_in(
        "Message",
        with: "I was wondering if you'd like to get some chowder sometime."
      )
      click_on "Send Message"
    end
    conversation = Conversation.order(created_at: :desc).last

    expect(current_path).to eq(conversation_path(conversation))
    expect(page).to have_css("header", text: "Ahoy!")
    expect(page).to have_css("header", text: "with #{other_user.username}")
  end

  scenario "marks conversations read when they are viewed" do
    user = create(:user)
    stub_login_as user
    other_user = create(:user, username: "seafood")
    conversation = create(
      :conversation,
      author: user,
      recipient: other_user,
      subject: "hi",
    )
    create(
      :message,
      :unread,
      author: other_user,
      recipient: user,
      body: "Nice to meet you",
      conversation: conversation,
    )

    visit root_path
    click_on "1 Message"

    expect(page).to have_css(".conversation.unread .subject", text: "hi")

    click_on other_user.username
    visit conversations_path

    expect(page).not_to have_css(".conversation.unread .subject", text: "hi")
    expect(page).to have_css(".conversation .subject", text: "hi")
    expect(page).not_to have_css(".headerlinks .new_messages")
    expect(page).to have_css(".headerlinks", text: "Messages")
  end

  context "when the message is invalid" do
    scenario "it bubbles up error messages to the form" do
      max_message_length = 1024 * 64
      author = create(:user)
      stub_login_as author
      create(:user, username: "seafood")

      visit root_path
      click_on "Messages"
      within(".new_conversation") do
        fill_in("To:", with: "seafood")
        fill_in("Subject:", with: "subject")
        fill_in("Message:", with: "a" * (max_message_length + 1))
        click_on "Send Message"
      end

      within(".errorExplanation") do
        expect(page).to have_css("li", text: "Body is too long")
      end
    end
  end
end

RSpec.feature "add a message to a conversation" do
  scenario "as the author" do
    author = create(:user)
    stub_login_as author
    recipient = create(:user, username: "seafood")
    conversation = create(
      :conversation,
      author: author,
      recipient: recipient,
      subject: "hi",
    )
    create(
      :message,
      :unread,
      author: recipient,
      recipient: author,
      body: "Nice to meet you",
      conversation: conversation,
    )
    message_text = "Do you like lobster bisque?"

    visit root_path
    click_on "1 Message"
    click_on recipient.username
    within(".new_message") do
      fill_in("Message", with: message_text)
      click_on "Send Message"
    end

    within(".messages") do
      expect(page).to have_css(".author", text: author.username)
      expect(page).to have_css(".message_text", text: message_text)
    end
  end

  scenario "as the recipient" do
    author = create(:user)
    recipient = create(:user)
    stub_login_as recipient
    message_text = "Nice to meet you"
    conversation = create(
      :conversation,
      author: author,
      recipient: recipient,
      subject: "hi",
    )
    create(
      :message,
      :unread,
      author: author,
      recipient: recipient,
      conversation: conversation,
    )

    visit root_path
    click_on "1 Message"
    click_on author.username
    within(".new_message") do
      fill_in("Message", with: message_text)
      click_on "Send Message"
    end

    within(".messages") do
      expect(page).to have_css(".author", text: recipient.username)
      expect(page).to have_css(".message_text", text: message_text)
    end
  end

  context "as a hat wearer" do
    scenario "starts a conversation with a hat" do
      author = create(:user)
      stub_login_as author
      recipient = create(:user)
      hat = create(:hat, user: author)

      visit root_path
      click_on "Messages"
      within(".new_conversation") do
        fill_in("To", with: recipient.username)
        fill_in("Subject", with: "subject")
        fill_in("Message", with: "hello")
        select(hat.hat, from: "Put on hat:")
        click_on "Send Message"
      end

      within(".messages") do
        expect(page).to have_css(".author", text: hat.hat)
      end
    end

    scenario "adds a message to a conversation with a hat" do
      conversation = create(:conversation)
      author = conversation.author
      stub_login_as author
      create(
        :message,
        :read,
        author: author,
        recipient: conversation.recipient,
        body: "Nice to meet you",
        conversation: conversation,
      )
      hat = create(:hat, user: author)

      visit root_path
      click_on "Messages"
      click_on conversation.subject
      within(".new_message") do
        fill_in("Message", with: "hello")
        select(hat.hat, from: "Put on hat:")
        click_on "Send Message"
      end

      within(".messages") do
        expect(page).to have_css(".author", text: hat.hat)
      end
    end
  end

  context "as a moderator" do
    scenario "starts a conversation with a mod note" do
      author = create(:user, is_moderator: true)
      stub_login_as author
      recipient = create(:user)
      create(:hat, user: author)

      visit root_path
      click_on "Messages"
      within(".new_conversation") do
        fill_in("To", with: recipient.username)
        fill_in("Subject", with: "subject")
        fill_in("Message", with: "hello with modnote")
        check("ModNote")
        click_on "Send Message"
      end

      visit user_path(recipient)

      mod_notes = page.find(:table, text: "Mod → User/When")

      within(mod_notes) do
        expect(page).to have_text("hello with modnote")
      end
    end
  end

  context "when the message is invalid" do
    scenario "it shows the error messages on the form" do
      max_message_length = 1024 * 64
      conversation = create(:conversation)
      author = conversation.author
      stub_login_as author
      create(
        :message,
        :read,
        author: author,
        recipient: conversation.recipient,
        body: "Nice to meet you",
        conversation: conversation,
      )

      visit root_path
      click_on "Messages"
      click_on conversation.recipient.username

      within(".new_message") do
        fill_in("Message", with: "a" * (max_message_length + 1))
        click_on "Send Message"
      end

      within(".errorExplanation") do
        expect(page).to have_css("li", text: "Body is too long")
      end
    end
  end
end

RSpec.feature "delete a conversation" do
  scenario "I dare you" do
    conversation = create(:conversation)
    author = conversation.author
    stub_login_as author
    MessageForm.new(
      conversation: conversation,
      author: author,
      body: "Hello",
    ).save

    visit root_path
    click_on "Messages"
    click_on conversation.subject
    click_on "Delete Conversation"

    expect(current_path).to eq(conversations_path)
    expect(page).not_to have_css(".conversation", text: conversation.subject)
    expect(page).to have_css("h2.legend", text: "Create Conversation")
  end
end
