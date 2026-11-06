class BackstopMailbox < ApplicationMailbox
  def process
    bounced!
  end
end
