# frozen_string_literal: true

require_relative "../errors/command_failed"
require_relative "../identifiers"
require_relative "../json_parsing"
require_relative "../path_escaping"

module Tesla
  module API
    # The command endpoint, which every command of the other mixins is sent through
    #
    # A vehicle has to be online to take a command (see {VehicleEndpoints#wake_up}), and most vehicles take only
    # commands signed with the Tesla Vehicle Command Protocol, which the vehicle command proxy does: a client whose
    # `host` is the proxy sends its commands through it.
    #
    # @api public
    module CommandEndpoints
      include Identifiers
      include JSONParsing
      include PathEscaping

      # Send a command to a vehicle
      #
      # The commands of the other mixins are sent with this, which also sends the commands the library has no
      # method for.
      #
      # @api public
      # @authenticated true
      # @param vehicle [String, Integer, Vehicle] The VIN or ID of a vehicle, or a vehicle.
      # @param name [String, Symbol] The name of the command, as the Fleet API names it.
      # @param params [Hash] The parameters of the command.
      # @return [true] once the vehicle has carried out the command
      # @raise [CommandFailed] if the vehicle answers that it did not carry out the command
      # @raise [RequestTimeout] if the vehicle is asleep or offline
      # @raise [InvalidResponse] if the response does not say whether the vehicle carried out the command
      # @example
      #   Tesla.command "5YJSA11111111111", :set_vehicle_name, vehicle_name: "Nikola 2.0"
      def command(vehicle, name, **params)
        body = post("/api/1/vehicles/#{escape(tag_of(vehicle))}/command/#{escape(name)}", params)
        result, reason = parse_response(body) { |response| [response.fetch("result"), response["reason"]] }
        raise CommandFailed.new(command: name.to_s, reason:) unless result

        true
      end

      private

      # Look up the number the Fleet API knows a named option by
      #
      # @api private
      # @param options [Hash{Symbol => Integer}] the numbers of the options, by name
      # @param name [Symbol, String] the name of the option
      # @param kind [String] what the option is, which the message names
      # @return [Integer] the number
      # @raise [ArgumentError] if the name is not one of the options
      def number_of(options, name, kind)
        options.fetch(name.to_sym) do
          raise ArgumentError, "Unknown #{kind}: #{name}. The #{kind}s the API defines are: #{options.keys.join(", ")}"
        end
      end
    end
  end
end
