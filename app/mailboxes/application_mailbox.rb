# typed: false

class ApplicationMailbox < ActionMailbox::Base
  # routing /something/i => :somewhere
  routing(/^#{Rails.application.shortname}-/ => :inbox)

  routing all: :backstop
end
