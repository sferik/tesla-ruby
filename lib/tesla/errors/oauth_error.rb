# frozen_string_literal: true

require_relative "error"

module Tesla
  # Error raised when the token endpoint of Tesla's authorization server turns a request away, or answers with a
  # response no token can be read from
  #
  # The error of the simple_oauth gem, which reads the response, is its `cause`.
  #
  # @api public
  class OAuthError < Error
    # The error code the token endpoint answered with
    # @api public
    # @return [String, nil] the error code, such as "invalid_grant", or nil when the response carried none
    # @example Get the error code
    #   error.code # => "invalid_grant"
    attr_reader :code

    # The description the token endpoint answered with
    # @api public
    # @return [String, nil] the description, or nil when the response carried none
    # @example Get the description
    #   error.description # => "The refresh token is expired."
    attr_reader :description

    # The HTTP status the token endpoint answered with
    # @api public
    # @return [Integer, nil] the HTTP status
    # @example Get the status
    #   error.status # => 401
    attr_reader :status

    # Initialize a new OAuthError
    #
    # The message is the error code and the description, or names the status when the response carried neither.
    #
    # @api public
    # @param code [String, nil] the error code the token endpoint answered with
    # @param description [String, nil] the description the token endpoint answered with
    # @param status [Integer, nil] the HTTP status the token endpoint answered with
    # @return [OAuthError] a new instance
    # @example Create an OAuth error
    #   Tesla::OAuthError.new(code: "invalid_grant", description: "The refresh token is expired.", status: 401)
    def initialize(code: nil, description: nil, status: nil)
      @code = code
      @description = description
      @status = status
      details = [code, description].compact
      super(details.empty? ? "The token endpoint answered with status #{status}" : details.join(": "))
    end
  end
end
