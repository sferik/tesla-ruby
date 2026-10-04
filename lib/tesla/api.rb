# frozen_string_literal: true

require_relative "api/alert_endpoints"
require_relative "api/charging_endpoints"
require_relative "api/climate_endpoints"
require_relative "api/closure_endpoints"
require_relative "api/command_endpoints"
require_relative "api/media_endpoints"
require_relative "api/navigation_endpoints"
require_relative "api/oauth_endpoints"
require_relative "api/partner_endpoints"
require_relative "api/security_endpoints"
require_relative "api/software_endpoints"
require_relative "api/user_endpoints"
require_relative "api/vehicle_endpoints"

module Tesla
  # The Tesla Fleet API endpoints, mixed into {Client}
  #
  # The endpoints are grouped into one mixin per topic. Every public method of those mixins is also available on
  # the {Tesla} module, which delegates to {Tesla.client}.
  #
  # @api public
  module API
    include AlertEndpoints
    include ChargingEndpoints
    include ClimateEndpoints
    include ClosureEndpoints
    include CommandEndpoints
    include MediaEndpoints
    include NavigationEndpoints
    include OAuthEndpoints
    include PartnerEndpoints
    include SecurityEndpoints
    include SoftwareEndpoints
    include UserEndpoints
    include VehicleEndpoints
  end
end
