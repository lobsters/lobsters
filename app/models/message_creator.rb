class MessageCreator
  class << self
    def create(conversation:, author:, params:)
      conversation.messages.create(
        subject: conversation.subject,
        author: author,
        recipient: conversation.partner(of: author),
        body: params[:body],
        hat_id: params[:hat_id],
      ).tap do |message|
        if create_modnote?(params) && author.is_moderator?
          ModNote.create_from_message(message, author)
        end
      end
    end

    private

      def create_modnote?(params)
        params[:mod_note] == "1"
      end
  end
end
