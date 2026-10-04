# frozen_string_literal: true

module Tesla
  module API
    # The climate commands, which control the temperature of the cabin and the seats of a vehicle
    # @api public
    module ClimateEndpoints
      # The seats of a vehicle, by the number the Fleet API knows each by
      #
      # @api public
      SEATS = {front_left: 0, front_right: 1, rear_left: 2, rear_left_back: 3, rear_center: 4, rear_right: 5,
               rear_right_back: 6, third_row_left: 7, third_row_right: 8}.freeze

      # The Climate Keeper modes, by the number the Fleet API knows each by
      #
      # Dog Mode and Camp Mode keep the climate control on after the driver has left the vehicle.
      #
      # @api public
      CLIMATE_KEEPER_MODES = {off: 0, on: 1, dog: 2, camp: 3}.freeze

      # Turn on the climate control of a vehicle
      #
      # The cabin is heated or cooled to the temperature it is set to (see {#set_temperature}).
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.start_climate "5YJSA11111111111"
      def start_climate(vehicle)
        command(vehicle, "auto_conditioning_start")
      end

      # Turn off the climate control of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.stop_climate "5YJSA11111111111"
      def stop_climate(vehicle)
        command(vehicle, "auto_conditioning_stop")
      end

      # Set the temperature the climate control of a vehicle heats or cools the cabin to
      #
      # The temperatures are in degrees Celsius, whatever unit the vehicle displays. The climate control is not turned
      # on (see {#start_climate}).
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param driver [Numeric] The temperature of the driver's side in degrees Celsius.
      # @param passenger [Numeric] The temperature of the passenger's side in degrees Celsius, which defaults to
      #   the driver's.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.set_temperature "5YJSA11111111111", 21.5
      # @example
      #   Tesla.set_temperature "5YJSA11111111111", 21.5, 19
      def set_temperature(vehicle, driver, passenger = driver)
        command(vehicle, "set_temps", driver_temp: driver, passenger_temp: passenger)
      end

      # Turn the maximum defrost of a vehicle on or off
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param on [Boolean] Whether to turn it on.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.set_max_defrost "5YJSA11111111111", on: true
      def set_max_defrost(vehicle, on:)
        command(vehicle, "set_preconditioning_max", on:)
      end

      # Set the heater of a seat of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param seat [Symbol, String] The seat, which is one of the seats {SEATS} names.
      # @param level [Integer] The level of the heater, from 0, which is off, to 3.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @raise [ArgumentError] if the seat is not one the API defines
      # @example
      #   Tesla.set_seat_heater "5YJSA11111111111", :front_left, 3
      def set_seat_heater(vehicle, seat, level)
        command(vehicle, "remote_seat_heater_request", seat_position: number_of(SEATS, seat, "seat"), level:)
      end

      # Set the cooler of a seat of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param seat [Symbol, String] The seat, which is one of the seats {SEATS} names.
      # @param level [Integer] The level of the cooler, from 0, which is off, to 3.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @raise [ArgumentError] if the seat is not one the API defines
      # @example
      #   Tesla.set_seat_cooler "5YJSA11111111111", :front_left, 3
      def set_seat_cooler(vehicle, seat, level)
        command(vehicle, "remote_seat_cooler_request", seat_position: number_of(SEATS, seat, "seat"), seat_cooler_level: level)
      end

      # Turn the heater of the steering wheel of a vehicle on or off
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param on [Boolean] Whether to turn it on.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.set_steering_wheel_heater "5YJSA11111111111", on: true
      def set_steering_wheel_heater(vehicle, on:)
        command(vehicle, "remote_steering_wheel_heater_request", on:)
      end

      # Set the Climate Keeper mode of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param mode [Symbol, String] The mode, which is one of the modes {CLIMATE_KEEPER_MODES} names.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @raise [ArgumentError] if the mode is not one the API defines
      # @example
      #   Tesla.set_climate_keeper_mode "5YJSA11111111111", :dog
      def set_climate_keeper_mode(vehicle, mode)
        mode = number_of(CLIMATE_KEEPER_MODES, mode, "climate keeper mode")
        command(vehicle, "set_climate_keeper_mode", climate_keeper_mode: mode)
      end

      # Turn the Bioweapon Defense Mode of a vehicle on or off
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param on [Boolean] Whether to turn it on.
      # @param manual_override [Boolean] Whether to turn it on although the vehicle would not, such as with a low
      #   battery.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.set_bioweapon_mode "5YJSA11111111111", on: true
      def set_bioweapon_mode(vehicle, on:, manual_override: false)
        command(vehicle, "set_bioweapon_mode", on:, manual_override:)
      end

      # Turn the Cabin Overheat Protection of a vehicle on or off
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param on [Boolean] Whether to turn it on.
      # @param fan_only [Boolean] Whether to cool the cabin with the fan alone, without the air conditioning.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.set_cabin_overheat_protection "5YJSA11111111111", on: true
      # @example
      #   Tesla.set_cabin_overheat_protection "5YJSA11111111111", on: true, fan_only: true
      def set_cabin_overheat_protection(vehicle, on:, fan_only: false)
        command(vehicle, "set_cabin_overheat_protection", on:, fan_only:)
      end
    end
  end
end
