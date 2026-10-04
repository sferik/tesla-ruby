# frozen_string_literal: true

require_relative "server_error"

module Tesla
  # Error raised for HTTP 540 responses, which the Fleet API answers with when the vehicle answered with an error
  #
  # The vehicle may need to be restarted, updated, or serviced.
  #
  # @api public
  class DeviceUnexpectedResponse < ServerError; end
end
