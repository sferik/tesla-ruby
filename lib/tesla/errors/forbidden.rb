# frozen_string_literal: true

require_relative "client_error"

module Tesla
  # Error raised for HTTP 403 Forbidden responses
  #
  # The Fleet API answers with it when the access token lacks the scope an endpoint requires, and when a command is
  # sent to a vehicle that takes commands only over the Tesla Vehicle Command Protocol, which signs them: such a
  # vehicle is commanded through the vehicle command proxy, which the client is pointed at with `host`.
  #
  # @api public
  class Forbidden < ClientError; end
end
