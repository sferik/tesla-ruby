# frozen_string_literal: true

module Tesla
  module API
    # The software commands, which control the software updates of a vehicle
    # @api public
    module SoftwareEndpoints
      # Install the software update a vehicle has downloaded
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param offset [Integer] The seconds to wait before the update is installed, which is none by default.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.schedule_software_update "5YJSA11111111111"
      # @example
      #   Tesla.schedule_software_update "5YJSA11111111111", offset: 7200
      def schedule_software_update(vehicle, offset: 0)
        command(vehicle, "schedule_software_update", offset_sec: offset)
      end

      # Cancel the software update a vehicle is waiting to install
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.cancel_software_update "5YJSA11111111111"
      def cancel_software_update(vehicle)
        command(vehicle, "cancel_software_update")
      end
    end
  end
end
