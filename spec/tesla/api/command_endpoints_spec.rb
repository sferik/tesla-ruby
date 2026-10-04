# frozen_string_literal: true

RSpec.describe Tesla::API::CommandEndpoints do
  let(:client) { Tesla::Client.new(access_token: TEST_ACCESS_TOKEN) }

  describe "#command" do
    before { stub_command("set_vehicle_name") }

    it "posts the command to the vehicle" do
      client.command(TEST_VIN, "set_vehicle_name")

      expect(a_command("set_vehicle_name")).to have_been_made
    end

    it "takes the name of the command as a Symbol" do
      client.command(TEST_VIN, :set_vehicle_name)

      expect(a_command("set_vehicle_name")).to have_been_made
    end

    it "accepts a vehicle" do
      client.command(Tesla::Vehicle.new("vin" => TEST_VIN), "set_vehicle_name")

      expect(a_command("set_vehicle_name")).to have_been_made
    end

    it "posts the parameters of the command as JSON" do
      client.command(TEST_VIN, "set_vehicle_name", vehicle_name: "Nikola 2.0")

      expect(a_command("set_vehicle_name").with(body: '{"vehicle_name":"Nikola 2.0"}')).to have_been_made
    end

    it "posts an empty JSON object for a command without parameters" do
      client.command(TEST_VIN, "set_vehicle_name")

      expect(a_command("set_vehicle_name").with(body: "{}")).to have_been_made
    end

    it "escapes the vehicle tag" do
      stub_post("/api/1/vehicles/..%2F#{TEST_VIN}/command/set_vehicle_name").to_return(body: '{"response":{"result":true}}')
      client.command("../#{TEST_VIN}", "set_vehicle_name")

      expect(a_post("/api/1/vehicles/..%2F#{TEST_VIN}/command/set_vehicle_name")).to have_been_made
    end

    it "escapes the name of the command" do
      stub_post("/api/1/vehicles/#{TEST_VIN}/command/..%2Fwake_up").to_return(body: '{"response":{"result":true}}')
      client.command(TEST_VIN, "../wake_up")

      expect(a_post("/api/1/vehicles/#{TEST_VIN}/command/..%2Fwake_up")).to have_been_made
    end

    it "returns true once the vehicle has carried out the command" do
      expect(client.command(TEST_VIN, "set_vehicle_name")).to be(true)
    end

    it "returns true for a response that carries no reason" do
      stub_command("honk_horn").to_return(body: '{"response":{"result":true}}')

      expect(client.command(TEST_VIN, "honk_horn")).to be(true)
    end

    it "raises CommandFailed when the vehicle did not carry out the command" do
      stub_command("charge_start", result: false, reason: "disconnected")

      expect { client.command(TEST_VIN, :charge_start) }
        .to raise_error(Tesla::CommandFailed, "The vehicle did not carry out charge_start: disconnected")
    end

    it "attaches the command, as a String, and the reason to the error" do
      stub_command("charge_start", result: false, reason: "disconnected")

      expect { client.command(TEST_VIN, :charge_start) }
        .to raise_error(having_attributes(command: "charge_start", reason: "disconnected"))
    end

    it "raises InvalidResponse for a response that does not say whether the vehicle carried out the command" do
      stub_post("/api/1/vehicles/#{TEST_VIN}/command/honk_horn").to_return(body: '{"response":{}}')

      expect { client.command(TEST_VIN, "honk_horn") }
        .to raise_error(Tesla::InvalidResponse, 'The response body is not the expected JSON: key not found: "result"')
    end

    it "raises the error of the status when the vehicle is asleep" do
      stub_post("/api/1/vehicles/#{TEST_VIN}/command/honk_horn").to_return(status: 408)

      expect { client.command(TEST_VIN, "honk_horn") }.to raise_error(Tesla::RequestTimeout)
    end
  end

  describe "#number_of" do
    let(:options) { {off: 0, on: 1} }

    it "is the number of an option named with a Symbol" do
      expect(client.send(:number_of, options, :on, "mode")).to eq(1)
    end

    it "is the number of an option named with a String" do
      expect(client.send(:number_of, options, "off", "mode")).to eq(0)
    end

    it "raises for a name that is not one of the options" do
      expect { client.send(:number_of, options, :auto, "mode") }
        .to raise_error(ArgumentError, "Unknown mode: auto. The modes the API defines are: off, on")
    end
  end
end
