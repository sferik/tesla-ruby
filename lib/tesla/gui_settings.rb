# frozen_string_literal: true

require_relative "resource"

module Tesla
  # The units and formats a vehicle displays
  # @api public
  class GUISettings < Resource
    inspect_with :distance_units, :temperature_units

    # @!method distance_units
    #   The unit of distance the vehicle displays, "mi/hr" or "km/hr"
    #   @api public
    #   @return [String, nil] the unit of distance the vehicle displays
    #   @example
    #     gui_settings.distance_units
    attribute :distance_units, :gui_distance_units

    # @!method temperature_units
    #   The unit of temperature the vehicle displays, "F" or "C"
    #   @api public
    #   @return [String, nil] the unit of temperature the vehicle displays
    #   @example
    #     gui_settings.temperature_units
    attribute :temperature_units, :gui_temperature_units

    # @!method charge_rate_units
    #   The unit of charge rate the vehicle displays, such as "mi/hr" or "kW"
    #   @api public
    #   @return [String, nil] the unit of charge rate the vehicle displays
    #   @example
    #     gui_settings.charge_rate_units
    attribute :charge_rate_units, :gui_charge_rate_units

    # @!method range_display
    #   The range the vehicle displays, "Rated" or "Ideal"
    #   @api public
    #   @return [String, nil] the range the vehicle displays
    #   @example
    #     gui_settings.range_display
    attribute :range_display, :gui_range_display

    # @!method twenty_four_hour_time?
    #   Whether the vehicle displays the time on a 24-hour clock
    #   @api public
    #   @return [Boolean] whether the vehicle displays the time on a 24-hour clock
    #   @example
    #     gui_settings.twenty_four_hour_time?
    predicate :twenty_four_hour_time, :gui_24_hour_time

    # @!method timestamp
    #   The time the vehicle reported the state
    #   @api public
    #   @return [Time, nil] the time the vehicle reported the state
    #   @raise [InvalidResponse] if the timestamp is not a number of milliseconds
    #   @example
    #     gui_settings.timestamp
    time_attribute :timestamp
  end
end
