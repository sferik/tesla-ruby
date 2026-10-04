# frozen_string_literal: true

require_relative "resource"

module Tesla
  # The state of the battery and the charging of a vehicle
  # @api public
  class ChargeState < Resource
    inspect_with :battery_level, :charging_state

    # @!method battery_level
    #   The charge of the battery, as a percentage
    #   @api public
    #   @return [Integer, nil] the charge of the battery
    #   @example
    #     charge_state.battery_level
    attribute :battery_level

    # @!method usable_battery_level
    #   The charge of the battery that can be used, as a percentage
    #
    #   It is lower than the charge of the battery when the battery is cold.
    #
    #   @api public
    #   @return [Integer, nil] the charge of the battery that can be used
    #   @example
    #     charge_state.usable_battery_level
    attribute :usable_battery_level

    # @!method battery_range
    #   The rated range of the battery in miles, whatever unit the vehicle displays
    #   @api public
    #   @return [Float, nil] the rated range of the battery
    #   @example
    #     charge_state.battery_range
    attribute :battery_range

    # @!method charge_limit
    #   The charge the vehicle stops charging at, as a percentage
    #   @api public
    #   @return [Integer, nil] the charge the vehicle stops charging at
    #   @example
    #     charge_state.charge_limit
    attribute :charge_limit, :charge_limit_soc

    # @!method charging_state
    #   The state of charging, such as "Charging" or "Disconnected"
    #   @api public
    #   @return [String, nil] the state of charging
    #   @example
    #     charge_state.charging_state
    attribute :charging_state

    # @!method charge_amps
    #   The current the vehicle asks the charger for, in amps
    #   @api public
    #   @return [Integer, nil] the current the vehicle asks the charger for
    #   @example
    #     charge_state.charge_amps
    attribute :charge_amps

    # @!method charge_rate
    #   The rate of charging in miles of range per hour
    #   @api public
    #   @return [Float, nil] the rate of charging
    #   @example
    #     charge_state.charge_rate
    attribute :charge_rate

    # @!method charger_power
    #   The power of the charger in kilowatts
    #   @api public
    #   @return [Integer, nil] the power of the charger
    #   @example
    #     charge_state.charger_power
    attribute :charger_power

    # @!method minutes_to_full_charge
    #   The minutes until the vehicle reaches its charge limit
    #   @api public
    #   @return [Integer, nil] the minutes until the vehicle reaches its charge limit
    #   @example
    #     charge_state.minutes_to_full_charge
    attribute :minutes_to_full_charge

    # @!method charge_port_latch
    #   The state of the latch of the charge port, such as "Engaged"
    #   @api public
    #   @return [String, nil] the state of the latch of the charge port
    #   @example
    #     charge_state.charge_port_latch
    attribute :charge_port_latch

    # @!method charge_port_door_open?
    #   Whether the door of the charge port is open
    #   @api public
    #   @return [Boolean] whether the door of the charge port is open
    #   @example
    #     charge_state.charge_port_door_open?
    predicate :charge_port_door_open

    # @!method timestamp
    #   The time the vehicle reported the state
    #   @api public
    #   @return [Time, nil] the time the vehicle reported the state
    #   @raise [InvalidResponse] if the timestamp is not a number of milliseconds
    #   @example
    #     charge_state.timestamp
    time_attribute :timestamp
  end
end
