# frozen_string_literal: true

module Tesla
  # Base class for authentication (no authentication)
  # @api private
  class Authenticator
    # The HTTP header name for authentication
    AUTHENTICATION_HEADER = "Authorization"
    private_constant :AUTHENTICATION_HEADER

    # Generate the authentication headers for a request
    #
    # @api private
    # @param _request [Net::HTTPRequest] the HTTP request
    # @return [Hash{String => String}] the authentication headers (empty)
    # @example Generate empty authentication headers
    #   authenticator = Tesla::Authenticator.new
    #   authenticator.header(request)
    def header(_request)
      {}
    end

    # Summarize the authenticator for the console
    #
    # @api private
    # @return [String] the summary, which never includes credentials
    # @example Inspect an authenticator
    #   authenticator.inspect # => #<Tesla::Authenticator>
    def inspect
      "#<#{self.class}>"
    end
  end
end
