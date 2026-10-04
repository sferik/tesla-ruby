# frozen_string_literal: true

require_relative "../json_parsing"
require_relative "../region"
require_relative "../user"

module Tesla
  module API
    # The user endpoints, which describe the account an access token was issued for
    # @api public
    module UserEndpoints
      include JSONParsing

      # View the user the access token was issued for
      #
      # @api public
      # @authenticated true
      # @return [User]
      # @example
      #   Tesla.me.email
      def me
        User.new(parse_response(get("/api/1/users/me")))
      end

      # View the region of the Fleet API the account is served by
      #
      # A request sent to the host of another region is answered with a {MisdirectedRequest}, so this is the
      # endpoint that names the host to configure.
      #
      # @api public
      # @authenticated true
      # @return [Region]
      # @example
      #   Tesla.host = Tesla.region.fleet_api_base_url
      def region
        Region.new(parse_response(get("/api/1/users/region")))
      end
    end
  end
end
