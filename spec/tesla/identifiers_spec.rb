# frozen_string_literal: true

RSpec.describe Tesla::Identifiers do
  subject(:identifiers) { Class.new { include Tesla::Identifiers }.new }

  describe "#tag_of" do
    it "is the VIN it is given" do
      expect(identifiers.send(:tag_of, TEST_VIN)).to eq(TEST_VIN)
    end

    it "is the ID it is given" do
      expect(identifiers.send(:tag_of, 12_345_678_901_234_567)).to eq(12_345_678_901_234_567)
    end

    it "is the VIN of a vehicle" do
      expect(identifiers.send(:tag_of, Tesla::Vehicle.new("vin" => TEST_VIN, "id" => 1))).to eq(TEST_VIN)
    end

    it "is the ID of a vehicle without a VIN" do
      expect(identifiers.send(:tag_of, Tesla::Vehicle.new("id" => 1))).to eq(1)
    end

    it "is the VIN of the data of a vehicle" do
      expect(identifiers.send(:tag_of, Tesla::VehicleData.new("vin" => TEST_VIN))).to eq(TEST_VIN)
    end

    it "is private" do
      expect(identifiers.private_methods).to include(:tag_of)
    end
  end
end
