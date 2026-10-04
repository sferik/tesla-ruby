# frozen_string_literal: true

require "json"
require_relative "errors/invalid_response"

module Tesla
  # Parses the JSON bodies of API responses, mixed into the API endpoints
  # @api private
  module JSONParsing
    private

    # Errors raised when the parsed JSON is not the expected shape: a key that is fetched is missing, or a value is
    # not of the expected type
    SHAPE_ERRORS = [KeyError, NoMethodError, TypeError].freeze
    private_constant :SHAPE_ERRORS

    # Parse a JSON response body, and read what the Fleet API answered with from it
    #
    # The Fleet API answers with a JSON object that carries what was asked for as its `response`, which is what is
    # read from the body. The block reads the fields the caller needs from that, and an error it raises because the
    # JSON is not the expected shape is reported as an invalid response with the body, rather than as a KeyError, a
    # NoMethodError, or a TypeError, as a body without a `response` is.
    #
    # @api private
    # @param body [String] the response body
    # @yield [response] the `response` of the parsed JSON, to read the fields the caller needs
    # @return [Object] the `response` of the parsed JSON, or what the block returns
    # @raise [InvalidResponse] if the body is not JSON, or the JSON is not the expected shape
    def parse_response(body)
      response = JSON.parse(body).fetch("response")
      block_given? ? yield(response) : response
    rescue JSON::ParserError
      raise InvalidResponse.new(body:)
    rescue *SHAPE_ERRORS => e
      raise InvalidResponse.new(body:, message: "The response body is not the expected JSON: #{e}")
    end
  end
end
