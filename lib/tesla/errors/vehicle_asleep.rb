# frozen_string_literal: true

require_relative "error"

module Tesla
  # Error raised when a vehicle that was woken is still not online once the wait for it is over
  #
  # A vehicle can take a minute to wake, and one without a connection, such as one parked underground, does not
  # wake at all.
  #
  # @api public
  class VehicleAsleep < Error
    # The vehicle as the Fleet API last answered with it
    # @api public
    # @return [Vehicle] the vehicle, whose state says why it is not online
    # @example Get the state the vehicle was last in
    #   error.vehicle.state # => "asleep"
    attr_reader :vehicle

    # Initialize a new VehicleAsleep
    #
    # @api public
    # @param vehicle [Vehicle] the vehicle as the Fleet API last answered with it
    # @return [VehicleAsleep] a new instance
    # @example Create a vehicle asleep error
    #   Tesla::VehicleAsleep.new(vehicle: vehicle)
    def initialize(vehicle:)
      @vehicle = vehicle
      super("The vehicle is still #{vehicle.state.inspect} rather than online")
    end
  end
end
