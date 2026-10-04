# frozen_string_literal: true

require_relative "client_error"

module Tesla
  # Error raised for HTTP 401 Unauthorized responses
  # @api public
  class Unauthorized < ClientError; end
end
