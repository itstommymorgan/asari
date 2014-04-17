require_relative "../asari_spec_helper"

describe Asari::Geography do

  let(:convert) { Asari::Geography }

  describe "#degrees_to_int" do
    it "converts standard lat and lng to integers" do
      result = convert.degrees_to_int(lat: 45.52, lng: 122.68)
      expect(result).to eq({ lat: 2506271416, lng: 2356862483 })
    end
  end

  describe "#int_to_degrees" do
    it "converts back successfully" do
      integers = convert.degrees_to_int(lat: -45.52, lng: 122.68)
      result = convert.int_to_degrees(integers)
      expect(result).to eq({ lat: -45.52, lng: 122.68 })
    end
  end

  describe "#coordinate_box" do
    it "creates a range from a coordinate and a distance in meters" do
      result = convert.coordinate_box(lat: 45.52, lng: 122.682, meters: 5000)
      expect(result).to eq({
        lat: 2505771415..2506771417,
        lng: 2358261557..2359262357
      })
    end
  end
end
