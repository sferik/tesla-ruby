# frozen_string_literal: true

require_relative "client_error"

module Tesla
  # Error raised for HTTP 405 Method Not Allowed responses
  # @api public
  class MethodNotAllowed < ClientError; end
end
