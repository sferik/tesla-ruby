# frozen_string_literal: true

module Tesla
  module API
    # The navigation commands, which send a destination to a vehicle
    # @api public
    module NavigationEndpoints
      # The type of a navigation request, which is the one the Tesla app shares a destination with
      NAVIGATION_REQUEST_TYPE = "share_ext_content_raw"
      # The key of the destination of a navigation request
      NAVIGATION_REQUEST_TEXT = "android.intent.extra.TEXT"
      private_constant :NAVIGATION_REQUEST_TYPE, :NAVIGATION_REQUEST_TEXT

      # Send a destination to the navigation of a vehicle
      #
      # The vehicle searches for the destination as it would for one typed into its navigation, so an address and
      # the name of a place both work.
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param destination [String] The address or the name of the place to navigate to.
      # @param locale [String] The locale the destination is written in.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.navigate_to "5YJSA11111111111", "3500 Deer Creek Road, Palo Alto, CA"
      def navigate_to(vehicle, destination, locale: "en-US")
        command(vehicle, "navigation_request", type: NAVIGATION_REQUEST_TYPE, locale:,
          timestamp_ms: Process.clock_gettime(Process::CLOCK_REALTIME, :millisecond),
          value: {NAVIGATION_REQUEST_TEXT => destination})
      end

      # Send a position to the navigation of a vehicle
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param latitude [Numeric] The latitude of the destination.
      # @param longitude [Numeric] The longitude of the destination.
      # @param order [Integer] The place of the destination among the ones the vehicle is navigating to.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @example
      #   Tesla.navigate_to_coordinates "5YJSA11111111111", 37.3947, -122.1503
      def navigate_to_coordinates(vehicle, latitude, longitude, order: 1)
        command(vehicle, "navigation_gps_request", lat: latitude, lon: longitude, order:)
      end
    end
  end
end
