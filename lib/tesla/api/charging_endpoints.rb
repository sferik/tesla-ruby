# frozen_string_literal: true

module Tesla
  module API
    # The charging commands, which control how a vehicle charges
    # @api public
    module ChargingEndpoints
      # Open the charge port of a vehicle, or unlock the cable in it
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.open_charge_port "5YJSA11111111111"
      def open_charge_port(vehicle)
        command(vehicle, "charge_port_door_open")
      end

      # Close the charge port of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.close_charge_port "5YJSA11111111111"
      def close_charge_port(vehicle)
        command(vehicle, "charge_port_door_close")
      end

      # Start charging a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.start_charging "5YJSA11111111111"
      def start_charging(vehicle)
        command(vehicle, "charge_start")
      end

      # Stop charging a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.stop_charging "5YJSA11111111111"
      def stop_charging(vehicle)
        command(vehicle, "charge_stop")
      end

      # Set the charge a vehicle stops charging at
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param percent [Integer] The charge to stop at, as a percentage.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.set_charge_limit "5YJSA11111111111", 80
      def set_charge_limit(vehicle, percent)
        command(vehicle, "set_charge_limit", percent:)
      end

      # Set the current a vehicle charges with
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param amps [Integer] The current in amps.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.set_charging_amps "5YJSA11111111111", 32
      def set_charging_amps(vehicle, amps)
        command(vehicle, "set_charging_amps", charging_amps: amps)
      end

      # Set the charge limit of a vehicle to the one Tesla recommends for daily driving
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.charge_to_standard_range "5YJSA11111111111"
      def charge_to_standard_range(vehicle)
        command(vehicle, "charge_standard")
      end

      # Set the charge limit of a vehicle to the whole of its battery
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.charge_to_max_range "5YJSA11111111111"
      def charge_to_max_range(vehicle)
        command(vehicle, "charge_max_range")
      end
    end
  end
end
