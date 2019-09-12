require 'rails_helper'

describe 'content security policy' do
  it 'sets the correct headers' do
    get '/'

    directives = [
      "default-src 'none'",
      "connect-src 'self'",
      "font-src 'self' https: data:",
      "img-src * data:",
      "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
      "style-src 'self' 'unsafe-inline'",
      "form-action 'self'",
      "report-uri /csp-violation-report",
    ].join('; ')

    expect(response.headers['Content-Security-Policy-Report-Only']).to eq(directives)
  end
end
