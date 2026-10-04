# frozen_string_literal: true

RSpec.describe Tesla::API::ClimateEndpoints do
  let(:client) { Tesla::Client.new(access_token: TEST_ACCESS_TOKEN) }

  describe "#start_climate" do
    before { stub_command("auto_conditioning_start") }

    it "sends the auto_conditioning_start command" do
      client.start_climate(TEST_VIN)

      expect(a_command("auto_conditioning_start").with(body: {})).to have_been_made
    end
  end

  describe "#stop_climate" do
    before { stub_command("auto_conditioning_stop") }

    it "sends the auto_conditioning_stop command" do
      client.stop_climate(TEST_VIN)

      expect(a_command("auto_conditioning_stop").with(body: {})).to have_been_made
    end
  end

  describe "#set_temperature" do
    before { stub_command("set_temps") }

    it "sends the set_temps command with its defaults" do
      client.set_temperature(TEST_VIN, 21.5)

      expect(a_command("set_temps").with(body: {driver_temp: 21.5, passenger_temp: 21.5})).to have_been_made
    end

    it "sends the set_temps command with the options given" do
      client.set_temperature(TEST_VIN, 21.5, 19)

      expect(a_command("set_temps").with(body: {driver_temp: 21.5, passenger_temp: 19})).to have_been_made
    end
  end

  describe "#set_max_defrost" do
    before { stub_command("set_preconditioning_max") }

    it "sends the set_preconditioning_max command" do
      client.set_max_defrost(TEST_VIN, on: true)

      expect(a_command("set_preconditioning_max").with(body: {on: true})).to have_been_made
    end
  end

  describe "#set_seat_heater" do
    before { stub_command("remote_seat_heater_request") }

    it "sends the remote_seat_heater_request command" do
      client.set_seat_heater(TEST_VIN, :front_right, 3)

      expect(a_command("remote_seat_heater_request").with(body: {seat_position: 1, level: 3})).to have_been_made
    end

    it "takes the seat as a String" do
      client.set_seat_heater(TEST_VIN, "rear_center", 1)

      expect(a_command("remote_seat_heater_request").with(body: hash_including(seat_position: 4))).to have_been_made
    end

    it "rejects a seat the API does not define" do
      expect { client.set_seat_heater(TEST_VIN, :trunk, 3) }
        .to raise_error(ArgumentError, /\AUnknown seat: trunk\. The seats the API defines are: front_left, /)
    end
  end

  describe "#set_seat_cooler" do
    before { stub_command("remote_seat_cooler_request") }

    it "sends the remote_seat_cooler_request command" do
      client.set_seat_cooler(TEST_VIN, :front_right, 3)

      expect(a_command("remote_seat_cooler_request").with(body: {seat_position: 1, seat_cooler_level: 3})).to have_been_made
    end

    it "takes the seat as a String" do
      client.set_seat_cooler(TEST_VIN, "rear_center", 1)

      expect(a_command("remote_seat_cooler_request").with(body: hash_including(seat_position: 4))).to have_been_made
    end

    it "rejects a seat the API does not define" do
      expect { client.set_seat_cooler(TEST_VIN, :trunk, 3) }
        .to raise_error(ArgumentError, /\AUnknown seat: trunk\. The seats the API defines are: front_left, /)
    end
  end

  describe "#set_steering_wheel_heater" do
    before { stub_command("remote_steering_wheel_heater_request") }

    it "sends the remote_steering_wheel_heater_request command" do
      client.set_steering_wheel_heater(TEST_VIN, on: true)

      expect(a_command("remote_steering_wheel_heater_request").with(body: {on: true})).to have_been_made
    end
  end

  describe "#set_climate_keeper_mode" do
    before { stub_command("set_climate_keeper_mode") }

    it "sends the set_climate_keeper_mode command" do
      client.set_climate_keeper_mode(TEST_VIN, :dog)

      expect(a_command("set_climate_keeper_mode").with(body: {climate_keeper_mode: 2})).to have_been_made
    end

    it "takes the mode as a String" do
      client.set_climate_keeper_mode(TEST_VIN, "camp")

      expect(a_command("set_climate_keeper_mode").with(body: {climate_keeper_mode: 3})).to have_been_made
    end

    it "rejects a mode the API does not define" do
      expect { client.set_climate_keeper_mode(TEST_VIN, :cat) }
        .to raise_error(ArgumentError, "Unknown climate keeper mode: cat. The climate keeper modes the API defines are: off, on, dog, camp")
    end
  end

  describe "#set_bioweapon_mode" do
    before { stub_command("set_bioweapon_mode") }

    it "sends the set_bioweapon_mode command with its defaults" do
      client.set_bioweapon_mode(TEST_VIN, on: true)

      expect(a_command("set_bioweapon_mode").with(body: {on: true, manual_override: false})).to have_been_made
    end

    it "sends the set_bioweapon_mode command with the options given" do
      client.set_bioweapon_mode(TEST_VIN, on: true, manual_override: true)

      expect(a_command("set_bioweapon_mode").with(body: {on: true, manual_override: true})).to have_been_made
    end
  end

  describe "#set_cabin_overheat_protection" do
    before { stub_command("set_cabin_overheat_protection") }

    it "sends the set_cabin_overheat_protection command with its defaults" do
      client.set_cabin_overheat_protection(TEST_VIN, on: true)

      expect(a_command("set_cabin_overheat_protection").with(body: {on: true, fan_only: false})).to have_been_made
    end

    it "sends the set_cabin_overheat_protection command with the options given" do
      client.set_cabin_overheat_protection(TEST_VIN, on: true, fan_only: true)

      expect(a_command("set_cabin_overheat_protection").with(body: {on: true, fan_only: true})).to have_been_made
    end
  end
end
