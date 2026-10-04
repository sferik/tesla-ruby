# frozen_string_literal: true

require "forwardable"
require "uri"
require_relative "api"
require_relative "client_credentials"
require_relative "configuration"
require_relative "connection"
require_relative "idempotence"
require_relative "redirect_handler"
require_relative "request_builder"
require_relative "response_parser"
require_relative "retry_handler"
require_relative "url_validation"

module Tesla
  # A client for the Tesla Fleet API
  # @api public
  class Client
    extend Forwardable
    include API
    include ClientCredentials
    include Idempotence
    include URLValidation

    # The status the Fleet API answers a request with when its access token is missing, expired, or revoked
    UNAUTHORIZED_STATUS = "401"
    private_constant :UNAUTHORIZED_STATUS

    # The host for API requests
    # @api public
    # @return [String] the host for API requests, including scheme
    # @example Get the host
    #   client.host
    attr_reader :host

    def_delegators :@connection, :open_timeout, :read_timeout, :write_timeout, :keep_alive_timeout, :proxy_url, :debug_output
    def_delegators :@connection, :open_timeout=, :read_timeout=, :write_timeout=, :keep_alive_timeout=, :proxy_url=, :debug_output=
    def_delegators :@connection, :ca_file, :ca_file=
    def_delegators :@redirect_handler, :max_redirects, :max_redirects=
    def_delegators :@retry_handler, :max_retries, :max_retry_delay
    def_delegators :@retry_handler, :max_retries=, :max_retry_delay=
    def_delegators :@request_builder, :user_agent
    def_delegators :@request_builder, :user_agent=

    # The methods of Forwardable, which the class delegates with rather than offers, so that `Client.delegate` and
    # the rest are not mistaken for methods of the API
    private_class_method(*Forwardable.instance_methods)

    # Build a client, and close it once a block is done with it
    #
    # Without a block the client is returned, as it is from any other constructor. With one, the client is given to
    # the block and its connections are closed once the block returns or raises, as `Net::HTTP.start` closes the
    # connection it opened, and what the block returns is returned. The client can still be used afterwards, since
    # a closed client opens its connections again as it needs them.
    #
    # The options are handed to {#initialize}, which is what declares them, so they are collected here and named
    # there.
    #
    # @api public
    # @param options [Hash] the options of {#initialize}
    # @yield [client] the client, which is closed once the block is done with it
    # @return [Client, Object] the client, or what the block returned
    # @example Close the connections of a client once a series of requests is done
    #   vehicles = Tesla::Client.new(access_token: "eyJhbGciOiJSUzI1NiIs") do |client|
    #     client.vehicles
    #   end
    def self.new(**options) # steep:ignore DifferentMethodParameterKind
      client = super

      return client unless block_given?

      begin
        yield client
      ensure
        client.close
      end
    end

    # Initialize a new Tesla Fleet API client
    #
    # Every option defaults to the global configuration (see {Tesla.configure}).
    #
    # A client with an access token alone sends it until it expires. One that also has a refresh token and a client
    # ID asks for a new access token when the Fleet API answers that the one it sent is no longer good, and one
    # with those and no access token asks for one before its first request.
    #
    # @api public
    # @param host [String] the host for API requests, including scheme
    # @param access_token [String, nil] the access token requests are authorized with
    # @param refresh_token [String, nil] the refresh token a new access token is asked for with
    # @param client_id [String, nil] the client ID of the application
    # @param client_secret [String, nil] the client secret of the application
    # @param redirect_uri [String, nil] the URL the authorization server sends a user back to
    # @param audience [String, nil] the host of the Fleet API tokens are issued for, or nil for the host
    # @param authorization_endpoint [String] the URL a user is sent to in order to authorize the application
    # @param token_endpoint [String] the URL tokens are issued and refreshed at
    # @param on_token_refresh [#call, nil] what is called with the token each time the access token is refreshed
    # @param user_agent [String] the 'User-Agent' HTTP header sent with requests
    # @param open_timeout [Numeric] the timeout for opening connections in seconds
    # @param read_timeout [Numeric] the timeout for reading responses in seconds
    # @param write_timeout [Numeric] the timeout for writing requests in seconds
    # @param debug_output [IO, nil] the IO object for debug output
    # @param proxy_url [String, nil] the proxy URL for requests
    # @param keep_alive_timeout [Numeric] the seconds an idle connection is kept open for another request
    # @param max_redirects [Integer] the maximum number of redirects to follow
    # @param ca_file [String, nil] the path of a file of certificates TLS is verified with
    # @param max_retries [Integer] the number of times a request that was turned away is sent again
    # @param max_retry_delay [Numeric] the longest a request waits before it is sent again, in seconds
    # @return [Client] a new client instance
    # @example Create a client with an access token
    #   client = Tesla::Client.new(access_token: "eyJhbGciOiJSUzI1NiIs")
    # @example Create a client that refreshes its access token
    #   client = Tesla::Client.new(client_id: "81527cff06843c8634fdc09e8ac0abef",
    #     refresh_token: "NA_9d0b4bfd0c4c3a6e")
    # @example Create a client that sends requests through the vehicle command proxy
    #   client = Tesla::Client.new(host: "https://localhost:4443", ca_file: "config/tls-cert.pem",
    #     audience: Tesla::Configuration::NORTH_AMERICA_HOST)
    # @raise [ArgumentError] if the host is not an HTTP or HTTPS URL, or the certificate path names nothing
    def initialize(host: Tesla.host, access_token: Tesla.access_token, refresh_token: Tesla.refresh_token,
      client_id: Tesla.client_id, client_secret: Tesla.client_secret, redirect_uri: Tesla.redirect_uri,
      audience: Tesla.audience, authorization_endpoint: Tesla.authorization_endpoint, token_endpoint: Tesla.token_endpoint,
      on_token_refresh: Tesla.on_token_refresh,
      user_agent: Tesla.user_agent,
      open_timeout: Tesla.open_timeout,
      read_timeout: Tesla.read_timeout,
      write_timeout: Tesla.write_timeout,
      debug_output: Tesla.debug_output,
      proxy_url: Tesla.proxy_url,
      keep_alive_timeout: Tesla.keep_alive_timeout,
      max_redirects: Tesla.max_redirects,
      ca_file: Tesla.ca_file,
      max_retries: Tesla.max_retries,
      max_retry_delay: Tesla.max_retry_delay)
      @host = validate_host(host)
      @connection = Connection.new(open_timeout:, read_timeout:, write_timeout:, debug_output:, proxy_url:,
        keep_alive_timeout:, ca_file:)
      @request_builder = RequestBuilder.new(user_agent:)
      @redirect_handler = RedirectHandler.new(connection: @connection, request_builder: @request_builder, max_redirects:)
      @retry_handler = RetryHandler.new(max_retries:, max_retry_delay:)
      @response_parser = ResponseParser.new
      initialize_credentials(access_token:, refresh_token:, client_id:, client_secret:, redirect_uri:, audience:,
        authorization_endpoint:, token_endpoint:, on_token_refresh:)
    end

    # Set the host for API requests
    #
    # @api public
    # @param host [String] the host for API requests, including scheme
    # @return [void]
    # @raise [ArgumentError] if the host is not an HTTP or HTTPS URL, in which case the host is left as it was
    # @example Set the host
    #   client.host = Tesla::Configuration::EUROPE_HOST
    def host=(host)
      @host = validate_host(host)
    end

    # Summarize the client for the console
    #
    # @api public
    # @return [String] the summary, which includes the host but never credentials
    # @example Inspect a client
    #   client.inspect # => #<Tesla::Client host="https://fleet-api.prd.na.vn.cloud.tesla.com">
    def inspect
      "#<#{self.class} host=#{host.inspect}>"
    end

    # Close the connections the client keeps open for the next request
    #
    # The connections are opened again as they are needed, so requests can still be made afterwards.
    #
    # @api public
    # @return [Client] the client
    # @example Close the connections a client keeps open
    #   client.close
    def close
      @connection.close
      self
    end

    # Perform a GET request to the Tesla Fleet API
    #
    # @api public
    # @param path [String] the request path
    # @param params [Hash] the query parameters
    # @param headers [Hash{String => String}] the headers to send with the request, which replace the ones the
    #   client would send, the 'Authorization' header of its access token among them
    # @return [String] the response body
    # @raise [HTTPError] if the response is not successful
    # @raise [ArgumentError] if the path is a URL of an origin other than the host
    # @example Get the vehicles of the account
    #   client.get("/api/1/vehicles")
    # @example Send a header of your own
    #   client.get("/api/1/vehicles", headers: {"Accept" => "application/json"})
    def get(path, params = {}, headers: {})
      execute_request(:get, path, params:, headers:)
    end

    # Perform a DELETE request to the Tesla Fleet API
    #
    # @api public
    # @param path [String] the request path
    # @param params [Hash] the query parameters
    # @param headers [Hash{String => String}] the headers to send with the request, which replace the ones the
    #   client would send, the 'Authorization' header of its access token among them
    # @return [String] the response body
    # @raise [HTTPError] if the response is not successful
    # @raise [ArgumentError] if the path is a URL of an origin other than the host
    # @example Remove a driver from a vehicle
    #   client.delete("/api/1/vehicles/5YJSA11111111111/drivers", {share_user_id: 800001})
    def delete(path, params = {}, headers: {})
      execute_request(:delete, path, params:, headers:)
    end

    # Perform a POST request to the Tesla Fleet API
    #
    # @api public
    # @param path [String] the request path
    # @param body [Hash, Array, String] the request body, which is sent as JSON unless it is a String
    # @param headers [Hash{String => String}] the headers to send with the request, which replace the ones the
    #   client would send, the 'Authorization' header of its access token among them
    # @return [String] the response body
    # @raise [HTTPError] if the response is not successful
    # @raise [ArgumentError] if the path is a URL of an origin other than the host
    # @example Lock the doors of a vehicle
    #   client.post("/api/1/vehicles/5YJSA11111111111/command/door_lock")
    def post(path, body = {}, headers: {})
      execute_request(:post, path, body:, headers:)
    end

    # Perform a PUT request to the Tesla Fleet API
    #
    # @api public
    # @param path [String] the request path
    # @param body [Hash, Array, String] the request body, which is sent as JSON unless it is a String
    # @param headers [Hash{String => String}] the headers to send with the request, which replace the ones the
    #   client would send, the 'Authorization' header of its access token among them
    # @return [String] the response body
    # @raise [HTTPError] if the response is not successful
    # @raise [ArgumentError] if the path is a URL of an origin other than the host
    # @example Replace the fleet telemetry configuration of a vehicle
    #   client.put("/api/1/vehicles/fleet_telemetry_config", {vins: ["5YJSA11111111111"], config: {}})
    def put(path, body = {}, headers: {})
      execute_request(:put, path, body:, headers:)
    end

    # Perform a PATCH request to the Tesla Fleet API
    #
    # @api public
    # @param path [String] the request path
    # @param body [Hash, Array, String] the request body, which is sent as JSON unless it is a String
    # @param headers [Hash{String => String}] the headers to send with the request, which replace the ones the
    #   client would send, the 'Authorization' header of its access token among them
    # @return [String] the response body
    # @raise [HTTPError] if the response is not successful
    # @raise [ArgumentError] if the path is a URL of an origin other than the host
    # @example Update a resource
    #   client.patch("/api/1/vehicles/5YJSA11111111111", {display_name: "Nikola 2.0"})
    def patch(path, body = {}, headers: {})
      execute_request(:patch, path, body:, headers:)
    end

    private

    # The connection used for API requests
    # @api private
    # @return [Connection] the connection
    attr_reader :connection

    # The request builder used for API requests
    # @api private
    # @return [RequestBuilder] the request builder
    attr_reader :request_builder

    # The redirect handler the responses of API requests are followed with
    # @api private
    # @return [RedirectHandler] the redirect handler
    attr_reader :redirect_handler

    # The retry handler the requests the server turns away are sent again with
    # @api private
    # @return [RetryHandler] the retry handler
    attr_reader :retry_handler

    # Execute an HTTP request to the Tesla Fleet API
    #
    # A request answered with a 401 Unauthorized is sent once more with a new access token when the client has what
    # refreshing one takes, since the Fleet API never acted on a request it did not authorize.
    #
    # @api private
    # @param http_method [Symbol] the HTTP method
    # @param path [String] the request path
    # @param params [Hash] the query parameters
    # @param body [Hash, Array, String, nil] the request body
    # @param headers [Hash{String => String}] the headers to send with the request
    # @return [String] the response body
    def execute_request(http_method, path, headers:, params: {}, body: nil)
      uri = build_uri(host, path)
      attempt = ->(access_token) { perform(access_token:, http_method:, uri:, params:, body:, headers:) }
      access_token = renewed_access_token(nil)
      response = attempt.call(access_token)
      if response.code.eql?(UNAUTHORIZED_STATUS) && refreshable?
        response = attempt.call(renewed_access_token(access_token))
      end
      @response_parser.parse(response:)
    end

    # Build a request, send it, and follow its redirects, again when it is turned away
    #
    # Each attempt builds a request of its own, so the retry handler is told whether the request is safe to send
    # again rather than given one to read the method of. Only a safe request, which asks the server for something
    # rather than asking a vehicle to do something, is sent again after a 502, 503, or 504, or after the network
    # lost it, since the vehicle may have acted on it before the answer went missing. Any request is sent again for
    # a 429, which a rate limiter answers before the request reaches the endpoint.
    #
    # A retry follows the redirects of the request again from the start, rather than sending it straight to where a
    # redirect led the first time.
    #
    # @api private
    # @param access_token [String, nil] the access token the request is authorized with
    # @param http_method [Symbol] the HTTP method
    # @param uri [URI::Generic] the request URI
    # @param params [Hash] the query parameters
    # @param body [Hash, Array, String, nil] the request body
    # @param headers [Hash{String => String}] the headers to send with the request
    # @return [Net::HTTPResponse] the response
    def perform(access_token:, http_method:, uri:, params:, body:, headers:)
      authenticator = authenticator_for(access_token)
      @retry_handler.handle(retry_unanswered: safe?(http_method)) do
        request = @request_builder.build(http_method:, uri:, params:, body:, headers:, authenticator:)
        response = @connection.perform(request:)
        @redirect_handler.handle(response:, request:, authenticator:, body:, headers:)
      end
    end
  end
end
