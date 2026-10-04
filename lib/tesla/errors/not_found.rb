# frozen_string_literal: true

require_relative "client_error"

module Tesla
  # Error raised for HTTP 404 Not Found responses
  # @api public
  class NotFound < ClientError; end
end
