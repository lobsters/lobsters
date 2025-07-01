# typed: false

class CspController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user

  def violation_report
    body = request.body.read
    json = JSON.parse(body)

    return head :bad_request unless
      request.content_type == "application/csp-report" && json&.is_a?(Hash) && json["csp-report"].is_a?(Hash)

    report = json["csp-report"]
    Telebugs.context :report, report
    Telebugs.message body, fingerprint: ["csp-violation", report.dig("blocked-uri"), report.dig("effective-directive")]

    head :ok
  rescue JSON::ParserError
    head :bad_request
    nil
  end
end
