# frozen_string_literal: true

RSpec.describe Tesla::API::ChargingEndpoints do
  let(:client) { Tesla::Client.new(access_token: TEST_ACCESS_TOKEN) }

  describe "#open_charge_port" do
    before { stub_command("charge_port_door_open") }

    it "sends the charge_port_door_open command" do
      client.open_charge_port(TEST_VIN)

      expect(a_command("charge_port_door_open").with(body: {})).to have_been_made
    end
  end

  describe "#close_charge_port" do
    before { stub_command("charge_port_door_close") }

    it "sends the charge_port_door_close command" do
      client.close_charge_port(TEST_VIN)

      expect(a_command("charge_port_door_close").with(body: {})).to have_been_made
    end
  end

  describe "#start_charging" do
    before { stub_command("charge_start") }

    it "sends the charge_start command" do
      client.start_charging(TEST_VIN)

      expect(a_command("charge_start").with(body: {})).to have_been_made
    end
  end

  describe "#stop_charging" do
    before { stub_command("charge_stop") }

    it "sends the charge_stop command" do
      client.stop_charging(TEST_VIN)

      expect(a_command("charge_stop").with(body: {})).to have_been_made
    end
  end

  describe "#set_charge_limit" do
    before { stub_command("set_charge_limit") }

    it "sends the set_charge_limit command" do
      client.set_charge_limit(TEST_VIN, 80)

      expect(a_command("set_charge_limit").with(body: {percent: 80})).to have_been_made
    end
  end

  describe "#set_charging_amps" do
    before { stub_command("set_charging_amps") }

    it "sends the set_charging_amps command" do
      client.set_charging_amps(TEST_VIN, 32)

      expect(a_command("set_charging_amps").with(body: {charging_amps: 32})).to have_been_made
    end
  end

  describe "#charge_to_standard_range" do
    before { stub_command("charge_standard") }

    it "sends the charge_standard command" do
      client.charge_to_standard_range(TEST_VIN)

      expect(a_command("charge_standard").with(body: {})).to have_been_made
    end
  end

  describe "#charge_to_max_range" do
    before { stub_command("charge_max_range") }

    it "sends the charge_max_range command" do
      client.charge_to_max_range(TEST_VIN)

      expect(a_command("charge_max_range").with(body: {})).to have_been_made
    end
  end
end
