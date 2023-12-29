# typed: false

class MailingListMailer < ApplicationMailer
    def story_email(user, story, body)
      @body = body
      mail(to: user.email, subject: story_subject(story), content_type: "text/plain", content_transfer_encoding: "quoted-printable")
    end
  
    def comment_email(user, comment, story, body)
      @body = body
      mail(to: user.email, subject: story_subject(story, "Re: "), content_type: "text/plain", content_transfer_encoding: "quoted-printable")
    end
  
    private
  
    def story_subject(story, prefix = "")
      ss = "#{prefix}#{story.title}"
  
      story.tags.sort_by(&:tag).each do |t|
        ss << " [#{t.tag}]"
      end
  
      ss.quoted_printable(true)
    end
  end
  