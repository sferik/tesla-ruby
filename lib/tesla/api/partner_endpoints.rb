# frozen_string_literal: true

require_relative "../json_parsing"

module Tesla
  module API
    # The partner endpoints, which act for the application rather than for a user
    #
    # They are authorized with a partner token, which each asks the token endpoint for with the client ID and the
    # client secret of the client (see {OAuthEndpoints#partner_token}).
    #
    # @api public
    module PartnerEndpoints
      include JSONParsing

      # Register the application in the region of the host
      #
      # An application is registered once in each region it is used in, before which the Fleet API of that region
      # answers its requests with a {PreconditionFailed}. The domain is the one the application was created with
      # at developer.tesla.com, and has to serve the public key of the application at
      # `/.well-known/appspecific/com.tesla.3p.public-key.pem`.
      #
      # @api public
      # @authenticated true
      # @param domain [String] The domain of the application, without a scheme.
      # @return [Hash{String => Object}] the account the application is registered as
      # @raise [OAuthError] if the token endpoint turns the request for a partner token away
      # @example
      #   Tesla.register_partner "example.com"
      def register_partner(domain)
        parse_response(post("/api/1/partner_accounts", {domain:}, headers: partner_headers))
      end

      # View the public key the application is registered with in the region of the host
      #
      # @api public
      # @authenticated true
      # @param domain [String] The domain of the application, without a scheme.
      # @return [String] the public key, as a hexadecimal string
      # @raise [OAuthError] if the token endpoint turns the request for a partner token away
      # @raise [InvalidResponse] if the response carries no public key
      # @example
      #   Tesla.partner_public_key "example.com"
      def partner_public_key(domain)
        body = get("/api/1/partner_accounts/public_key", {domain:}, headers: partner_headers)
        parse_response(body) { |response| response.fetch("public_key") }
      end

      private

      # The headers that authorize a request with a partner token
      #
      # They replace the header that carries the access token of the client.
      #
      # @api private
      # @return [Hash{String => String}] the headers
      def partner_headers
        {"Authorization" => "Bearer #{partner_token.access_token}"}
      end
    end
  end
end
