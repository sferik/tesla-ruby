# frozen_string_literal: true

require_relative "resource"

module Tesla
  # The state of the climate control of a vehicle
  # @api public
  class ClimateState < Resource
    inspect_with :inside_temp, :driver_temp_setting

    # @!method inside_temp
    #   The temperature inside the vehicle in degrees Celsius
    #   @api public
    #   @return [Float, nil] the temperature inside the vehicle
    #   @example
    #     climate_state.inside_temp
    attribute :inside_temp

    # @!method outside_temp
    #   The temperature outside the vehicle in degrees Celsius
    #   @api public
    #   @return [Float, nil] the temperature outside the vehicle
    #   @example
    #     climate_state.outside_temp
    attribute :outside_temp

    # @!method driver_temp_setting
    #   The temperature the driver's side is set to in degrees Celsius
    #   @api public
    #   @return [Float, nil] the temperature the driver's side is set to
    #   @example
    #     climate_state.driver_temp_setting
    attribute :driver_temp_setting

    # @!method passenger_temp_setting
    #   The temperature the passenger's side is set to in degrees Celsius
    #   @api public
    #   @return [Float, nil] the temperature the passenger's side is set to
    #   @example
    #     climate_state.passenger_temp_setting
    attribute :passenger_temp_setting

    # @!method fan_status
    #   The speed of the fan
    #   @api public
    #   @return [Integer, nil] the speed of the fan
    #   @example
    #     climate_state.fan_status
    attribute :fan_status

    # @!method climate_keeper_mode
    #   The Climate Keeper mode, such as "off", "dog", or "camp"
    #   @api public
    #   @return [String, nil] the Climate Keeper mode
    #   @example
    #     climate_state.climate_keeper_mode
    attribute :climate_keeper_mode

    # @!method seat_heater_left
    #   The level of the heater of the front left seat, from 0 to 3
    #   @api public
    #   @return [Integer, nil] the level of the heater of the front left seat
    #   @example
    #     climate_state.seat_heater_left
    attribute :seat_heater_left

    # @!method seat_heater_right
    #   The level of the heater of the front right seat, from 0 to 3
    #   @api public
    #   @return [Integer, nil] the level of the heater of the front right seat
    #   @example
    #     climate_state.seat_heater_right
    attribute :seat_heater_right

    # @!method climate_on?
    #   Whether the climate control is on
    #   @api public
    #   @return [Boolean] whether the climate control is on
    #   @example
    #     climate_state.climate_on?
    predicate :climate_on, :is_climate_on

    # @!method preconditioning?
    #   Whether the vehicle is preconditioning
    #   @api public
    #   @return [Boolean] whether the vehicle is preconditioning
    #   @example
    #     climate_state.preconditioning?
    predicate :preconditioning, :is_preconditioning

    # @!method front_defroster_on?
    #   Whether the front defroster is on
    #   @api public
    #   @return [Boolean] whether the front defroster is on
    #   @example
    #     climate_state.front_defroster_on?
    predicate :front_defroster_on, :is_front_defroster_on

    # @!method rear_defroster_on?
    #   Whether the rear defroster is on
    #   @api public
    #   @return [Boolean] whether the rear defroster is on
    #   @example
    #     climate_state.rear_defroster_on?
    predicate :rear_defroster_on, :is_rear_defroster_on

    # @!method timestamp
    #   The time the vehicle reported the state
    #   @api public
    #   @return [Time, nil] the time the vehicle reported the state
    #   @raise [InvalidResponse] if the timestamp is not a number of milliseconds
    #   @example
    #     climate_state.timestamp
    time_attribute :timestamp
  end
end
