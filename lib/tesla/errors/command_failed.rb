# frozen_string_literal: true

require_relative "error"

module Tesla
  # Error raised when a vehicle answers a command by saying it did not carry it out
  #
  # A command the Fleet API could not deliver, such as one sent to a vehicle that is asleep, is answered with an
  # HTTP status and raises the {HTTPError} of that status. This is the error of a command that was delivered: the
  # vehicle read it and refused, such as a charge that cannot be started because no cable is connected.
  #
  # @api public
  class CommandFailed < Error
    # The command the vehicle did not carry out
    # @api public
    # @return [String] the name of the command, as the Fleet API names it
    # @example Get the command
    #   error.command # => "charge_start"
    attr_reader :command

    # The reason the vehicle gave
    # @api public
    # @return [String] the reason, which is empty when the vehicle gave none
    # @example Get the reason
    #   error.reason # => "disconnected"
    attr_reader :reason

    # Initialize a new CommandFailed
    #
    # @api public
    # @param command [String] the name of the command, as the Fleet API names it
    # @param reason [String, nil] the reason the vehicle gave
    # @return [CommandFailed] a new instance
    # @example Create a command failed error
    #   Tesla::CommandFailed.new(command: "charge_start", reason: "disconnected")
    def initialize(command:, reason:)
      @command = command
      @reason = reason.to_s
      super(["The vehicle did not carry out #{command}", @reason].reject(&:empty?).join(": "))
    end
  end
end
