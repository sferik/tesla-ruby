# frozen_string_literal: true

require_relative "../errors/vehicle_asleep"
require_relative "../identifiers"
require_relative "../json_parsing"
require_relative "../nearby_charging_sites"
require_relative "../path_escaping"
require_relative "../vehicle"
require_relative "../vehicle_data"

module Tesla
  module API
    # The vehicle endpoints, which list the vehicles of an account, read their state, and wake them
    # @api public
    module VehicleEndpoints
      include Identifiers
      include JSONParsing
      include PathEscaping

      # The seconds between the requests that ask whether a vehicle being woken is online yet
      DEFAULT_WAKE_INTERVAL = 2 # seconds

      # List the vehicles of the account
      #
      # @api public
      # @authenticated true
      # @param page [Integer, nil] The page of vehicles, from 1, or nil for the first.
      # @param per_page [Integer, nil] The number of vehicles on a page, or nil for the default of the Fleet API.
      # @return [Array<Vehicle>]
      # @example
      #   Tesla.vehicles.map(&:display_name)
      def vehicles(page: nil, per_page: nil)
        Vehicle.list(parse_response(get("/api/1/vehicles", {page:, per_page:}.compact)))
      end

      # View a vehicle of the account
      #
      # The vehicle is answered with whatever state it is in, without waking it.
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [Vehicle]
      # @example
      #   Tesla.vehicle("5YJSA11111111111").state
      def vehicle(vehicle)
        Vehicle.new(parse_response(get(vehicle_path(vehicle))))
      end

      # Read the state of a vehicle and its subsystems
      #
      # The vehicle has to be online to answer (see {#wake_up}).
      #
      # The Fleet API answers with the states it is asked for, and leaves the position of the vehicle out of the
      # ones it answers with by default: it is asked for as "location_data", and answered for an access token with
      # the vehicle_location scope.
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param endpoints [Array<String, Symbol>, String, Symbol, nil] The states to answer with, among
      #   "charge_state", "climate_state", "closures_state", "drive_state", "gui_settings", "location_data",
      #   "charge_schedule_data", "preconditioning_schedule_data", "vehicle_config", and "vehicle_state", or nil for
      #   the default of the Fleet API.
      # @return [VehicleData]
      # @raise [RequestTimeout] if the vehicle is asleep or offline
      # @example
      #   Tesla.vehicle_data("5YJSA11111111111").charge_state.battery_level
      # @example
      #   Tesla.vehicle_data("5YJSA11111111111", endpoints: %i[location_data drive_state]).drive_state.latitude
      def vehicle_data(vehicle, endpoints: nil)
        params = {endpoints: endpoints && [endpoints].join(";")}.compact
        VehicleData.new(parse_response(get("#{vehicle_path(vehicle)}/vehicle_data", params)))
      end

      # Wake a vehicle from sleep
      #
      # The Fleet API answers before the vehicle has woken, so the vehicle answered with is seldom online. With a
      # timeout, the vehicle is asked for again every few seconds until it is online, and that is the vehicle
      # answered with.
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param timeout [Numeric, nil] The seconds to wait for the vehicle to be online, or nil not to wait.
      # @param interval [Numeric] The seconds between the requests that ask whether the vehicle is online yet.
      # @return [Vehicle] the vehicle, which is online when a timeout was given
      # @raise [VehicleAsleep] if the vehicle is not online once the timeout is over
      # @example
      #   Tesla.wake_up "5YJSA11111111111"
      # @example
      #   Tesla.wake_up "5YJSA11111111111", timeout: 60
      def wake_up(vehicle, timeout: nil, interval: DEFAULT_WAKE_INTERVAL)
        woken = Vehicle.new(parse_response(post("#{vehicle_path(vehicle)}/wake_up")))
        timeout ? await_online(woken, monotonic_time + timeout, interval) : woken
      end

      # List the charging sites near a vehicle
      #
      # The vehicle has to be online to answer (see {#wake_up}).
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [NearbyChargingSites]
      # @raise [RequestTimeout] if the vehicle is asleep or offline
      # @example
      #   Tesla.nearby_charging_sites("5YJSA11111111111").superchargers.map(&:name)
      def nearby_charging_sites(vehicle)
        NearbyChargingSites.new(parse_response(get("#{vehicle_path(vehicle)}/nearby_charging_sites")))
      end

      # Whether a vehicle allows mobile access
      #
      # A vehicle is commanded remotely only while mobile access is enabled in it.
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @return [Boolean] whether mobile access is enabled in the vehicle
      # @raise [RequestTimeout] if the vehicle is asleep or offline
      # @example
      #   Tesla.mobile_enabled? "5YJSA11111111111"
      def mobile_enabled?(vehicle)
        parse_response(get("#{vehicle_path(vehicle)}/mobile_enabled")).eql?(true)
      end

      private

      # The path of a vehicle
      #
      # @api private
      # @param vehicle [String, Integer, Vehicle] the VIN or ID of a vehicle, or a vehicle
      # @return [String] the path
      def vehicle_path(vehicle)
        "/api/1/vehicles/#{escape(tag_of(vehicle))}"
      end

      # Ask for a vehicle until it is online
      #
      # The vehicle is asked for rather than woken again, since one wake-up is enough to wake a vehicle that can be
      # woken, and the Fleet API allows fewer of them.
      #
      # Kernel#sleep takes any Numeric, but its signature asks for the narrower interface Integer and Float happen to
      # answer, so the seconds are passed to it unchecked rather than narrowing what the interval accepts.
      #
      # @api private
      # @param woken [Vehicle] the vehicle, as the Fleet API last answered with it
      # @param deadline [Numeric] the time, on the monotonic clock, the wait is over
      # @param interval [Numeric] the seconds between the requests
      # @return [Vehicle] the vehicle, once it is online
      # @raise [VehicleAsleep] if the vehicle is not online once the wait is over
      def await_online(woken, deadline, interval)
        until woken.online?
          raise VehicleAsleep.new(vehicle: woken) if monotonic_time >= deadline

          sleep(interval) # steep:ignore UnresolvedOverloading
          woken = vehicle(woken)
        end
        woken
      end

      # The time on the monotonic clock
      #
      # A change to the time of the system does not move the monotonic clock, so a wait is measured with it.
      #
      # @api private
      # @return [Float] the seconds since an arbitrary moment
      def monotonic_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
