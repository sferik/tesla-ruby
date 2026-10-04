# frozen_string_literal: true

require "simple_oauth"
require "uri"
require_relative "authenticator"
require_relative "bearer_token_authenticator"
require_relative "errors/oauth_error"

module Tesla
  # The credentials of a client, and the tokens it asks Tesla's authorization server for, mixed into {Client}
  #
  # The requests to the token endpoint are built by the simple_oauth gem and sent on the connection of the client,
  # so that the timeouts, the proxy, and the certificates of the client apply to them.
  #
  # A refresh token of the Fleet API is used once: refreshing the access token answers with another refresh token,
  # and the one it was asked for with stops working a day later. Two threads refreshing with the same refresh token
  # would each be answered with tokens of their own, so a client refreshes one thread at a time, and a thread that
  # waited for another to refresh uses the token that thread was answered with rather than refreshing again.
  #
  # @api private
  module ClientCredentials
    # The access token requests are authorized with
    # @api public
    # @return [String, nil] the access token
    # @example Get or set the access token
    #   client.access_token = "eyJhbGciOiJSUzI1NiIs"
    attr_accessor :access_token

    # The refresh token a new access token is asked for with
    #
    # This is the refresh token the last refresh answered with, once the client has refreshed its access token.
    #
    # @api public
    # @return [String, nil] the refresh token
    # @example Get or set the refresh token
    #   client.refresh_token = "NA_9d0b4bfd0c4c3a6e"
    attr_accessor :refresh_token

    # The client ID of the application, as developer.tesla.com issued it
    # @api public
    # @return [String, nil] the client ID
    # @example Get or set the client ID
    #   client.client_id = "81527cff06843c8634fdc09e8ac0abef"
    attr_accessor :client_id

    # The client secret of the application, as developer.tesla.com issued it
    # @api public
    # @return [String, nil] the client secret
    # @example Get or set the client secret
    #   client.client_secret = "ta-secret.7vx6VkVvk2gBgSrN"
    attr_accessor :client_secret

    # The URL the authorization server sends a user back to
    # @api public
    # @return [String, nil] the redirect URI
    # @example Get or set the redirect URI
    #   client.redirect_uri = "https://example.com/auth/callback"
    attr_accessor :redirect_uri

    # Set the audience tokens are issued for
    # @api public
    # @param value [String, nil] the host of the Fleet API the tokens are used with, or nil for the host of the client
    # @return [void]
    # @example Issue tokens for the Fleet API for Europe while requests are sent through a proxy
    #   client.audience = Tesla::Configuration::EUROPE_HOST
    attr_writer :audience

    # The URL a user is sent to in order to authorize the application
    # @api public
    # @return [String] the authorization endpoint
    # @example Get or set the authorization endpoint
    #   client.authorization_endpoint = "https://auth.tesla.cn/oauth2/v3/authorize"
    attr_accessor :authorization_endpoint

    # The URL tokens are issued and refreshed at
    # @api public
    # @return [String] the token endpoint
    # @example Get or set the token endpoint
    #   client.token_endpoint = "https://auth.tesla.cn/oauth2/v3/token"
    attr_accessor :token_endpoint

    # What is called with the token each time the access token is refreshed
    # @api public
    # @return [#call, nil] what is called with the `SimpleOAuth::OAuth2::Token`, or nil to call nothing
    # @example Store the tokens each time they are refreshed
    #   client.on_token_refresh = ->(token) { File.write("refresh_token", token.refresh_token) }
    attr_accessor :on_token_refresh

    # The audience tokens are issued for
    #
    # @api public
    # @return [String] the host of the Fleet API the tokens are used with, which is the host of the client unless
    #   another has been assigned
    # @example Get the audience
    #   client.audience
    def audience
      @audience || host
    end

    private

    # Assign the credentials the client is built with
    #
    # @api private
    # @param credentials [Hash{Symbol => Object}] the credentials, each named as the setting it is assigned to
    # @return [void]
    def initialize_credentials(**credentials)
      @token_mutex = Mutex.new
      credentials.each { |setting, value| public_send(:"#{setting}=", value) }
    end

    # The authenticator for a request authorized with an access token
    #
    # @api private
    # @param access_token [String, nil] the access token, or nil to send the request without one
    # @return [Authenticator] the authenticator
    def authenticator_for(access_token)
      access_token ? BearerTokenAuthenticator.new(access_token:) : Authenticator.new
    end

    # Whether the client has what a refresh of its access token takes
    #
    # @api private
    # @return [Boolean] whether the client has a refresh token and a client ID
    def refreshable?
      [refresh_token, client_id].none?(&:nil?)
    end

    # Run a block while no other thread refreshes the tokens of the client
    #
    # @api private
    # @yield while the tokens are held
    # @return [Object] what the block returned
    def exclusively(&)
      @token_mutex.synchronize(&)
    end

    # The access token to authorize a request with, refreshed when it is stale
    #
    # The token is refreshed only while it is still the stale one, so that a thread that waited for another to
    # refresh it is given the token that thread was answered with rather than using a refresh token a second time.
    # A client without an access token is given one this way before its first request, since nil is the token it
    # has until then.
    #
    # @api private
    # @param stale [String, nil] the access token that is no longer good, or nil for none
    # @return [String, nil] the access token, or nil when the client has none and cannot refresh
    def renewed_access_token(stale)
      exclusively do
        refresh if refreshable? && access_token.eql?(stale)
        access_token
      end
    end

    # Ask the token endpoint for a new access token with the refresh token
    #
    # @api private
    # @return [SimpleOAuth::OAuth2::Token] the token
    # @raise [ArgumentError] if the client has no refresh token or no client ID
    # @raise [OAuthError] if the token endpoint turns the request away
    def refresh
      current = refresh_token
      raise ArgumentError, "A refresh_token is required to refresh the access token" if current.nil?

      token = store_token(request_token(oauth_client.refresh_token_request(refresh_token: current)))
      on_token_refresh&.call(token)
      token
    end

    # Keep the tokens the token endpoint answered with
    #
    # The refresh token is kept as it was when the response carries none.
    #
    # @api private
    # @param token [SimpleOAuth::OAuth2::Token] the token
    # @return [SimpleOAuth::OAuth2::Token] the token
    def store_token(token)
      @access_token = token.access_token
      @refresh_token = token.refresh_token || refresh_token
      token
    end

    # The OAuth 2.0 client that builds the requests for the authorization server
    #
    # The client secret is sent in the body of a request, as the token endpoint reads it.
    #
    # @api private
    # @return [SimpleOAuth::OAuth2::Client] the OAuth 2.0 client
    # @raise [ArgumentError] if the client has no client ID
    def oauth_client
      id = client_id
      raise ArgumentError, "A client_id is required to ask the authorization server for a token" if id.nil?

      SimpleOAuth::OAuth2::Client.new(client_id: id, client_secret:, authorization_endpoint:, token_endpoint:,
        auth_method: :client_secret_post)
    end

    # Send a request to the token endpoint, and read the token it answers with
    #
    # @api private
    # @param oauth_request [SimpleOAuth::OAuth2::Request] the request, as simple_oauth built it
    # @return [SimpleOAuth::OAuth2::Token] the token
    # @raise [OAuthError] if the token endpoint turns the request away, or answers without a token
    # @raise [NetworkError] if the request is lost to the network
    def request_token(oauth_request)
      response = perform_token_request(oauth_request)
      SimpleOAuth::OAuth2::Token.from_response(status: response.code, body: response.body)
    rescue SimpleOAuth::OAuth2::Error => e
      raise OAuthError.new(code: e.code, description: e.description, status: e.status)
    end

    # Send a request to the token endpoint
    #
    # A request a rate limiter turned away is sent again, as any request is, but one that went unanswered is not,
    # since the token endpoint may have used the refresh token it carried.
    #
    # @api private
    # @param oauth_request [SimpleOAuth::OAuth2::Request] the request, as simple_oauth built it
    # @return [Net::HTTPResponse] the response
    # @raise [NetworkError] if the request is lost to the network
    def perform_token_request(oauth_request)
      uri = URI(oauth_request.url)
      body = oauth_request.body
      headers = oauth_request.headers
      retry_handler.handle(retry_unanswered: false) do
        connection.perform(request: request_builder.build(http_method: :post, uri:, body:, headers:))
      end
    end
  end
end
