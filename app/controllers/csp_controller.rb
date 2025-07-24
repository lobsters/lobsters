# typed: false

class CspController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user
  skip_after_action :clear_session_cookie

  # adapted from https://github.com/getsentry/sentry/blob/15544d9be92922ef09ae59d04fd60bc0982f52e5/src/sentry/interfaces/security.py#L13
  IGNORED_SCHEMES = [
    "about",
    "chrome",
    "chrome-extension",
    "chromeinvokeimmediate",
    "chromenull",
    "jar",
    "mbinit",
    "moz-extension",
    "ms-browser-extension",
    "ms-browser-extension",
    "mxaddon-pkg",
    "resource",
    "safari-extension",
    "safari-web-extension",
    "symres",
    "tmtbff",
    "webviewprogressproxy"
  ].freeze

  def violation_report
    body = request.body.read
    json = JSON.parse(body)

    return head :bad_request unless
      request.content_type == "application/csp-report" && json&.is_a?(Hash) && json["csp-report"].is_a?(Hash)

    report = json["csp-report"]

    source_file = report.dig("source-file")
    if source_file
      begin
        uri = URI.parse(source_file)

        if IGNORED_SCHEMES.include? uri.scheme
          return head :ok
        end
      rescue URI::InvalidURIError
      end
    end

    Telebugs.context :report, report
    Telebugs.message body, fingerprint: ["csp-violation", report.dig("blocked-uri"), report.dig("effective-directive")]

    head :ok
  rescue JSON::ParserError
    head :bad_request
    nil
  end
end
