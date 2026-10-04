# frozen_string_literal: true

require_relative "client_error"

module Tesla
  # Error raised for HTTP 402 Payment Required responses
  #
  # The Fleet API answers with it when the account of the application has a bill to pay before it is served again.
  #
  # @api public
  class PaymentRequired < ClientError; end
end
