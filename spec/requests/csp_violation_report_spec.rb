require 'rails_helper'

describe 'csp violations', type: :request do
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
          "report-uri http://localhost:3000/csp-violation-report",
        ].join('; '),
        "referrer" => "http://localhost:3000/",
        "violated-directive" => "img-src",
      },
    }
  end

  it 'responds appropriately' do
    post '/csp-violation-report', params: { body: post_body.to_json, format: :json }
    expect(response).to have_http_status(:ok)
  end

  it 'records the violation' do
    allow(Rails.logger).to receive(:info)
    post '/csp-violation-report', params: { body: post_body.to_json, format: :json }
    expect(Rails.logger).to have_received(:info).with(/#{document_uri}/)
  end
end
