# frozen_string_literal: true

RSpec.describe Tesla::API::SoftwareEndpoints do
  let(:client) { Tesla::Client.new(access_token: TEST_ACCESS_TOKEN) }

  describe "#schedule_software_update" do
    before { stub_command("schedule_software_update") }

    it "sends the schedule_software_update command with its defaults" do
      client.schedule_software_update(TEST_VIN)

      expect(a_command("schedule_software_update").with(body: {offset_sec: 0})).to have_been_made
    end

    it "sends the schedule_software_update command with the options given" do
      client.schedule_software_update(TEST_VIN, offset: 7200)

      expect(a_command("schedule_software_update").with(body: {offset_sec: 7200})).to have_been_made
    end
  end

  describe "#cancel_software_update" do
    before { stub_command("cancel_software_update") }

    it "sends the cancel_software_update command" do
      client.cancel_software_update(TEST_VIN)

      expect(a_command("cancel_software_update").with(body: {})).to have_been_made
    end
  end
end
