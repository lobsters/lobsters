# typed: false

require "rails_helper"

describe "csp violations", type: :request do
  let(:document_uri) { "http://localhost:3000/s/izi825/hckr_news_hacker_news_sorted_by_time" }
  let(:post_body) do
    {
      "csp-report" => {
        "blocked-uri" => "data",
        "document-uri" => document_uri,
        "original-policy" => [
          "default-src 'none'",
          "img-src *",
          "script-src 'self' 'unsafe-inline'",
          "style-src 'self' 'unsafe-inline'",
          "form-action 'self'",
          "report-uri http://localhost:3000/csp-violation-report"
        ].join("; "),
        "referrer" => "http://localhost:3000/",
        "violated-directive" => "img-src"
      }
    }
  end

  it "responds appropriately" do
    post "/csp-violation-report", params: post_body.to_json, headers: {"Content-Type": "application/csp-report"}
    expect(response).to have_http_status(:ok)
  end

  it "requires correct content type" do
    post "/csp-violation-report", params: post_body.to_json, headers: {"Content-Type": "application/json"}
    expect(response).to have_http_status(:bad_request)

    post "/csp-violation-report", params: post_body.to_json
    expect(response).to have_http_status(:bad_request)
  end

  it "requires csp-report child" do
    post "/csp-violation-report", params: "[1,2,3]", headers: {"Content-Type": "application/csp-report"}
    expect(response).to have_http_status(:bad_request)

    post "/csp-violation-report", params: '{"key": 5}', headers: {"Content-Type": "application/csp-report"}
    expect(response).to have_http_status(:bad_request)

    post "/csp-violation-report", params: '{"csp-report": 5}', headers: {"Content-Type": "application/csp-report"}
    expect(response).to have_http_status(:bad_request)

    post "/csp-violation-report", params: '{"csp-report": [1,2,3]}', headers: {"Content-Type": "application/csp-report"}
    expect(response).to have_http_status(:bad_request)
  end
end
