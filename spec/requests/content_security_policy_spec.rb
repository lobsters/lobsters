require 'rails_helper'

describe 'content security policy' do
  it 'sets the correct headers' do
    get '/'

    directives = [
      "default-src 'none'",
      "img-src * data:",
      "script-src 'self' 'unsafe-inline'",
      "style-src 'self' 'unsafe-inline'",
      "form-action 'self'",
      "report-uri /csp-violation-report"
    ].join('; ')

    expect(response.headers['Content-Security-Policy']).to eq(directives)
  end
end
