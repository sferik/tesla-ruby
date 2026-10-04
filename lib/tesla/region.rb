# frozen_string_literal: true

require_relative "resource"

module Tesla
  # The region of the Fleet API an account is served by
  # @api public
  class Region < Resource
    inspect_with :region

    # @!method region
    #   The name of the region, such as "na" or "eu"
    #   @api public
    #   @return [String, nil] the name of the region
    #   @example
    #     region.region
    attribute :region

    # @!method fleet_api_base_url
    #   The host the Fleet API serves the account at, which is the `host` to configure
    #   @api public
    #   @return [String, nil] the host the Fleet API serves the account at
    #   @example
    #     region.fleet_api_base_url
    attribute :fleet_api_base_url
  end
end
