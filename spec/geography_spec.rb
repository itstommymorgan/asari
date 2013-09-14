require_relative "../spec_helper"

describe Asari::Geography do

  let(:convert) { Asari::Geography }

  describe "#degrees_to_int" do
    it "converts standard lat and lng to integers" do
      result = convert.degrees_to_int(lat: 45.52, lng: 122.682)
      expect(result).to eq({ lat: 25062714160, lng: 1112993834 })
    end
  end

  describe "#int_to_degrees" do
    it "converts back successfully" do
      integers = convert.degrees_to_int(lat: -45.52, lng: 122.682)
      result = convert.int_to_degrees(integers)
      expect(result).to eq({ lat: -45.52, lng: 122.682 })
    end
  end

  describe "#coordinate_box" do
    it "creates a range from a coordinate and a distance in miles" do
      result = convert.coordinate_box(lat: 45.52, lng: 122.682, meters: 5000)
      expect(result).to eq({
        lat: 25057714154..25067714166,
        lng: 1112757718..1113229951
      })
    end
  end
end
