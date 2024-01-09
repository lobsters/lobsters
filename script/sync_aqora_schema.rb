#!/usr/bin/env ruby

# frozen_string_literal: true

require 'graphql/client'
require 'graphql/client/http'

filename = File.expand_path('../config/aqora.graphql.json', __dir__)
puts filename

HTTP = GraphQL::Client::HTTP.new(ARGV[1] || 'http://localhost:3000')
Schema = GraphQL::Client.dump_schema(HTTP, filename)
