# frozen_string_literal: true

require_relative "resource"

module Tesla
  # A vehicle of the account
  # @api public
  class Vehicle < Resource
    inspect_with :vin, :display_name, :state
    identified_by :vin

    # @!method id
    #   The ID the Fleet API knows the vehicle by
    #   @api public
    #   @return [Integer, nil] the ID the Fleet API knows the vehicle by
    #   @example
    #     vehicle.id
    attribute :id

    # @!method vehicle_id
    #   The ID the streaming and Autopark APIs know the vehicle by
    #   @api public
    #   @return [Integer, nil] the ID the streaming and Autopark APIs know the vehicle by
    #   @example
    #     vehicle.vehicle_id
    attribute :vehicle_id

    # @!method vin
    #   The vehicle identification number
    #   @api public
    #   @return [String, nil] the vehicle identification number
    #   @example
    #     vehicle.vin
    attribute :vin

    # @!method display_name
    #   The name the owner gave the vehicle
    #   @api public
    #   @return [String, nil] the name the owner gave the vehicle
    #   @example
    #     vehicle.display_name
    attribute :display_name

    # @!method state
    #   The state of the vehicle, such as "online", "asleep", or "offline"
    #   @api public
    #   @return [String, nil] the state of the vehicle
    #   @example
    #     vehicle.state
    attribute :state

    # @!method access_type
    #   The access the account has to the vehicle, such as "OWNER" or "DRIVER"
    #   @api public
    #   @return [String, nil] the access the account has to the vehicle
    #   @example
    #     vehicle.access_type
    attribute :access_type

    # @!method api_version
    #   The version of the API the vehicle speaks
    #   @api public
    #   @return [Integer, nil] the version of the API the vehicle speaks
    #   @example
    #     vehicle.api_version
    attribute :api_version

    # @!method in_service?
    #   Whether the vehicle is being serviced
    #   @api public
    #   @return [Boolean] whether the vehicle is being serviced
    #   @example
    #     vehicle.in_service?
    predicate :in_service

    # Whether the vehicle is online
    #
    # A vehicle takes commands and answers with its data only while it is online.
    #
    # A vehicle that is asleep is woken with {API::VehicleEndpoints#wake_up}.
    #
    # @api public
    # @return [Boolean] whether the state of the vehicle is "online"
    # @example
    #   vehicle.online?
    def online?
      state.eql?("online")
    end
  end
end
