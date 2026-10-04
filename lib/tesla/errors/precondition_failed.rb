# frozen_string_literal: true

require_relative "client_error"

module Tesla
  # Error raised for HTTP 412 Precondition Failed responses
  #
  # The Fleet API answers with it when the application has not been registered in the region of the request (see
  # {API::PartnerEndpoints#register_partner}).
  #
  # @api public
  class PreconditionFailed < ClientError; end
end
