# frozen_string_literal: true

RSpec.describe Tesla::API::NavigationEndpoints do
  let(:client) { Tesla::Client.new(access_token: TEST_ACCESS_TOKEN) }

  describe "#navigate_to" do
    before do
      stub_command("navigation_request")
      allow(Process).to receive(:clock_gettime).and_call_original
      allow(Process).to receive(:clock_gettime).with(Process::CLOCK_REALTIME, :millisecond).and_return(1_539_465_730_000)
    end

    it "sends the navigation_request command with the destination, as the Tesla app shares one" do
      client.navigate_to(TEST_VIN, "3500 Deer Creek Road, Palo Alto, CA")

      expect(a_command("navigation_request").with(body: {type: "share_ext_content_raw", locale: "en-US",
                                                         timestamp_ms: 1_539_465_730_000,
                                                         value: {"android.intent.extra.TEXT" => "3500 Deer Creek Road, Palo Alto, CA"}}))
        .to have_been_made
    end

    it "sends the locale it is given" do
      client.navigate_to(TEST_VIN, "Tesla Gigafactory Berlin-Brandenburg", locale: "de-DE")

      expect(a_command("navigation_request").with(body: hash_including(locale: "de-DE"))).to have_been_made
    end
  end

  describe "#navigate_to_coordinates" do
    before { stub_command("navigation_gps_request") }

    it "sends the navigation_gps_request command with the position" do
      client.navigate_to_coordinates(TEST_VIN, 37.3947, -122.1503)

      expect(a_command("navigation_gps_request").with(body: {lat: 37.3947, lon: -122.1503, order: 1})).to have_been_made
    end

    it "sends the order it is given" do
      client.navigate_to_coordinates(TEST_VIN, 37.3947, -122.1503, order: 2)

      expect(a_command("navigation_gps_request").with(body: {lat: 37.3947, lon: -122.1503, order: 2})).to have_been_made
    end
  end
end
