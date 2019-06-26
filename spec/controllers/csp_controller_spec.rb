require 'rails_helper'

describe CspController do
  describe '/csp-violation-report' do
    it 'records the violation' do
      body = {
        "csp-report" => {
          "blocked-uri" => "data",
          "document-uri" => "http://localhost:3000/s/izi825/hckr_news_hacker_news_sorted_by_time",
          "original-policy" => [
            "default-src 'none';",
            "img-src *;",
            "script-src 'self' 'unsafe-inline';",
            "style-src 'self' 'unsafe-inline';",
            "form-action 'self';",
            "report-uri http://localhost:3000/csp-violation-report",
          ].join(' '),
          "referrer" => "http://localhost:3000/",
          "violated-directive" => "img-src",
        },
      }
      post :violation_report, body: body.to_json, format: :json
      expect(response).to have_http_status(:ok)
    end
  end
end
