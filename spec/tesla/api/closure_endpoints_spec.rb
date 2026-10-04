# frozen_string_literal: true

RSpec.describe Tesla::API::ClosureEndpoints do
  let(:client) { Tesla::Client.new(access_token: TEST_ACCESS_TOKEN) }

  describe "#lock_doors" do
    before { stub_command("door_lock") }

    it "sends the door_lock command" do
      client.lock_doors(TEST_VIN)

      expect(a_command("door_lock").with(body: {})).to have_been_made
    end
  end

  describe "#unlock_doors" do
    before { stub_command("door_unlock") }

    it "sends the door_unlock command" do
      client.unlock_doors(TEST_VIN)

      expect(a_command("door_unlock").with(body: {})).to have_been_made
    end
  end

  describe "#actuate_trunk" do
    before { stub_command("actuate_trunk") }

    it "sends the actuate_trunk command" do
      client.actuate_trunk(TEST_VIN)

      expect(a_command("actuate_trunk").with(body: {which_trunk: "rear"})).to have_been_made
    end
  end

  describe "#open_frunk" do
    before { stub_command("actuate_trunk") }

    it "sends the actuate_trunk command" do
      client.open_frunk(TEST_VIN)

      expect(a_command("actuate_trunk").with(body: {which_trunk: "front"})).to have_been_made
    end
  end

  describe "#vent_windows" do
    before { stub_command("window_control") }

    it "sends the window_control command" do
      client.vent_windows(TEST_VIN)

      expect(a_command("window_control").with(body: {command: "vent", lat: 0, lon: 0})).to have_been_made
    end
  end

  describe "#close_windows" do
    before { stub_command("window_control") }

    it "sends the window_control command with its defaults" do
      client.close_windows(TEST_VIN)

      expect(a_command("window_control").with(body: {command: "close", lat: 0, lon: 0})).to have_been_made
    end

    it "sends the window_control command with the options given" do
      client.close_windows(TEST_VIN, latitude: 37.4929, longitude: -121.9453)

      expect(a_command("window_control").with(body: {command: "close", lat: 37.4929, lon: -121.9453})).to have_been_made
    end
  end

  describe "#vent_sunroof" do
    before { stub_command("sun_roof_control") }

    it "sends the sun_roof_control command" do
      client.vent_sunroof(TEST_VIN)

      expect(a_command("sun_roof_control").with(body: {state: "vent"})).to have_been_made
    end
  end

  describe "#close_sunroof" do
    before { stub_command("sun_roof_control") }

    it "sends the sun_roof_control command" do
      client.close_sunroof(TEST_VIN)

      expect(a_command("sun_roof_control").with(body: {state: "close"})).to have_been_made
    end
  end

  describe "#trigger_homelink" do
    before { stub_command("trigger_homelink") }

    it "sends the trigger_homelink command" do
      client.trigger_homelink(TEST_VIN, latitude: 37.4929, longitude: -121.9453)

      expect(a_command("trigger_homelink").with(body: {lat: 37.4929, lon: -121.9453})).to have_been_made
    end
  end
end
