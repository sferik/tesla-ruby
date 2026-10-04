# frozen_string_literal: true

module Tesla
  # Tells whether a request can be sent again, mixed into the client and the connection pool
  #
  # A safe request only asks the server for something, so sending it again leaves the vehicle as it was and is
  # answered as the first one would have been. A request that asks a vehicle to do something, such as honking the
  # horn or opening the trunk, is not safe: it cannot be sent a second time to find out whether the vehicle acted on
  # the first one, so it is not sent again once it may have arrived (see {RetryHandler}).
  #
  # @api private
  module Idempotence
    # The HTTP methods that ask the server for something rather than asking it to do something
    SAFE_METHODS = %w[GET HEAD OPTIONS TRACE].freeze

    private

    # Whether a request made with an HTTP method only asks the server for something
    #
    # The method is named rather than the request, so that a caller deciding whether to send a request again does
    # not have to have built one (see {Client#execute_request}).
    #
    # @api private
    # @param http_method [String, Symbol] the HTTP method, in either case
    # @return [Boolean] whether a request made with the method is safe
    def safe?(http_method)
      SAFE_METHODS.include?(http_method.to_s.upcase)
    end
  end
end
