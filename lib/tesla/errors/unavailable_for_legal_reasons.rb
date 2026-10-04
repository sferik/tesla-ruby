# frozen_string_literal: true

require_relative "client_error"

module Tesla
  # Error raised for HTTP 451 Unavailable For Legal Reasons responses
  #
  # The Fleet API answers with it when a privacy setting of the vehicle or the account withholds what was asked for.
  #
  # @api public
  class UnavailableForLegalReasons < ClientError; end
end
