# typed: false

require "rails_helper"

describe "stories#check_url_dupe XSS via comment excerpt", type: :request do
  it "does not re-inject escaped comment markup as a live tag" do
    user = create(:user)
    sign_in user
    url = "http://example.com/"

    comment = create(:comment, comment: "<img src=x onerror=alert(document.domain)> #{url}")
    # safely escaped
    expect(comment.markeddown_comment).to include("&lt;img")
    expect(comment.markeddown_comment).not_to include("<img")

    # try to submit the link as a story
    post "/stories/check_url_dupe.html", params: {story: {url: url}}

    # confirm the excerpt didn't parse the &lt; back into <
    expect(response).to have_http_status(200)
    expect(response.body).to include("This link has recently appeared in comments")
    expect(response.body).not_to match(/<img[^>]*onerror/i)
    expect(response.body).to include("&lt;img")
  end
end
