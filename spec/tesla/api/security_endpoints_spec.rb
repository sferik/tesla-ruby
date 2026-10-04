# frozen_string_literal: true

RSpec.describe Tesla::API::SecurityEndpoints do
  let(:client) { Tesla::Client.new(access_token: TEST_ACCESS_TOKEN) }

  describe "#set_sentry_mode" do
    before { stub_command("set_sentry_mode") }

    it "sends the set_sentry_mode command" do
      client.set_sentry_mode(TEST_VIN, on: true)

      expect(a_command("set_sentry_mode").with(body: {on: true})).to have_been_made
    end
  end

  describe "#set_valet_mode" do
    before { stub_command("set_valet_mode") }

    it "sends the set_valet_mode command with its defaults" do
      client.set_valet_mode(TEST_VIN, on: true)

      expect(a_command("set_valet_mode").with(body: {on: true})).to have_been_made
    end

    it "sends the set_valet_mode command with the options given" do
      client.set_valet_mode(TEST_VIN, on: true, password: "1234")

      expect(a_command("set_valet_mode").with(body: {on: true, password: "1234"})).to have_been_made
    end
  end

  describe "#reset_valet_pin" do
    before { stub_command("reset_valet_pin") }

    it "sends the reset_valet_pin command" do
      client.reset_valet_pin(TEST_VIN)

      expect(a_command("reset_valet_pin").with(body: {})).to have_been_made
    end
  end

  describe "#remote_start" do
    before { stub_command("remote_start_drive") }

    it "sends the remote_start_drive command" do
      client.remote_start(TEST_VIN)

      expect(a_command("remote_start_drive").with(body: {})).to have_been_made
    end
  end

  describe "#set_speed_limit" do
    before { stub_command("speed_limit_set_limit") }

    it "sends the speed_limit_set_limit command" do
      client.set_speed_limit(TEST_VIN, 65)

      expect(a_command("speed_limit_set_limit").with(body: {limit_mph: 65})).to have_been_made
    end
  end

  describe "#activate_speed_limit" do
    before { stub_command("speed_limit_activate") }

    it "sends the speed_limit_activate command" do
      client.activate_speed_limit(TEST_VIN, "1234")

      expect(a_command("speed_limit_activate").with(body: {pin: "1234"})).to have_been_made
    end
  end

  describe "#deactivate_speed_limit" do
    before { stub_command("speed_limit_deactivate") }

    it "sends the speed_limit_deactivate command" do
      client.deactivate_speed_limit(TEST_VIN, "1234")

      expect(a_command("speed_limit_deactivate").with(body: {pin: "1234"})).to have_been_made
    end
  end

  describe "#clear_speed_limit_pin" do
    before { stub_command("speed_limit_clear_pin") }

    it "sends the speed_limit_clear_pin command" do
      client.clear_speed_limit_pin(TEST_VIN, "1234")

      expect(a_command("speed_limit_clear_pin").with(body: {pin: "1234"})).to have_been_made
    end
  end
end
