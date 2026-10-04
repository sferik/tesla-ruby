# frozen_string_literal: true

require_relative "client_error"

module Tesla
  # Error raised for HTTP 400 Bad Request responses
  # @api public
  class BadRequest < ClientError; end
end
