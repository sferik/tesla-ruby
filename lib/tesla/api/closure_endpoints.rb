# frozen_string_literal: true

module Tesla
  module API
    # The closure commands, which lock, open, and close the doors, trunks, windows, and sunroof of a vehicle
    # @api public
    module ClosureEndpoints
      # Lock the doors of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.lock_doors "5YJSA11111111111"
      def lock_doors(vehicle)
        command(vehicle, "door_lock")
      end

      # Unlock the doors of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.unlock_doors "5YJSA11111111111"
      def unlock_doors(vehicle)
        command(vehicle, "door_unlock")
      end

      # Open the rear trunk of a vehicle, or close it
      #
      # A vehicle with a powered liftgate closes a trunk that is open, so this is the command that pops the trunk and
      # the one that closes it again. A trunk without one is opened and stays open.
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.actuate_trunk "5YJSA11111111111"
      def actuate_trunk(vehicle)
        command(vehicle, "actuate_trunk", which_trunk: "rear")
      end

      # Open the front trunk of a vehicle
      #
      # The front trunk is closed by hand on the vehicles that do not close it themselves.
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.open_frunk "5YJSA11111111111"
      def open_frunk(vehicle)
        command(vehicle, "actuate_trunk", which_trunk: "front")
      end

      # Vent the windows of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.vent_windows "5YJSA11111111111"
      def vent_windows(vehicle)
        command(vehicle, "window_control", command: "vent", lat: 0, lon: 0)
      end

      # Close the windows of a vehicle
      #
      # A vehicle that takes the command over the Fleet API rather than through the vehicle command proxy closes its
      # windows only for a user who is near it, so the position of the user is sent along.
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param latitude [Numeric] The latitude of the user.
      # @param longitude [Numeric] The longitude of the user.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.close_windows "5YJSA11111111111"
      # @example
      #   Tesla.close_windows "5YJSA11111111111", latitude: 37.4929, longitude: -121.9453
      def close_windows(vehicle, latitude: 0, longitude: 0)
        command(vehicle, "window_control", command: "close", lat: latitude, lon: longitude)
      end

      # Vent the sunroof of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.vent_sunroof "5YJSA11111111111"
      def vent_sunroof(vehicle)
        command(vehicle, "sun_roof_control", state: "vent")
      end

      # Close the sunroof of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.close_sunroof "5YJSA11111111111"
      def close_sunroof(vehicle)
        command(vehicle, "sun_roof_control", state: "close")
      end

      # Open or close the garage door a vehicle is paired with over HomeLink
      #
      # The vehicle triggers HomeLink only for a user who is near it, so the position of the user is sent along.
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param latitude [Numeric] The latitude of the user.
      # @param longitude [Numeric] The longitude of the user.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.trigger_homelink "5YJSA11111111111", latitude: 37.4929, longitude: -121.9453
      def trigger_homelink(vehicle, latitude:, longitude:)
        command(vehicle, "trigger_homelink", lat: latitude, lon: longitude)
      end
    end
  end
end
