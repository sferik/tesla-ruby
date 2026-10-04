# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
* Add `vehicles`, `vehicle`, `vehicle_data`, `wake_up`, `nearby_charging_sites`, and `mobile_enabled?` for the vehicle endpoints of the Tesla Fleet API; `wake_up` takes a `timeout` to wait for the vehicle to be online
* Add `command`, which sends any command to a vehicle, returns `true` once the vehicle has carried it out, and raises `Tesla::CommandFailed` with the reason the vehicle gave when it has not
* Add the closure commands `lock_doors`, `unlock_doors`, `actuate_trunk`, `open_frunk`, `vent_windows`, `close_windows`, `vent_sunroof`, `close_sunroof`, and `trigger_homelink`
* Add the climate commands `start_climate`, `stop_climate`, `set_temperature`, `set_max_defrost`, `set_seat_heater`, `set_seat_cooler`, `set_steering_wheel_heater`, `set_climate_keeper_mode`, `set_bioweapon_mode`, and `set_cabin_overheat_protection`
* Add the charging commands `open_charge_port`, `close_charge_port`, `start_charging`, `stop_charging`, `set_charge_limit`, `set_charging_amps`, `charge_to_standard_range`, and `charge_to_max_range`
* Add the alert commands `honk_horn` and `flash_lights`, the media commands `toggle_playback`, `next_track`, `previous_track`, `next_favorite`, `previous_favorite`, `volume_up`, `volume_down`, and `set_volume`, and the navigation commands `navigate_to` and `navigate_to_coordinates`
* Add the security commands `set_sentry_mode`, `set_valet_mode`, `reset_valet_pin`, `remote_start`, `set_speed_limit`, `activate_speed_limit`, `deactivate_speed_limit`, and `clear_speed_limit_pin`, and the software commands `schedule_software_update` and `cancel_software_update`
* Add `me` and `region` for the user endpoints, and `register_partner` and `partner_public_key` for the partner endpoints
* Add OAuth 2.0 with the simple_oauth gem: `authorization_url`, `exchange_code`, `refresh_access_token`, and `partner_token`
* Refresh the access token when the Fleet API answers that it is no longer good, for a client with a refresh token and a client ID, and call `on_token_refresh` with the new tokens
* Wrap responses in `Vehicle`, `VehicleData`, `ChargeState`, `ClimateState`, `DriveState`, `VehicleState`, `VehicleConfig`, `GUISettings`, `NearbyChargingSites`, `ChargingSite`, `User`, and `Region` objects, which are immutable, compare by identity, match `case`/`in` patterns, inspect as short summaries, and keep `[]` and `to_h` for the raw response
* Accept a `Vehicle` wherever a VIN or the ID of a vehicle is expected
* Add `host`, `audience`, `authorization_endpoint`, `token_endpoint`, `user_agent`, `open_timeout`, `read_timeout`, `write_timeout`, `keep_alive_timeout`, `debug_output`, `proxy_url`, `max_redirects`, and `ca_file` options, set globally or per client; the credentials fall back to the `TESLA_ACCESS_TOKEN`, `TESLA_REFRESH_TOKEN`, `TESLA_CLIENT_ID`, `TESLA_CLIENT_SECRET`, and `TESLA_REDIRECT_URI` environment variables, and the host to `TESLA_HOST`
* Add `max_retries` and `max_retry_delay` options: a 429 is sent again twice by default, honoring `Retry-After`, as is a 502, 503, or 504, or a request the network lost, for the requests that only ask for something; a command is never sent a second time
* Reuse connections across the requests to the same host that only ask for something; `Client#close` closes them, and a client built with a block closes them when the block returns
* Follow redirects, up to `max_redirects` times, without the access token when one leads to another host, and never with the body of a request to another host
* Redact the access token, the tokens and the client secret of a token request and its response, and the PIN or password of a command from `debug_output`
* Raise an error named for the HTTP status of an unsuccessful response, such as `Tesla::RequestTimeout` for a vehicle that is asleep, each a `Tesla::HTTPError` and a `Tesla::Error`, with the error the Fleet API describes as its message
* Ship RBS signatures
