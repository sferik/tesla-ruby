# frozen_string_literal: true

require_relative "client_error"

module Tesla
  # Error raised for HTTP 421 Misdirected Request responses
  #
  # The Fleet API answers with it when the account belongs to another region than the host of the request serves
  # (see {API::UserEndpoints#region}).
  #
  # @api public
  class MisdirectedRequest < ClientError; end
end
