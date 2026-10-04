# frozen_string_literal: true

require_relative "charge_state"
require_relative "climate_state"
require_relative "drive_state"
require_relative "gui_settings"
require_relative "vehicle"
require_relative "vehicle_config"
require_relative "vehicle_state"

module Tesla
  # A vehicle and the state of its subsystems
  #
  # The Fleet API answers with the states it was asked for, so the reader of one it was not asked for answers nil
  # (see {API::VehicleEndpoints#vehicle_data}).
  #
  # @api public
  class VehicleData < Vehicle
    # @!method charge_state
    #   The state of the battery and the charging
    #   @api public
    #   @return [ChargeState, nil] the state of the battery and the charging
    #   @example
    #     vehicle_data.charge_state.battery_level
    resource_attribute :charge_state, ChargeState

    # @!method climate_state
    #   The state of the climate control
    #   @api public
    #   @return [ClimateState, nil] the state of the climate control
    #   @example
    #     vehicle_data.climate_state.inside_temp
    resource_attribute :climate_state, ClimateState

    # @!method drive_state
    #   The position and the driving state
    #   @api public
    #   @return [DriveState, nil] the position and the driving state
    #   @example
    #     vehicle_data.drive_state.shift_state
    resource_attribute :drive_state, DriveState

    # @!method gui_settings
    #   The units and formats the vehicle displays
    #   @api public
    #   @return [GUISettings, nil] the units and formats the vehicle displays
    #   @example
    #     vehicle_data.gui_settings.temperature_units
    resource_attribute :gui_settings, GUISettings

    # @!method vehicle_config
    #   The configuration the vehicle was built with
    #   @api public
    #   @return [VehicleConfig, nil] the configuration the vehicle was built with
    #   @example
    #     vehicle_data.vehicle_config.car_type
    resource_attribute :vehicle_config, VehicleConfig

    # @!method vehicle_state
    #   The physical state of the vehicle
    #   @api public
    #   @return [VehicleState, nil] the physical state of the vehicle
    #   @example
    #     vehicle_data.vehicle_state.locked?
    resource_attribute :vehicle_state, VehicleState
  end
end
