# frozen_string_literal: true

module Tesla
  module API
    # The media commands, which control what a vehicle plays
    # @api public
    module MediaEndpoints
      # Play or pause the media of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.toggle_playback "5YJSA11111111111"
      def toggle_playback(vehicle)
        command(vehicle, "media_toggle_playback")
      end

      # Skip to the next track of the media of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.next_track "5YJSA11111111111"
      def next_track(vehicle)
        command(vehicle, "media_next_track")
      end

      # Skip to the previous track of the media of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.previous_track "5YJSA11111111111"
      def previous_track(vehicle)
        command(vehicle, "media_prev_track")
      end

      # Skip to the next favorite of the media of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.next_favorite "5YJSA11111111111"
      def next_favorite(vehicle)
        command(vehicle, "media_next_fav")
      end

      # Skip to the previous favorite of the media of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.previous_favorite "5YJSA11111111111"
      def previous_favorite(vehicle)
        command(vehicle, "media_prev_fav")
      end

      # Turn up the volume of the media of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.volume_up "5YJSA11111111111"
      def volume_up(vehicle)
        command(vehicle, "media_volume_up")
      end

      # Turn down the volume of the media of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.volume_down "5YJSA11111111111"
      def volume_down(vehicle)
        command(vehicle, "media_volume_down")
      end

      # Set the volume of the media of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param volume [Numeric] The volume, from 0 to 11.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.set_volume "5YJSA11111111111", 4.5
      def set_volume(vehicle, volume)
        command(vehicle, "adjust_volume", volume:)
      end
    end
  end
end
