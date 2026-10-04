# frozen_string_literal: true

require "forwardable"
require_relative "tesla/client"
require_relative "tesla/configuration"
require_relative "tesla/version"

# A Ruby wrapper for the Tesla Fleet API
#
# Every public method of {API} is a method of this module too, delegated to {.client}: {API::VehicleEndpoints#vehicles}
# is `Tesla.vehicles`, {API::ClosureEndpoints#actuate_trunk} is `Tesla.actuate_trunk`, and so on for every endpoint.
# They are delegated as the module is loaded rather than written out, so they are not listed among the methods
# below; {API} groups them into one mixin per topic, and each is documented there.
#
# The raw request methods, {Client#get} and the rest, are on the client rather than on this module, since a request
# of your own is made with {.client}.
#
# @api public
# @see API The endpoints, grouped into one mixin per topic
module Tesla
  extend Configuration
  extend SingleForwardable

  # The mutex that guards the client the API methods of the module delegate to
  CLIENT_MUTEX = Mutex.new
  private_constant :CLIENT_MUTEX

  # The settings of the global configuration a client is built from, and built again for when one of them changes
  CLIENT_SETTINGS = %i[host access_token refresh_token client_id client_secret].freeze
  private_constant :CLIENT_SETTINGS

  # The settings of the global configuration that are applied to the client the module has, rather than building
  # another one from them
  APPLIED_SETTINGS = %i[redirect_uri audience authorization_endpoint token_endpoint on_token_refresh user_agent
    open_timeout read_timeout write_timeout keep_alive_timeout debug_output proxy_url ca_file max_redirects
    max_retries max_retry_delay].freeze
  private_constant :APPLIED_SETTINGS

  # @!method self.new(**options)
  #   Alias for Tesla::Client.new
  #   @api public
  #   @param options [Hash] options passed to {Tesla::Client#initialize}
  #   @yield [client] the client, which is closed once the block is done with it (see {Tesla::Client.new})
  #   @return [Tesla::Client, Object] a new client, or what the block returned
  #   @example Create a client
  #     Tesla.new(access_token: "eyJhbGciOiJSUzI1NiIs")
  #   @example Close the connections of a client once a block is done with it
  #     Tesla.new { |client| client.vehicles }
  def_delegator "Tesla::Client", :new

  # The endpoints of {API}, each delegated to the client the module has. They are read from the module as it is
  # loaded rather than written out one by one, so YARD has none of them to document here; {API} documents each of
  # them in the mixin it belongs to.
  def_delegators :client, *API.public_instance_methods

  # The methods of SingleForwardable, which the module delegates with rather than offers, so that `Tesla.delegate`
  # and the rest are not mistaken for methods of the API
  private_class_method(*SingleForwardable.instance_methods)

  # The client the API methods of the module delegate to
  #
  # The client is built from the global configuration, and a change to that configuration is applied to the client
  # it has rather than building another one, which would throw away what the client learned: the tokens it was
  # answered with when it refreshed its access token, of which the refresh token is the only one that still works.
  #
  # Another client is built only for the host and the credentials that tokens are issued for, since a client that
  # was given other ones has nothing to keep from the ones it had.
  #
  # @api public
  # @return [Client] the client
  # @example Perform a raw request with the module's client
  #   Tesla.client.get("/api/1/vehicles")
  def self.client
    CLIENT_MUTEX.synchronize do
      rebuild_client unless values_of(CLIENT_SETTINGS).eql?(@client_values)
      apply_settings unless values_of(APPLIED_SETTINGS).eql?(@applied_values)
      @client
    end
  end

  # Reset the global configuration and forget the client
  #
  # The client is forgotten as well as the configuration it was built from, so that what it learned from
  # credentials that have been reset, such as the tokens it refreshed, is not kept. Its connections are closed,
  # since no request of the module will be sent on them again.
  #
  # The configuration is reset while the client is forgotten rather than afterwards, so that a thread asking for the
  # client is given one built from the configuration as it was or as it has been reset, rather than one built from a
  # configuration that is half of each.
  #
  # @api public
  # @return [self]
  # @example Reset the configuration
  #   Tesla.reset
  def self.reset
    CLIENT_MUTEX.synchronize do
      @client&.close
      @client_values = nil
      super
    end
  end

  # Build the client again from the global configuration
  #
  # The client is built from the whole of the configuration, so the settings that are applied to a client are the
  # ones it already has. The client being replaced is closed once the new one has been built, since no request of
  # the module will be sent on its connections again, and so that a configuration a client cannot be built from
  # leaves the client the module has open rather than closing it on the way to raising.
  #
  # @api private
  # @return [Array<Object>] the settings the client was built from
  def self.rebuild_client
    client = new
    @client&.close
    @client = client
    @client_values = values_of(CLIENT_SETTINGS)
  end
  private_class_method :rebuild_client

  # The values of settings of the global configuration
  #
  # @api private
  # @param settings [Array<Symbol>] the names of the settings
  # @return [Array<Object>] the values
  def self.values_of(settings)
    settings.map { |setting| public_send(setting) }
  end
  private_class_method :values_of

  # Apply the rest of the global configuration to the client the module has
  #
  # @api private
  # @return [Array<Object>] the configuration applied to the client
  def self.apply_settings
    APPLIED_SETTINGS.each { |setting| @client.public_send(:"#{setting}=", public_send(setting)) }
    @applied_values = values_of(APPLIED_SETTINGS)
  end
  private_class_method :apply_settings
end
