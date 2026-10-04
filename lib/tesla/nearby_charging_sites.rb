# frozen_string_literal: true

require_relative "charging_site"
require_relative "resource"

module Tesla
  # The charging sites near a vehicle
  # @api public
  class NearbyChargingSites < Resource
    # @!method superchargers
    #   The Superchargers near the vehicle, nearest first
    #   @api public
    #   @return [Array<ChargingSite>] the Superchargers
    #   @example
    #     nearby_charging_sites.superchargers.first.available_stalls
    resource_list_attribute :superchargers, ChargingSite

    # @!method destination_charging
    #   The destination chargers near the vehicle, nearest first
    #   @api public
    #   @return [Array<ChargingSite>] the destination chargers
    #   @example
    #     nearby_charging_sites.destination_charging.first.name
    resource_list_attribute :destination_charging, ChargingSite

    # @!method timestamp
    #   The time the vehicle reported the sites
    #   @api public
    #   @return [Time, nil] the time the vehicle reported the sites
    #   @raise [InvalidResponse] if the timestamp is not a number of milliseconds
    #   @example
    #     nearby_charging_sites.timestamp
    time_attribute :timestamp
  end
end
