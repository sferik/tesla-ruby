# frozen_string_literal: true

require_relative "http_error"

module Tesla
  # Base class for client errors (4xx HTTP status codes)
  # @api public
  class ClientError < HTTPError; end
end
