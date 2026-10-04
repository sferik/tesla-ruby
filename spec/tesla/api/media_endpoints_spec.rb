# frozen_string_literal: true

RSpec.describe Tesla::API::MediaEndpoints do
  let(:client) { Tesla::Client.new(access_token: TEST_ACCESS_TOKEN) }

  describe "#toggle_playback" do
    before { stub_command("media_toggle_playback") }

    it "sends the media_toggle_playback command" do
      client.toggle_playback(TEST_VIN)

      expect(a_command("media_toggle_playback").with(body: {})).to have_been_made
    end
  end

  describe "#next_track" do
    before { stub_command("media_next_track") }

    it "sends the media_next_track command" do
      client.next_track(TEST_VIN)

      expect(a_command("media_next_track").with(body: {})).to have_been_made
    end
  end

  describe "#previous_track" do
    before { stub_command("media_prev_track") }

    it "sends the media_prev_track command" do
      client.previous_track(TEST_VIN)

      expect(a_command("media_prev_track").with(body: {})).to have_been_made
    end
  end

  describe "#next_favorite" do
    before { stub_command("media_next_fav") }

    it "sends the media_next_fav command" do
      client.next_favorite(TEST_VIN)

      expect(a_command("media_next_fav").with(body: {})).to have_been_made
    end
  end

  describe "#previous_favorite" do
    before { stub_command("media_prev_fav") }

    it "sends the media_prev_fav command" do
      client.previous_favorite(TEST_VIN)

      expect(a_command("media_prev_fav").with(body: {})).to have_been_made
    end
  end

  describe "#volume_up" do
    before { stub_command("media_volume_up") }

    it "sends the media_volume_up command" do
      client.volume_up(TEST_VIN)

      expect(a_command("media_volume_up").with(body: {})).to have_been_made
    end
  end

  describe "#volume_down" do
    before { stub_command("media_volume_down") }

    it "sends the media_volume_down command" do
      client.volume_down(TEST_VIN)

      expect(a_command("media_volume_down").with(body: {})).to have_been_made
    end
  end

  describe "#set_volume" do
    before { stub_command("adjust_volume") }

    it "sends the adjust_volume command" do
      client.set_volume(TEST_VIN, 4.5)

      expect(a_command("adjust_volume").with(body: {volume: 4.5})).to have_been_made
    end
  end
end
