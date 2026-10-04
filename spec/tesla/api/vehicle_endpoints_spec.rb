# frozen_string_literal: true

RSpec.describe Tesla::API::VehicleEndpoints do
  let(:client) { Tesla::Client.new(access_token: TEST_ACCESS_TOKEN) }
  let(:vehicle) { Tesla::Vehicle.new("vin" => TEST_VIN) }

  describe "::DEFAULT_WAKE_INTERVAL" do
    it "is two seconds" do
      expect(described_class::DEFAULT_WAKE_INTERVAL).to eq(2)
    end
  end

  describe "#vehicles" do
    before { stub_get("/api/1/vehicles").with(query: hash_including({})).to_return(body: fixture("vehicles.json")) }

    it "gets the correct resource" do
      client.vehicles

      expect(a_get("/api/1/vehicles").with(query: {})).to have_been_made
    end

    it "gets the page it is asked for" do
      client.vehicles(page: 2, per_page: 10)

      expect(a_get("/api/1/vehicles?page=2&per_page=10")).to have_been_made
    end

    it "returns the vehicles" do
      expect(client.vehicles).to all(be_an_instance_of(Tesla::Vehicle)).and have_attributes(size: 1)
    end

    it "reads the attributes of a vehicle" do
      expect(client.vehicles.first).to have_attributes(vin: TEST_VIN, display_name: "Nikola 2.0", state: "online")
    end
  end

  describe "#vehicle" do
    before { stub_get("/api/1/vehicles/#{TEST_VIN}").to_return(body: fixture("vehicle.json")) }

    it "gets the correct resource" do
      client.vehicle(TEST_VIN)

      expect(a_get("/api/1/vehicles/#{TEST_VIN}")).to have_been_made
    end

    it "accepts a vehicle" do
      client.vehicle(vehicle)

      expect(a_get("/api/1/vehicles/#{TEST_VIN}")).to have_been_made
    end

    it "accepts the ID of a vehicle" do
      stub_get("/api/1/vehicles/12345678901234567").to_return(body: fixture("vehicle.json"))
      client.vehicle(12_345_678_901_234_567)

      expect(a_get("/api/1/vehicles/12345678901234567")).to have_been_made
    end

    it "escapes the vehicle tag" do
      stub_get("/api/1/vehicles/..%2Fusers").to_return(body: fixture("vehicle.json"))
      client.vehicle("../users")

      expect(a_get("/api/1/vehicles/..%2Fusers")).to have_been_made
    end

    it "returns the vehicle" do
      expect(client.vehicle(TEST_VIN)).to be_an_instance_of(Tesla::Vehicle).and have_attributes(vin: TEST_VIN)
    end
  end

  describe "#vehicle_data" do
    let(:path) { "/api/1/vehicles/#{TEST_VIN}/vehicle_data" }

    before { stub_get(path).with(query: hash_including({})).to_return(body: fixture("vehicle_data.json")) }

    it "gets the correct resource" do
      client.vehicle_data(TEST_VIN)

      expect(a_get(path).with(query: {})).to have_been_made
    end

    it "accepts a vehicle" do
      client.vehicle_data(vehicle)

      expect(a_get(path)).to have_been_made
    end

    it "asks for the states it is given, separated by semicolons" do
      client.vehicle_data(TEST_VIN, endpoints: %i[location_data drive_state])

      expect(a_get(path).with(query: {endpoints: "location_data;drive_state"})).to have_been_made
    end

    it "asks for a single state" do
      client.vehicle_data(TEST_VIN, endpoints: "charge_state")

      expect(a_get(path).with(query: {endpoints: "charge_state"})).to have_been_made
    end

    it "returns the data of the vehicle" do
      expect(client.vehicle_data(TEST_VIN)).to be_an_instance_of(Tesla::VehicleData)
        .and have_attributes(vin: TEST_VIN, charge_state: have_attributes(battery_level: 59))
    end
  end

  describe "#wake_up" do
    let(:path) { "/api/1/vehicles/#{TEST_VIN}/wake_up" }

    context "without a timeout" do
      before { stub_post(path).to_return(body: fixture("vehicle_asleep.json")) }

      it "posts to the correct resource" do
        client.wake_up(TEST_VIN)

        expect(a_post(path)).to have_been_made
      end

      it "accepts a vehicle" do
        client.wake_up(vehicle)

        expect(a_post(path)).to have_been_made
      end

      it "returns the vehicle as the Fleet API answered with it, which is seldom online yet" do
        expect(client.wake_up(TEST_VIN)).to be_an_instance_of(Tesla::Vehicle).and have_attributes(state: "asleep")
      end

      it "does not ask for the vehicle again" do
        client.wake_up(TEST_VIN)

        expect(a_get("/api/1/vehicles/#{TEST_VIN}")).not_to have_been_made
      end
    end

    context "with a timeout" do
      let(:waited) { [] }
      let(:clock) { [100.0, 100.0, 102.0, 104.0, 106.0] }

      before do
        allow(client).to receive(:sleep) { |seconds| waited << seconds }
        allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC) { clock.shift }
        stub_post(path).to_return(body: fixture("vehicle_asleep.json"))
        stub_get("/api/1/vehicles/#{TEST_VIN}")
          .to_return({body: fixture("vehicle_asleep.json")}, {body: fixture("vehicle.json")})
      end

      it "asks for the vehicle until it is online" do
        expect(client.wake_up(TEST_VIN, timeout: 60)).to have_attributes(state: "online")
      end

      it "wakes the vehicle once" do
        client.wake_up(TEST_VIN, timeout: 60)

        expect(a_post(path)).to have_been_made.once
      end

      it "asks for the vehicle no more than it takes" do
        client.wake_up(TEST_VIN, timeout: 60)

        expect(a_get("/api/1/vehicles/#{TEST_VIN}")).to have_been_made.twice
      end

      it "waits two seconds between the requests by default" do
        client.wake_up(TEST_VIN, timeout: 60)

        expect(waited).to eq([2, 2])
      end

      it "waits the interval it is given between the requests" do
        client.wake_up(TEST_VIN, timeout: 60, interval: 0.5)

        expect(waited).to eq([0.5, 0.5])
      end

      it "does not wait for a vehicle that is online when it is woken" do
        stub_post(path).to_return(body: fixture("vehicle.json"))
        client.wake_up(TEST_VIN, timeout: 60)

        expect(waited).to be_empty
      end

      it "raises VehicleAsleep when the vehicle is not online once the timeout is over" do
        expect { client.wake_up(TEST_VIN, timeout: 2) }
          .to raise_error(Tesla::VehicleAsleep, 'The vehicle is still "asleep" rather than online')
      end

      it "raises VehicleAsleep when the timeout was over before it was asked whether it is" do
        expect { client.wake_up(TEST_VIN, timeout: 1) }.to raise_error(Tesla::VehicleAsleep)
      end

      it "attaches the vehicle as the Fleet API last answered with it to the error" do
        expect { client.wake_up(TEST_VIN, timeout: 2) }
          .to raise_error(having_attributes(vehicle: an_instance_of(Tesla::Vehicle)))
      end

      it "asks for the vehicle until the timeout is over" do
        client.wake_up(TEST_VIN, timeout: 2)
      rescue Tesla::VehicleAsleep
        expect(a_get("/api/1/vehicles/#{TEST_VIN}")).to have_been_made.once
      end

      it "asks for the vehicle while the timeout is not yet over" do
        expect(client.wake_up(TEST_VIN, timeout: 4.5)).to have_attributes(state: "online")
      end

      it "gives up at once with a timeout of zero" do
        expect { client.wake_up(TEST_VIN, timeout: 0) }.to raise_error(Tesla::VehicleAsleep)
      end
    end
  end

  describe "#monotonic_time" do
    it "reads the monotonic clock" do
      expect(client.send(:monotonic_time)).to be_within(1).of(Process.clock_gettime(Process::CLOCK_MONOTONIC))
    end
  end

  describe "#nearby_charging_sites" do
    let(:path) { "/api/1/vehicles/#{TEST_VIN}/nearby_charging_sites" }

    before { stub_get(path).to_return(body: fixture("nearby_charging_sites.json")) }

    it "gets the correct resource" do
      client.nearby_charging_sites(TEST_VIN)

      expect(a_get(path)).to have_been_made
    end

    it "accepts a vehicle" do
      client.nearby_charging_sites(vehicle)

      expect(a_get(path)).to have_been_made
    end

    it "returns the charging sites" do
      expect(client.nearby_charging_sites(TEST_VIN)).to be_an_instance_of(Tesla::NearbyChargingSites)
        .and have_attributes(superchargers: have_attributes(size: 2))
    end
  end

  describe "#mobile_enabled?" do
    let(:path) { "/api/1/vehicles/#{TEST_VIN}/mobile_enabled" }

    it "gets the correct resource" do
      stub_get(path).to_return(body: '{"response":true}')
      client.mobile_enabled?(vehicle)

      expect(a_get(path)).to have_been_made
    end

    it "is true when mobile access is enabled" do
      stub_get(path).to_return(body: '{"response":true}')

      expect(client.mobile_enabled?(TEST_VIN)).to be(true)
    end

    it "is false when mobile access is disabled" do
      stub_get(path).to_return(body: '{"response":false}')

      expect(client.mobile_enabled?(TEST_VIN)).to be(false)
    end

    it "is false for a response that does not say" do
      stub_get(path).to_return(body: '{"response":"true"}')

      expect(client.mobile_enabled?(TEST_VIN)).to be(false)
    end
  end
end
