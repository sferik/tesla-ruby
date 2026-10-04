# frozen_string_literal: true

require_relative "resource"

module Tesla
  # The physical state of a vehicle, such as whether it is locked
  # @api public
  class VehicleState < Resource
    inspect_with :car_version, :odometer

    # @!method car_version
    #   The version of the software the vehicle runs
    #   @api public
    #   @return [String, nil] the version of the software the vehicle runs
    #   @example
    #     vehicle_state.car_version
    attribute :car_version

    # @!method odometer
    #   The odometer in miles, whatever unit the vehicle displays
    #   @api public
    #   @return [Float, nil] the odometer
    #   @example
    #     vehicle_state.odometer
    attribute :odometer

    # @!method vehicle_name
    #   The name the owner gave the vehicle
    #   @api public
    #   @return [String, nil] the name the owner gave the vehicle
    #   @example
    #     vehicle_state.vehicle_name
    attribute :vehicle_name

    # @!method sun_roof_state
    #   The state of the sunroof, such as "closed" or "vent"
    #   @api public
    #   @return [String, nil] the state of the sunroof
    #   @example
    #     vehicle_state.sun_roof_state
    attribute :sun_roof_state

    # @!method locked?
    #   Whether the vehicle is locked
    #   @api public
    #   @return [Boolean] whether the vehicle is locked
    #   @example
    #     vehicle_state.locked?
    predicate :locked

    # @!method sentry_mode?
    #   Whether Sentry Mode is on
    #   @api public
    #   @return [Boolean] whether Sentry Mode is on
    #   @example
    #     vehicle_state.sentry_mode?
    predicate :sentry_mode

    # @!method valet_mode?
    #   Whether Valet Mode is on
    #   @api public
    #   @return [Boolean] whether Valet Mode is on
    #   @example
    #     vehicle_state.valet_mode?
    predicate :valet_mode

    # @!method user_present?
    #   Whether someone is in the vehicle
    #   @api public
    #   @return [Boolean] whether someone is in the vehicle
    #   @example
    #     vehicle_state.user_present?
    predicate :user_present, :is_user_present

    # @!method remote_start?
    #   Whether the vehicle has been started remotely
    #   @api public
    #   @return [Boolean] whether the vehicle has been started remotely
    #   @example
    #     vehicle_state.remote_start?
    predicate :remote_start

    # @!method timestamp
    #   The time the vehicle reported the state
    #   @api public
    #   @return [Time, nil] the time the vehicle reported the state
    #   @raise [InvalidResponse] if the timestamp is not a number of milliseconds
    #   @example
    #     vehicle_state.timestamp
    time_attribute :timestamp

    # Whether the front trunk is open
    #
    # @api public
    # @return [Boolean] whether the front trunk is open
    # @example
    #   vehicle_state.frunk_open?
    def frunk_open?
      open?(self[:ft])
    end

    # Whether the rear trunk is open
    #
    # @api public
    # @return [Boolean] whether the rear trunk is open
    # @example
    #   vehicle_state.trunk_open?
    def trunk_open?
      open?(self[:rt])
    end

    private

    # Whether a closure is open
    #
    # The Fleet API writes an open closure as a number other than zero.
    #
    # @api private
    # @param value [Integer, nil] the state of the closure
    # @return [Boolean] whether the closure is open, which one the response does not carry is not
    def open?(value)
      !(value.nil? || value.zero?)
    end
  end
end
