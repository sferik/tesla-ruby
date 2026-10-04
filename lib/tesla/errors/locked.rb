# frozen_string_literal: true

require_relative "client_error"

module Tesla
  # Error raised for HTTP 423 Locked responses
  #
  # The Fleet API answers with it when Tesla has locked the account.
  #
  # @api public
  class Locked < ClientError; end
end
