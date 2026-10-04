# frozen_string_literal: true

module Tesla
  module API
    # The alert commands, which draw attention to a vehicle
    # @api public
    module AlertEndpoints
      # Honk the horn of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.honk_horn "5YJSA11111111111"
      def honk_horn(vehicle)
        command(vehicle, "honk_horn")
      end

      # Flash the headlights of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.flash_lights "5YJSA11111111111"
      def flash_lights(vehicle)
        command(vehicle, "flash_lights")
      end
    end
  end
end
