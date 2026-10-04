# frozen_string_literal: true

require_relative "vehicle"

module Tesla
  # Resolves identifiers from resource objects, so API methods accept either
  #
  # @api private
  module Identifiers
    private

    # Resolve the tag the Fleet API knows a vehicle by from a tag or a vehicle
    #
    # A vehicle is known by its VIN or by its ID. The VIN is preferred for a vehicle that carries both, since the
    # vehicle command proxy knows a vehicle only by its VIN.
    #
    # @api private
    # @param vehicle [String, Integer, Vehicle] a VIN, the ID of a vehicle, or a vehicle
    # @return [String, Integer, nil] the VIN or the ID
    def tag_of(vehicle)
      case vehicle
      when Vehicle then vehicle.vin || vehicle.id
      else vehicle
      end
    end
  end
end
