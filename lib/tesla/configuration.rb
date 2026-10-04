# frozen_string_literal: true

require_relative "certificate_options"
require_relative "connection"
require_relative "redirect_handler"
require_relative "request_builder"
require_relative "retry_handler"
require_relative "settings"
require_relative "url_validation"

module Tesla
  # Global configuration for {Tesla::Client} instances
  # @api public
  module Configuration
    include CertificateOptions
    include Settings
    include URLValidation

    # The host of the Fleet API for North America and Asia-Pacific, other than China
    NORTH_AMERICA_HOST = "https://fleet-api.prd.na.vn.cloud.tesla.com"

    # The host of the Fleet API for Europe, the Middle East, and Africa
    EUROPE_HOST = "https://fleet-api.prd.eu.vn.cloud.tesla.com"

    # The host of the Fleet API for China
    CHINA_HOST = "https://fleet-api.prd.cn.vn.cloud.tesla.cn"

    # The API endpoint used when the TESLA_HOST environment variable is not set
    DEFAULT_HOST = NORTH_AMERICA_HOST

    # The URL a user is sent to in order to authorize the application
    DEFAULT_AUTHORIZATION_ENDPOINT = "https://auth.tesla.com/oauth2/v3/authorize"

    # The URL tokens are issued and refreshed at
    DEFAULT_TOKEN_ENDPOINT = "https://fleet-auth.prd.vn.cloud.tesla.com/oauth2/v3/token"

    # The default 'User-Agent' HTTP header
    DEFAULT_USER_AGENT = RequestBuilder::DEFAULT_USER_AGENT

    # The credentials that fall back to an environment variable until they are assigned
    ENVIRONMENT = {
      access_token: "TESLA_ACCESS_TOKEN",
      refresh_token: "TESLA_REFRESH_TOKEN",
      client_id: "TESLA_CLIENT_ID",
      client_secret: "TESLA_CLIENT_SECRET",
      redirect_uri: "TESLA_REDIRECT_URI"
    }.freeze
    private_constant :ENVIRONMENT

    # The host used for API requests
    #
    # This is the host of the Fleet API for the region of the account (see {API::UserEndpoints#region}), or the
    # host the vehicle command proxy listens at, which signs the commands of the vehicles that take only signed
    # ones and hands every other request on to the Fleet API.
    #
    # @api public
    # @return [String] the host, including scheme
    # @example Get the host
    #   Tesla.host
    attr_reader :host

    # Set the host used for API requests
    #
    # The host is checked here rather than when a request is made with it, as {Client#host=} checks the host of a
    # client, so that the error names the assignment that was wrong.
    #
    # @api public
    # @param host [String] the host, including scheme
    # @return [void]
    # @raise [ArgumentError] if the host is not an HTTP or HTTPS URL, in which case the host is left as it was
    # @example Send requests to the Fleet API for Europe
    #   Tesla.host = Tesla::Configuration::EUROPE_HOST
    # @example Send requests through the vehicle command proxy
    #   Tesla.host = "https://localhost:4443"
    def host=(host)
      @host = validate_host(host)
    end

    # The audience tokens are issued for
    #
    # The token endpoint issues a token for the host of the Fleet API it is used with, which is the host of the
    # client unless that is the vehicle command proxy, in which case the host of the Fleet API for the region of the
    # account is assigned here.
    #
    # @api public
    # @return [String, nil] the host of the Fleet API the tokens are used with, or nil for the host of the client
    # @example Issue tokens for the Fleet API for Europe while requests are sent through a proxy
    #   Tesla.audience = Tesla::Configuration::EUROPE_HOST
    attr_accessor :audience

    # The URL a user is sent to in order to authorize the application
    # @api public
    # @return [String] the authorization endpoint
    # @example Get or set the authorization endpoint
    #   Tesla.authorization_endpoint = "https://auth.tesla.cn/oauth2/v3/authorize"
    attr_accessor :authorization_endpoint

    # The URL tokens are issued and refreshed at
    # @api public
    # @return [String] the token endpoint
    # @example Get or set the token endpoint
    #   Tesla.token_endpoint = "https://auth.tesla.cn/oauth2/v3/token"
    attr_accessor :token_endpoint

    # @!method access_token
    #   The access token requests are authorized with
    #
    #   Falls back to the TESLA_ACCESS_TOKEN environment variable until one is assigned.
    #
    #   @api public
    #   @return [String, nil] the access token
    #   @example Get the access token
    #     Tesla.access_token
    # @!method access_token=(access_token)
    #   Set the access token requests are authorized with
    #   @api public
    #   @param access_token [String, nil] the access token
    #   @return [void]
    #   @example Set the access token
    #     Tesla.access_token = "eyJhbGciOiJSUzI1NiIs"
    environment_setting :access_token, ENVIRONMENT.fetch(:access_token)

    # @!method refresh_token
    #   The refresh token a new access token is asked for with
    #
    #   Falls back to the TESLA_REFRESH_TOKEN environment variable until one is assigned.
    #
    #   @api public
    #   @return [String, nil] the refresh token
    #   @example Get the refresh token
    #     Tesla.refresh_token
    # @!method refresh_token=(refresh_token)
    #   Set the refresh token a new access token is asked for with
    #   @api public
    #   @param refresh_token [String, nil] the refresh token
    #   @return [void]
    #   @example Set the refresh token
    #     Tesla.refresh_token = "NA_9d0b4bfd0c4c3a6e"
    environment_setting :refresh_token, ENVIRONMENT.fetch(:refresh_token)

    # @!method client_id
    #   The client ID of the application, as developer.tesla.com issued it
    #
    #   Falls back to the TESLA_CLIENT_ID environment variable until one is assigned.
    #
    #   @api public
    #   @return [String, nil] the client ID
    #   @example Get the client ID
    #     Tesla.client_id
    # @!method client_id=(client_id)
    #   Set the client ID of the application
    #   @api public
    #   @param client_id [String, nil] the client ID
    #   @return [void]
    #   @example Set the client ID
    #     Tesla.client_id = "81527cff06843c8634fdc09e8ac0abef"
    environment_setting :client_id, ENVIRONMENT.fetch(:client_id)

    # @!method client_secret
    #   The client secret of the application, as developer.tesla.com issued it
    #
    #   Falls back to the TESLA_CLIENT_SECRET environment variable until one is assigned.
    #
    #   @api public
    #   @return [String, nil] the client secret
    #   @example Get the client secret
    #     Tesla.client_secret
    # @!method client_secret=(client_secret)
    #   Set the client secret of the application
    #   @api public
    #   @param client_secret [String, nil] the client secret
    #   @return [void]
    #   @example Set the client secret
    #     Tesla.client_secret = "ta-secret.7vx6VkVvk2gBgSrN"
    environment_setting :client_secret, ENVIRONMENT.fetch(:client_secret)

    # @!method redirect_uri
    #   The URL the authorization server sends a user back to
    #
    #   It is one of the redirect URIs registered for the application at developer.tesla.com.
    #
    #   Falls back to the TESLA_REDIRECT_URI environment variable until one is assigned.
    #
    #   @api public
    #   @return [String, nil] the redirect URI
    #   @example Get the redirect URI
    #     Tesla.redirect_uri
    # @!method redirect_uri=(redirect_uri)
    #   Set the URL the authorization server sends a user back to
    #   @api public
    #   @param redirect_uri [String, nil] the redirect URI
    #   @return [void]
    #   @example Set the redirect URI
    #     Tesla.redirect_uri = "https://example.com/auth/callback"
    environment_setting :redirect_uri, ENVIRONMENT.fetch(:redirect_uri)

    # What is called with the token each time the access token is refreshed
    #
    # A refresh token of the Fleet API is used once: refreshing the access token answers with another refresh
    # token, which is the one the next refresh needs. Whatever stores the tokens is told of the new ones here.
    #
    # @api public
    # @return [#call, nil] what is called with the `SimpleOAuth::OAuth2::Token`, or nil to call nothing
    # @example Store the tokens each time they are refreshed
    #   Tesla.on_token_refresh = ->(token) { File.write("refresh_token", token.refresh_token) }
    attr_accessor :on_token_refresh

    # The 'User-Agent' HTTP header sent with requests
    # @api public
    # @return [String] the user agent
    # @example Get or set the user agent
    #   Tesla.user_agent = "Custom User Agent"
    attr_accessor :user_agent

    # @!method open_timeout
    #   The timeout for opening connections in seconds
    #   @api public
    #   @return [Numeric] the timeout for opening connections in seconds
    #   @example Get the open timeout
    #     Tesla.open_timeout
    # @!method open_timeout=(open_timeout)
    #   Set the timeout for opening connections in seconds
    #   @api public
    #   @param open_timeout [Numeric] the timeout for opening connections in seconds
    #   @return [void]
    #   @raise [ArgumentError] if it is not a number of seconds, in which case the timeout is left as it was
    #   @example Set the open timeout
    #     Tesla.open_timeout = 30
    seconds_setting :open_timeout

    # @!method read_timeout
    #   The timeout for reading responses in seconds
    #   @api public
    #   @return [Numeric] the timeout for reading responses in seconds
    #   @example Get the read timeout
    #     Tesla.read_timeout
    # @!method read_timeout=(read_timeout)
    #   Set the timeout for reading responses in seconds
    #   @api public
    #   @param read_timeout [Numeric] the timeout for reading responses in seconds
    #   @return [void]
    #   @raise [ArgumentError] if it is not a number of seconds, in which case the timeout is left as it was
    #   @example Set the read timeout
    #     Tesla.read_timeout = 30
    seconds_setting :read_timeout

    # @!method write_timeout
    #   The timeout for writing requests in seconds
    #   @api public
    #   @return [Numeric] the timeout for writing requests in seconds
    #   @example Get the write timeout
    #     Tesla.write_timeout
    # @!method write_timeout=(write_timeout)
    #   Set the timeout for writing requests in seconds
    #   @api public
    #   @param write_timeout [Numeric] the timeout for writing requests in seconds
    #   @return [void]
    #   @raise [ArgumentError] if it is not a number of seconds, in which case the timeout is left as it was
    #   @example Set the write timeout
    #     Tesla.write_timeout = 30
    seconds_setting :write_timeout

    # @!method keep_alive_timeout
    #   The seconds an idle connection is kept open for another request
    #
    #   Zero closes every connection when its request is done.
    #
    #   @api public
    #   @return [Numeric] the seconds an idle connection is kept open
    #   @example Get the keep-alive timeout
    #     Tesla.keep_alive_timeout
    # @!method keep_alive_timeout=(keep_alive_timeout)
    #   Set the seconds an idle connection is kept open for another request
    #   @api public
    #   @param keep_alive_timeout [Numeric] the seconds an idle connection is kept open
    #   @return [void]
    #   @raise [ArgumentError] if it is not a number of seconds, in which case the timeout is left as it was
    #   @example Set the keep-alive timeout
    #     Tesla.keep_alive_timeout = 0
    seconds_setting :keep_alive_timeout

    # The IO object for debug output
    #
    # The access token, the tokens and the client secret of a request to the token endpoint, and the PIN of a
    # command are redacted from what is written to it.
    #
    # @api public
    # @return [IO, nil] the IO object for debug output
    # @example Get or set the debug output
    #   Tesla.debug_output = $stderr
    attr_accessor :debug_output

    # The proxy URL for requests
    #
    # When nil, proxies are read from the http_proxy, https_proxy, and no_proxy environment variables.
    #
    # @api public
    # @return [String, nil] the proxy URL for requests
    # @example Get the proxy URL
    #   Tesla.proxy_url
    attr_reader :proxy_url

    # Set the proxy URL for requests
    #
    # The proxy URL is checked here rather than when a request is made with it, as {Connection#proxy_url=} checks
    # the proxy URL of a connection, so that the error names the assignment that was wrong.
    #
    # @api public
    # @param proxy_url [String, nil] the proxy URL, or nil to read proxies from the environment
    # @return [void]
    # @raise [ArgumentError] if the proxy URL is invalid, in which case the proxy is left as it was; the message
    #   leaves out its user and password
    # @example Set the proxy URL
    #   Tesla.proxy_url = "http://proxy.example.com:8080"
    def proxy_url=(proxy_url)
      parse_proxy_uri(proxy_url) unless proxy_url.nil?
      @proxy_url = proxy_url
    end

    # @!method max_redirects
    #   The maximum number of redirects to follow
    #
    #   A redirect to another host is followed without the access token, and one that would send the body of a
    #   request to another host is not followed at all.
    #
    #   @api public
    #   @return [Integer] the maximum number of redirects to follow
    #   @example Get the maximum redirects
    #     Tesla.max_redirects
    # @!method max_redirects=(max_redirects)
    #   Set the maximum number of redirects to follow
    #   @api public
    #   @param max_redirects [Integer] the maximum number of redirects to follow
    #   @return [void]
    #   @raise [ArgumentError] if it is not a whole number of times, in which case the maximum is left as it was
    #   @example Set the maximum redirects
    #     Tesla.max_redirects = 5
    count_setting :max_redirects

    # @!method max_retries
    #   The number of times a request that was turned away is sent again
    #
    #   A request answered with a 429 Too Many Requests is sent again, and one that only asks for something is sent
    #   again for a 502, 503, or 504 and when the network loses it. A command is not, since the vehicle may have
    #   carried it out. Zero turns retrying off.
    #
    #   @api public
    #   @return [Integer] the number of times a request is sent again
    #   @example Get the maximum retries
    #     Tesla.max_retries
    # @!method max_retries=(max_retries)
    #   Set the number of times a request that was turned away is sent again
    #   @api public
    #   @param max_retries [Integer] the number of times a request is sent again
    #   @return [void]
    #   @raise [ArgumentError] if it is not a whole number of times, in which case the maximum is left as it was
    #   @example Turn retrying off
    #     Tesla.max_retries = 0
    count_setting :max_retries

    # @!method max_retry_delay
    #   The longest a request waits before it is sent again, in seconds
    #
    #   A response that asks to wait longer raises rather than pausing the caller's thread for that long.
    #
    #   @api public
    #   @return [Numeric] the longest a request waits before it is sent again, in seconds
    #   @example Get the maximum retry delay
    #     Tesla.max_retry_delay
    # @!method max_retry_delay=(max_retry_delay)
    #   Set the longest a request waits before it is sent again, in seconds
    #   @api public
    #   @param max_retry_delay [Numeric] the longest a request waits before it is sent again, in seconds
    #   @return [void]
    #   @raise [ArgumentError] if it is not a number of seconds, in which case the maximum is left as it was
    #   @example Set the maximum retry delay
    #     Tesla.max_retry_delay = 30
    seconds_setting :max_retry_delay

    # @!method ca_file
    #   The path of a file of certificates TLS is verified with
    #
    #   The certificates in the file are trusted alongside the ones OpenSSL already trusts, which is how the
    #   certificate the vehicle command proxy was started with is trusted.
    #
    #   @api public
    #   @return [String, nil] the path of the file, or nil to verify with the certificates OpenSSL trusts
    #   @example Get the CA file
    #     Tesla.ca_file
    # @!method ca_file=(ca_file)
    #   Set the path of a file of certificates TLS is verified with
    #   @api public
    #   @param ca_file [String, nil] the path of the file, or nil to verify with the certificates OpenSSL trusts
    #   @return [void]
    #   @raise [ArgumentError] if the path does not name a file, in which case the path is left as it was
    #   @example Trust the certificate of the vehicle command proxy
    #     Tesla.ca_file = "config/tls-cert.pem"

    # Set the default configuration when the module is extended
    #
    # @api private
    # @param base [Module] the module extending Configuration
    # @return [void]
    def self.extended(base)
      base.reset
    end

    # The host used when none has been assigned
    #
    # @api public
    # @return [String] the TESLA_HOST environment variable, or the host of the Fleet API for North America
    # @example Get the default host
    #   Tesla.default_host
    def default_host
      ENV.fetch("TESLA_HOST", DEFAULT_HOST)
    end

    # Convenience method to allow configuration options to be set in a block
    #
    # @api public
    # @yield [self] the configuration
    # @return [self]
    # @example Configure the credentials of the application
    #   Tesla.configure do |config|
    #     config.client_id = "81527cff06843c8634fdc09e8ac0abef"
    #     config.client_secret = "ta-secret.7vx6VkVvk2gBgSrN"
    #   end
    def configure
      yield self
      self
    end

    # Reset all configuration options to defaults
    #
    # The default host is taken as it is rather than checked the way a host assigned to {#host=} is, so that a
    # `TESLA_HOST` that is not a URL is reported when a client is built with it rather than when the library is
    # required.
    #
    # @api public
    # @return [self]
    # @example Reset the configuration
    #   Tesla.reset
    def reset
      @host = default_host
      self.user_agent = DEFAULT_USER_AGENT
      reset_credentials
      reset_connection
      self
    end

    private

    # Clear all credentials, so that each falls back to the environment again
    # @api private
    # @return [void]
    def reset_credentials
      ENVIRONMENT.each_key do |setting|
        variable = :"@#{setting}"
        remove_instance_variable(variable) if instance_variable_defined?(variable)
      end
      self.audience = nil
      self.authorization_endpoint = DEFAULT_AUTHORIZATION_ENDPOINT
      self.token_endpoint = DEFAULT_TOKEN_ENDPOINT
      self.on_token_refresh = nil
    end

    # Reset the connection, redirect, and retry options to their defaults
    # @api private
    # @return [void]
    def reset_connection
      self.open_timeout = Connection::DEFAULT_OPEN_TIMEOUT
      self.read_timeout = Connection::DEFAULT_READ_TIMEOUT
      self.write_timeout = Connection::DEFAULT_WRITE_TIMEOUT
      self.keep_alive_timeout = Connection::DEFAULT_KEEP_ALIVE_TIMEOUT
      self.debug_output = nil
      self.proxy_url = nil
      self.ca_file = nil
      self.max_redirects = RedirectHandler::DEFAULT_MAX_REDIRECTS
      self.max_retries = RetryHandler::DEFAULT_MAX_RETRIES
      self.max_retry_delay = RetryHandler::DEFAULT_MAX_RETRY_DELAY
    end
  end
end
