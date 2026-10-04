# frozen_string_literal: true

require_relative "resource"

module Tesla
  # The position and the driving state of a vehicle
  # @api public
  class DriveState < Resource
    inspect_with :latitude, :longitude, :shift_state

    # @!method latitude
    #   The latitude of the vehicle
    #
    #   The Fleet API answers with it when it is asked for "location_data", for a token with the vehicle_location scope.
    #
    #   @api public
    #   @return [Float, nil] the latitude of the vehicle
    #   @example
    #     drive_state.latitude
    attribute :latitude

    # @!method longitude
    #   The longitude of the vehicle
    #
    #   The Fleet API answers with it when it is asked for "location_data", for a token with the vehicle_location scope.
    #
    #   @api public
    #   @return [Float, nil] the longitude of the vehicle
    #   @example
    #     drive_state.longitude
    attribute :longitude

    # @!method heading
    #   The compass heading of the vehicle in degrees
    #   @api public
    #   @return [Integer, nil] the compass heading of the vehicle
    #   @example
    #     drive_state.heading
    attribute :heading

    # @!method speed
    #   The speed of the vehicle in miles per hour, or nil when it is parked
    #   @api public
    #   @return [Integer, nil] the speed of the vehicle
    #   @example
    #     drive_state.speed
    attribute :speed

    # @!method power
    #   The power the vehicle is drawing in kilowatts
    #
    #   It is negative while the vehicle charges or regenerates.
    #
    #   @api public
    #   @return [Integer, nil] the power the vehicle is drawing
    #   @example
    #     drive_state.power
    attribute :power

    # @!method shift_state
    #   The gear the vehicle is in, "P", "R", "N", or "D"
    #
    #   It is nil when the vehicle is parked and idle.
    #
    #   @api public
    #   @return [String, nil] the gear the vehicle is in
    #   @example
    #     drive_state.shift_state
    attribute :shift_state

    # @!method timestamp
    #   The time the vehicle reported the state
    #   @api public
    #   @return [Time, nil] the time the vehicle reported the state
    #   @raise [InvalidResponse] if the timestamp is not a number of milliseconds
    #   @example
    #     drive_state.timestamp
    time_attribute :timestamp
  end
end
