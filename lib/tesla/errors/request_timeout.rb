# frozen_string_literal: true

require_relative "client_error"

module Tesla
  # Error raised for HTTP 408 Request Timeout responses
  #
  # The Fleet API answers with it when the vehicle is asleep or offline, so it is the error of a command or a data
  # request sent to a vehicle that has not been woken (see {API::VehicleEndpoints#wake_up}).
  #
  # @api public
  class RequestTimeout < ClientError; end
end
