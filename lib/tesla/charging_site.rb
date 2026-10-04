# frozen_string_literal: true

require_relative "resource"

module Tesla
  # A charging site near a vehicle
  # @api public
  class ChargingSite < Resource
    inspect_with :name, :type

    # @!method name
    #   The name of the site
    #   @api public
    #   @return [String, nil] the name of the site
    #   @example
    #     charging_site.name
    attribute :name

    # @!method type
    #   The type of the site, "supercharger" or "destination"
    #   @api public
    #   @return [String, nil] the type of the site
    #   @example
    #     charging_site.type
    attribute :type

    # @!method distance_miles
    #   The distance from the vehicle to the site in miles
    #   @api public
    #   @return [Float, nil] the distance from the vehicle to the site
    #   @example
    #     charging_site.distance_miles
    attribute :distance_miles

    # @!method available_stalls
    #   The number of stalls that are free, which a Supercharger reports
    #   @api public
    #   @return [Integer, nil] the number of stalls that are free
    #   @example
    #     charging_site.available_stalls
    attribute :available_stalls

    # @!method total_stalls
    #   The number of stalls the site has, which a Supercharger reports
    #   @api public
    #   @return [Integer, nil] the number of stalls the site has
    #   @example
    #     charging_site.total_stalls
    attribute :total_stalls

    # @!method location
    #   The position of the site, as its "lat" and "long"
    #   @api public
    #   @return [Hash{String => Float}, nil] the position of the site
    #   @example
    #     charging_site.location
    attribute :location

    # @!method site_closed?
    #   Whether the site is closed
    #   @api public
    #   @return [Boolean] whether the site is closed
    #   @example
    #     charging_site.site_closed?
    predicate :site_closed
  end
end
