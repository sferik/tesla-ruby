# frozen_string_literal: true

module Tesla
  module API
    # The security commands, which control who can drive a vehicle and how
    # @api public
    module SecurityEndpoints
      # Turn the Sentry Mode of a vehicle on or off
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param on [Boolean] Whether to turn it on.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.set_sentry_mode "5YJSA11111111111", on: true
      def set_sentry_mode(vehicle, on:)
        command(vehicle, "set_sentry_mode", on:)
      end

      # Turn the Valet Mode of a vehicle on or off
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param on [Boolean] Whether to turn it on.
      # @param password [String, nil] The four digit PIN that turns Valet Mode off again in the vehicle, or nil for
      #   none.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.set_valet_mode "5YJSA11111111111", on: true
      # @example
      #   Tesla.set_valet_mode "5YJSA11111111111", on: true, password: "1234"
      def set_valet_mode(vehicle, on:, password: nil)
        command(vehicle, "set_valet_mode", **{on:, password:}.compact)
      end

      # Clear the PIN that turns the Valet Mode of a vehicle off
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.reset_valet_pin "5YJSA11111111111"
      def reset_valet_pin(vehicle)
        command(vehicle, "reset_valet_pin")
      end

      # Let a vehicle be driven without a key for the next two minutes
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.remote_start "5YJSA11111111111"
      def remote_start(vehicle)
        command(vehicle, "remote_start_drive")
      end

      # Set the speed the Speed Limit Mode of a vehicle limits it to
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param mph [Numeric] The speed in miles per hour, from 50 to 120.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.set_speed_limit "5YJSA11111111111", 65
      def set_speed_limit(vehicle, mph)
        command(vehicle, "speed_limit_set_limit", limit_mph: mph)
      end

      # Turn on the Speed Limit Mode of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param pin [String] The four digit PIN that turns Speed Limit Mode off again.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.activate_speed_limit "5YJSA11111111111", "1234"
      def activate_speed_limit(vehicle, pin)
        command(vehicle, "speed_limit_activate", pin:)
      end

      # Turn off the Speed Limit Mode of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param pin [String] The four digit PIN Speed Limit Mode was turned on with.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.deactivate_speed_limit "5YJSA11111111111", "1234"
      def deactivate_speed_limit(vehicle, pin)
        command(vehicle, "speed_limit_deactivate", pin:)
      end

      # Clear the PIN of the Speed Limit Mode of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param pin [String] The four digit PIN Speed Limit Mode was turned on with.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.clear_speed_limit_pin "5YJSA11111111111", "1234"
      def clear_speed_limit_pin(vehicle, pin)
        command(vehicle, "speed_limit_clear_pin", pin:)
      end
    end
  end
end
