# frozen_string_literal: true

require "json"
require "net/http"
require_relative "../retry_after"
require_relative "error"

module Tesla
  # Base class for HTTP errors from the Tesla Fleet API
  # @api public
  class HTTPError < Error
    include RetryAfter

    # The HTTP response
    # @api public
    # @return [Net::HTTPResponse] the HTTP response
    # @example Get the response
    #   error.response
    attr_reader :response

    # The HTTP status code
    # @api public
    # @return [Integer] the HTTP status code
    # @example Get the status code
    #   error.code
    attr_reader :code

    # Initialize a new HTTPError
    #
    # The message is the error the Fleet API describes in the JSON of the response body, which is its `error` and
    # its `error_description`. A body that describes no error is the message as it is, and the status message
    # stands in for a body that is empty or an HTML page, such as the error page of a CDN.
    #
    # @api public
    # @param response [Net::HTTPResponse] the HTTP response
    # @return [HTTPError] a new instance
    # @example Create an HTTP error
    #   error = Tesla::HTTPError.new(response: response)
    def initialize(response:)
      super(error_message(response))
      @response = response
      @code = Integer(response.code)
    end

    # The seconds to wait before retrying the request
    #
    # The Fleet API sends a Retry-After header with a 429 Too Many Requests response, as a number of seconds or an
    # HTTP date.
    #
    # @api public
    # @return [Integer, nil] the seconds to wait, rounded up and never negative, or nil when the response has no
    #   Retry-After header or one that is neither a number of seconds nor an HTTP date
    # @example Wait before retrying
    #   sleep(error.retry_after || 1)
    def retry_after
      retry_after_of(response)
    end

    private

    # Get the error message from the response
    # @api private
    # @param response [Net::HTTPResponse] the HTTP response
    # @return [String] the error the body describes, else the body, else the status message if the body is empty or
    #   an HTML page
    def error_message(response)
      body = response.body.to_s
      return response.message if body.empty? || response.content_type&.casecmp?("text/html")

      described_error(body) || body
    end

    # The error a JSON response body describes
    #
    # The Fleet API answers an error with a short identifier as the `error` of a JSON object, and sometimes more
    # about it as the `error_description`.
    #
    # @api private
    # @param body [String] the response body
    # @return [String, nil] the error and its description, or nil when the body is not JSON or describes no error
    def described_error(body)
      error = Hash.try_convert(JSON.parse(body)) || {}
      details = error.values_at("error", "error_description").map(&:to_s).reject(&:empty?)
      details.join(": ") unless details.empty?
    rescue JSON::ParserError
      nil
    end
  end
end
