# frozen_string_literal: true
# typed: false

require 'graphql/client'
require 'graphql/client/http'

CLIENT_ID = 'quantumnews'

class AqoraApi
  SCHEMA = GraphQL::Client.load_schema(Rails.root.join('config', 'aqora.graphql.json').to_s)
  PARSER = GraphQL::Client.new(schema: SCHEMA, execute: nil)

  OAuth2TokenMutation = PARSER.parse <<~GRAPHQL
    mutation($client_id: String!, $redirect_uri: Url!, $code: String!) {
      oauth2Token(
        input: { clientId: $client_id, redirectUri: $redirect_uri, code: $code }
      ) {
        clientError
        unauthorized
        issued {
          accessToken
          refreshToken
        }
      }
    }
  GRAPHQL

  ViewerQuery = PARSER.parse <<~GRAPHQL
    query {
      viewer {
        id
        username
        email
        website
        bio
        github
      }
    }
  GRAPHQL

  def initialize(url)
    @http = GraphQL::Client::HTTP.new(url) do
      def headers(context)
        puts "context: #{context.inspect}"
        headers = {}
        headers['Authorization'] = "Bearer #{context[:access_token]}" if context.key?(:access_token)
        headers
      end
    end
    @client = GraphQL::Client.new(schema: SCHEMA, execute: @http)
  end

  def oauth2_token(code, redirect_uri)
    @client.query(OAuth2TokenMutation, variables: {
                    client_id: CLIENT_ID, code:, redirect_uri:
                  }, context: {})
  end

  def viewer(access_token)
    @client.query(ViewerQuery, context: { access_token: })
  end
end

class GraphQLClientError < StandardError
  attr_reader :errors

  def initialize(message, errors)
    super(message)
    @errors = errors
  end

  def self.from_errors(errors)
    begin
      message = errors.messages['data'].join(' ')
    rescue StandardError
      message = 'GraphQL error'
    end
    new(message, errors)
  end
end

class AqoraOAuth2TokenError < GraphQLClientError; end
class AqoraOAuth2ViewerError < GraphQLClientError; end
class AqoraOAuth2ClientError < StandardError; end
class AqoraOAuth2UnauthorizedError < StandardError; end

class Aqora
  cattr_reader :url

  @url = 'https://app.aqora.io'
  @api = nil

  def self.url=(url)
    @url = url
    @api = nil
  end

  def self.relative_url(url)
    URI.join(@url, url)
  end

  def self.api
    @api = AqoraApi.new(relative_url('/graphql')) if @api.nil?
    @api
  end

  def self.oauth_callback_user(callback_uri)
    uri = URI.parse(callback_uri)
    code = CGI.parse(uri.query)['code'].first
    redirect_uri = uri.origin + uri.path
    oauth2_token = api.oauth2_token(code, redirect_uri)

    raise AqoraOAuth2TokenError.from_errors(oauth2.token.errors) unless oauth2_token.errors.empty?
    raise AqoraOAuth2UnauthorizedError if oauth2_token.data.oauth2_token.unauthorized.present?
    raise AqoraOAuth2ClientError if oauth2_token.data.oauth2_token.client_error.present?

    access_token = oauth2_token.data.oauth2_token.issued.access_token
    refresh_token = oauth2_token.data.oauth2_token.issued.refresh_token
    viewer = api.viewer(access_token)

    raise AqoraOAuth2ViewerError.from_errors(viewer.errors) unless viewer.errors.empty?

    [refresh_token, viewer.data.viewer]
  end

  def self.oauth_auth_url(state)
    relative_url("/oauth2/authorize?client_id=#{CLIENT_ID}&state=#{state}")
  end
end
