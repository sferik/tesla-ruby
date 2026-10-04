# frozen_string_literal: true

require_relative "client_error"

module Tesla
  # Error raised for HTTP 406 Not Acceptable responses
  # @api public
  class NotAcceptable < ClientError; end
end
