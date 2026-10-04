# frozen_string_literal: true

RSpec.describe Tesla::API::AlertEndpoints do
  let(:client) { Tesla::Client.new(access_token: TEST_ACCESS_TOKEN) }

  describe "#honk_horn" do
    before { stub_command("honk_horn") }

    it "sends the honk_horn command" do
      client.honk_horn(TEST_VIN)

      expect(a_command("honk_horn").with(body: {})).to have_been_made
    end
  end

  describe "#flash_lights" do
    before { stub_command("flash_lights") }

    it "sends the flash_lights command" do
      client.flash_lights(TEST_VIN)

      expect(a_command("flash_lights").with(body: {})).to have_been_made
    end
  end
end
