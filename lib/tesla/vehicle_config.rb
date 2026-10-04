# frozen_string_literal: true

require_relative "resource"

module Tesla
  # The configuration a vehicle was built with
  # @api public
  class VehicleConfig < Resource
    inspect_with :car_type, :trim_badging

    # @!method car_type
    #   The model of the vehicle, such as "model3" or "modely"
    #   @api public
    #   @return [String, nil] the model of the vehicle
    #   @example
    #     vehicle_config.car_type
    attribute :car_type

    # @!method trim_badging
    #   The trim of the vehicle, such as "p90d"
    #   @api public
    #   @return [String, nil] the trim of the vehicle
    #   @example
    #     vehicle_config.trim_badging
    attribute :trim_badging

    # @!method exterior_color
    #   The color of the paint
    #   @api public
    #   @return [String, nil] the color of the paint
    #   @example
    #     vehicle_config.exterior_color
    attribute :exterior_color

    # @!method wheel_type
    #   The wheels the vehicle was built with
    #   @api public
    #   @return [String, nil] the wheels the vehicle was built with
    #   @example
    #     vehicle_config.wheel_type
    attribute :wheel_type

    # @!method charge_port_type
    #   The type of the charge port, such as "US" or "CCS"
    #   @api public
    #   @return [String, nil] the type of the charge port
    #   @example
    #     vehicle_config.charge_port_type
    attribute :charge_port_type

    # @!method sun_roof_installed
    #   The sunroof the vehicle was built with, or zero for none
    #   @api public
    #   @return [Integer, nil] the sunroof the vehicle was built with
    #   @example
    #     vehicle_config.sun_roof_installed
    attribute :sun_roof_installed

    # @!method can_actuate_trunks?
    #   Whether the trunks of the vehicle can be opened remotely
    #   @api public
    #   @return [Boolean] whether the trunks of the vehicle can be opened remotely
    #   @example
    #     vehicle_config.can_actuate_trunks?
    predicate :can_actuate_trunks

    # @!method power_liftgate?
    #   Whether the vehicle has a powered liftgate
    #
    #   A powered liftgate can be closed as well as opened remotely.
    #
    #   @api public
    #   @return [Boolean] whether the vehicle has a powered liftgate
    #   @example
    #     vehicle_config.power_liftgate?
    predicate :power_liftgate, :plg

    # @!method right_hand_drive?
    #   Whether the vehicle is right-hand drive
    #   @api public
    #   @return [Boolean] whether the vehicle is right-hand drive
    #   @example
    #     vehicle_config.right_hand_drive?
    predicate :right_hand_drive, :rhd

    # @!method timestamp
    #   The time the vehicle reported the state
    #   @api public
    #   @return [Time, nil] the time the vehicle reported the state
    #   @raise [InvalidResponse] if the timestamp is not a number of milliseconds
    #   @example
    #     vehicle_config.timestamp
    time_attribute :timestamp
  end
end
