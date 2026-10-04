# frozen_string_literal: true

require_relative "authenticator"

module Tesla
  # Authenticator for OAuth 2.0 bearer token authentication
  # @api private
  class BearerTokenAuthenticator < Authenticator
    # The access token
    # @api private
    # @return [String] the access token
    # @example Get the access token
    #   authenticator.access_token
    attr_reader :access_token

    # Initialize a new BearerTokenAuthenticator
    #
    # @api private
    # @param access_token [String] the access token
    # @return [BearerTokenAuthenticator] a new instance
    # @example Create a bearer token authenticator
    #   authenticator = Tesla::BearerTokenAuthenticator.new(access_token: "eyJhbGciOiJSUzI1NiIs")
    def initialize(access_token:)
      @access_token = access_token
    end

    # Generate the authentication headers for a request
    #
    # @api private
    # @param _request [Net::HTTPRequest] the HTTP request
    # @return [Hash{String => String}] the authentication headers with the access token
    # @example Generate a bearer token authentication header
    #   authenticator.header(request)
    def header(_request)
      {AUTHENTICATION_HEADER => "Bearer #{access_token}"}
    end
  end
end
