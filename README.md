# Tesla

[![tests](https://github.com/sferik/tesla-ruby/actions/workflows/test.yml/badge.svg)](https://github.com/sferik/tesla-ruby/actions/workflows/test.yml)
[![mutation tests](https://github.com/sferik/tesla-ruby/actions/workflows/mutant.yml/badge.svg)](https://github.com/sferik/tesla-ruby/actions/workflows/mutant.yml)
[![linter](https://github.com/sferik/tesla-ruby/actions/workflows/lint.yml/badge.svg)](https://github.com/sferik/tesla-ruby/actions/workflows/lint.yml)
[![type checker](https://github.com/sferik/tesla-ruby/actions/workflows/steep.yml/badge.svg)](https://github.com/sferik/tesla-ruby/actions/workflows/steep.yml)
[![docs](https://github.com/sferik/tesla-ruby/actions/workflows/docs.yml/badge.svg)](https://github.com/sferik/tesla-ruby/actions/workflows/docs.yml)

Ruby wrapper for the [Tesla Fleet API](https://developer.tesla.com/docs/fleet-api).

## Installation

Install the gem and add to the application's Gemfile:

    bundle add tesla

Or, if Bundler is not being used to manage dependencies:

    gem install tesla

## Usage Examples

```ruby
require 'tesla'

Tesla.access_token = 'eyJhbGciOiJSUzI1NiIs...'

# Return the vehicles of the account.
car = Tesla.vehicles.first
car.vin              # => "5YJSA11111111111"
car.display_name     # => "Nikola 2.0"
car.state            # => "asleep"

# Wake the car, and wait up to a minute for it to be online.
car = Tesla.wake_up car, timeout: 60
car.online?          # => true

# Pop the trunk. A powered liftgate that is open closes again.
Tesla.actuate_trunk car

# Open the frunk.
Tesla.open_frunk car

# Set the temperature, in degrees Celsius, and turn on the climate control.
Tesla.set_temperature car, 21.5
Tesla.start_climate car

# Heat the driver's seat, and the steering wheel.
Tesla.set_seat_heater car, :front_left, 3
Tesla.set_steering_wheel_heater car, on: true

# Keep the dog cool.
Tesla.set_climate_keeper_mode car, :dog

# Lock and unlock the doors.
Tesla.lock_doors car
Tesla.unlock_doors car

# Vent the windows, and close them again.
Tesla.vent_windows car
Tesla.close_windows car

# Find the car in a parking lot.
Tesla.flash_lights car
Tesla.honk_horn car

# Charge to 80%, at 32 amps.
Tesla.set_charge_limit car, 80
Tesla.set_charging_amps car, 32
Tesla.open_charge_port car
Tesla.start_charging car

# Send a destination to the navigation.
Tesla.navigate_to car, '3500 Deer Creek Road, Palo Alto, CA'

# Turn on Sentry Mode.
Tesla.set_sentry_mode car, on: true

# A VIN stands in for the car wherever one is expected.
Tesla.lock_doors '5YJSA11111111111'

# Send a command the library has no method for.
Tesla.command car, :set_vehicle_name, vehicle_name: 'Nikola 2.0'
```

Every command returns `true` once the car has carried it out. Each is documented, with its parameters, in the
mixin of [`Tesla::API`](https://www.rubydoc.info/gems/tesla/Tesla/API) it belongs to:

| Mixin | Commands |
| ----- | -------- |
| `ClosureEndpoints` | `lock_doors`, `unlock_doors`, `actuate_trunk`, `open_frunk`, `vent_windows`, `close_windows`, `vent_sunroof`, `close_sunroof`, `trigger_homelink` |
| `ClimateEndpoints` | `start_climate`, `stop_climate`, `set_temperature`, `set_max_defrost`, `set_seat_heater`, `set_seat_cooler`, `set_steering_wheel_heater`, `set_climate_keeper_mode`, `set_bioweapon_mode`, `set_cabin_overheat_protection` |
| `ChargingEndpoints` | `open_charge_port`, `close_charge_port`, `start_charging`, `stop_charging`, `set_charge_limit`, `set_charging_amps`, `charge_to_standard_range`, `charge_to_max_range` |
| `AlertEndpoints` | `honk_horn`, `flash_lights` |
| `MediaEndpoints` | `toggle_playback`, `next_track`, `previous_track`, `next_favorite`, `previous_favorite`, `volume_up`, `volume_down`, `set_volume` |
| `NavigationEndpoints` | `navigate_to`, `navigate_to_coordinates` |
| `SecurityEndpoints` | `set_sentry_mode`, `set_valet_mode`, `reset_valet_pin`, `remote_start`, `set_speed_limit`, `activate_speed_limit`, `deactivate_speed_limit`, `clear_speed_limit_pin` |
| `SoftwareEndpoints` | `schedule_software_update`, `cancel_software_update` |

### Reading the state of the car

```ruby
data = Tesla.vehicle_data car

data.charge_state.battery_level        # => 59
data.charge_state.battery_range        # => 149.92, in miles
data.charge_state.charging_state       # => "Charging"
data.climate_state.inside_temp         # => 22.1, in degrees Celsius
data.climate_state.climate_on?         # => false
data.vehicle_state.locked?             # => true
data.vehicle_state.trunk_open?         # => false
data.vehicle_state.odometer            # => 57869.762487, in miles
data.vehicle_config.car_type           # => "modely"
data.gui_settings.temperature_units    # => "F"

# The Fleet API answers with the position of the car only when it is asked for,
# for an access token with the vehicle_location scope.
data = Tesla.vehicle_data car, endpoints: %i[location_data drive_state]
data.drive_state.latitude              # => 33.111111

# The charging sites near the car.
Tesla.nearby_charging_sites(car).superchargers.map(&:name)

# The user the access token was issued for.
Tesla.me.email
```

Responses are immutable objects with a reader for the fields used most. Every field of the response is kept, and
read with `[]` or `to_h`:

```ruby
data.charge_state[:charge_energy_added]   # => 2.42
data.to_h                                 # => {"id" => 12345678901234567, ...}

case Tesla.vehicle(car)
in {state: "online"} then puts "ready"
in {state:} then puts "the car is #{state}"
end
```

## Using it with your own car

The Fleet API is not only for fleets: it is the API Tesla offers for any car, and an application that commands a
single car of your own is set up the same way as one that commands thousands. No approval to manage a fleet is
involved, but there is some setup, which Tesla describes in its
[getting started guide](https://developer.tesla.com/docs/fleet-api/getting-started/what-is-fleet-api):

1. Create an application at [developer.tesla.com](https://developer.tesla.com) with the Tesla account that owns the
   car, which issues a client ID and a client secret.
2. Generate a key pair, and serve the public key from a domain of yours at
   `/.well-known/appspecific/com.tesla.3p.public-key.pem`.
3. Register the application in your region with `Tesla.register_partner`.
4. Authorize the application for your own account (see [Authentication](#authentication)), and keep the refresh
   token.
5. Add the key of the application to the car, by opening `https://tesla.com/_ak/your-domain.example` on the phone
   that has the Tesla app.
6. Run the [vehicle command proxy](#the-vehicle-command-proxy) with the private key, and point the library at it.

## Authentication

Requests are authorized with an OAuth 2.0 access token, which Tesla issues to an application registered at
[developer.tesla.com](https://developer.tesla.com). The OAuth 2.0 requests are built by the
[simple_oauth](https://github.com/laserlemon/simple_oauth) gem.

```ruby
Tesla.configure do |config|
  config.client_id = '81527cff06843c8634fdc09e8ac0abef'
  config.client_secret = 'ta-secret.7vx6VkVvk2gBgSrN'
  config.redirect_uri = 'https://example.com/auth/callback'
end
```

Each of those falls back to an environment variable until it is assigned: `TESLA_CLIENT_ID`, `TESLA_CLIENT_SECRET`,
`TESLA_REDIRECT_URI`, `TESLA_ACCESS_TOKEN`, and `TESLA_REFRESH_TOKEN`.

```ruby
# 1. Register the application in the region it is used in, once.
Tesla.register_partner 'example.com'

# 2. Send the owner of the car to authorize the application.
state = SecureRandom.hex
redirect_to Tesla.authorization_url(state: state)

# 3. Tesla sends them back to the redirect URI with a code. Check the state, and exchange the code for tokens.
response = SimpleOAuth::OAuth2::AuthorizationResponse.parse(request.query_string, state: state)
token = Tesla.exchange_code response.code

token.access_token    # lasts eight hours
token.refresh_token   # lasts three months, and is used once
token.expires_at      # => 2026-10-04 20:00:00 UTC
```

The module keeps the tokens, and authorizes its requests with them from then on. In another process, start from the
tokens that were stored:

```ruby
Tesla.configure do |config|
  config.access_token = stored.access_token
  config.refresh_token = stored.refresh_token
end
```

### Refreshing the access token

A client with a refresh token and a client ID asks for a new access token when the Fleet API answers that the one it
sent is no longer good, and sends the request again. One with a refresh token and no access token asks for one before
its first request.

A refresh token is used once: each refresh answers with another, which is the one the next refresh needs. Store the
new tokens whenever they change:

```ruby
Tesla.on_token_refresh = ->(token) { store(token.access_token, token.refresh_token) }

# Refresh ahead of time, rather than when a request is turned away.
Tesla.refresh_access_token
```

## The vehicle command proxy

Most cars built since 2021 only take commands signed with the
[Tesla Vehicle Command Protocol](https://github.com/teslamotors/vehicle-command), and the Fleet API answers an
unsigned one with a `Tesla::Forbidden`. Tesla's
[vehicle command proxy](https://github.com/teslamotors/vehicle-command#using-the-http-proxy) signs commands with the
private key of your application, and hands every other request on to the Fleet API. Point the library at it:

```ruby
Tesla.configure do |config|
  config.host = 'https://localhost:4443'
  # Trust the certificate the proxy was started with. TLS verification is never turned off.
  config.ca_file = 'config/tls-cert.pem'
  # Tokens are issued for the Fleet API of your region rather than for the proxy.
  config.audience = Tesla::Configuration::NORTH_AMERICA_HOST
end
```

The proxy knows a car by its VIN, which is what the library sends for a `Tesla::Vehicle`.

## Configuration

```ruby
Tesla.configure do |config|
  # The Fleet API of your region: NORTH_AMERICA_HOST (the default), EUROPE_HOST, or CHINA_HOST.
  # Tesla.region.fleet_api_base_url names the one an account is served by.
  config.host = Tesla::Configuration::EUROPE_HOST

  config.open_timeout = 10      # seconds, 60 by default
  config.read_timeout = 30      # seconds, 60 by default
  config.write_timeout = 30     # seconds, 60 by default
  config.keep_alive_timeout = 2 # seconds an idle connection is kept open, the default; 0 opens one per request
  config.max_redirects = 10     # the default
  config.proxy_url = 'http://proxy.example.com:8080'
  config.user_agent = 'MyApp/1.0'
  config.max_retries = 2        # the default; 0 turns retrying off
  config.max_retry_delay = 60   # seconds, the default
end
```

Every option can be given to a client of its own instead, which is how several accounts are used at once:

```ruby
client = Tesla::Client.new(access_token: 'eyJhbGciOiJSUzI1NiIs...', host: Tesla::Configuration::EUROPE_HOST)
client.vehicles
client.actuate_trunk '5YJSA11111111111'

# A request of your own, for an endpoint the library has no method for.
client.get '/api/1/vehicles/5YJSA11111111111/release_notes'
```

### Connections

A request that only asks for something is sent on the connection the request before it left open, so a series of
them does not open a connection each. A command is sent on a connection of its own, which is closed afterwards, since
a command sent on a connection the server has closed could not be sent again. `Client#close` closes the connections
a client keeps open, and a client built with a block closes them when the block returns:

```ruby
Tesla::Client.new(access_token: 'eyJhbGciOiJSUzI1NiIs...') do |client|
  client.vehicles.each { |car| puts client.vehicle_data(car).charge_state.battery_level }
end
```

### Redirects

A redirect is followed, up to `max_redirects` times. One to another scheme, host, or port is followed without the
access token and without the headers of the caller, and one that would send the body of a request to another host
is not followed at all.

### Debug output

```ruby
Tesla.debug_output = $stderr
```

Every request and response is written to the IO, with the credentials they carry redacted: the `Authorization` and
`Proxy-Authorization` headers, the tokens and the client secret of a request to the token endpoint and of its
response, and the PIN or password of a command.

### Retries

A request the Fleet API rate limited (429) is sent again, up to `max_retries` times, after the wait its `Retry-After`
header asks for. A request that only asks for something is also sent again after a 502, 503, or 504, or when the
network loses it. A command is not: the car may have carried it out before the answer went missing, and a trunk asked
to open twice closes again.

## Errors

Every error the library raises is a `Tesla::Error`.

```ruby
begin
  Tesla.start_charging car
rescue Tesla::CommandFailed => e
  e.reason            # => "disconnected": the car read the command and refused
rescue Tesla::RequestTimeout
  Tesla.wake_up car, timeout: 60   # the car is asleep or offline
  retry
rescue Tesla::TooManyRequests => e
  sleep e.retry_after
  retry
rescue Tesla::HTTPError => e
  e.code              # => 403
  e.message           # => the error the Fleet API describes
end
```

| Error | Raised when |
| ----- | ----------- |
| `Tesla::CommandFailed` | the car answers that it did not carry out a command |
| `Tesla::VehicleAsleep` | the car is not online once the `timeout` of `wake_up` is over |
| `Tesla::OAuthError` | the token endpoint turns a request for a token away |
| `Tesla::NetworkError` | the request is lost to the network |
| `Tesla::TooManyRedirects` | a request is redirected more than `max_redirects` times |
| `Tesla::InvalidResponse` | a successful response cannot be read |
| `Tesla::HTTPError` | the response is not successful; its subclasses are named for the status, and are each a `Tesla::ClientError` or a `Tesla::ServerError` |

The statuses the Fleet API gives a meaning of its own:

| Status | Error | Meaning |
| ------ | ----- | ------- |
| 401 | `Tesla::Unauthorized` | the access token is missing, expired, or revoked |
| 403 | `Tesla::Forbidden` | the token lacks a scope, or the car takes only signed commands |
| 408 | `Tesla::RequestTimeout` | the car is asleep or offline |
| 412 | `Tesla::PreconditionFailed` | the application is not registered in the region |
| 421 | `Tesla::MisdirectedRequest` | the account belongs to another region |
| 429 | `Tesla::TooManyRequests` | the application is rate limited |
| 540 | `Tesla::DeviceUnexpectedResponse` | the car answered with an error |

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake` to run the specs,
the linters, the mutation tests, the type checker, and the documentation checks. `bin/console` opens an interactive
prompt.

The library is tested on Ruby 3.4, Ruby 4.0, and JRuby 10, on Linux, macOS, and Windows.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sferik/tesla-ruby. See
[CONTRIBUTING.md](CONTRIBUTING.md).

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.md).

This project is not affiliated with or endorsed by Tesla, Inc.
