require_relative '../asari_spec_helper'

describe Asari do
  describe Asari::Collection do
    before :each do  
      response = OpenStruct.new(:parsed_response => { "hits" => { "found" => 10, "start" => 0, "hit" => ["1","2"]}})
      @collection = Asari::Collection.new(response, 2)
    end

    it "calculates the page_size correctly" do
      expect(@collection.page_size).to eq(2)
    end

    it "calculates the total_entries correctly" do
      expect(@collection.total_entries).to eq(10)
    end

    it "calculates the total_pages correctly" do
      expect(@collection.total_pages).to eq(5)
    end

    it "calculates the current_page correctly" do
      expect(@collection.current_page).to eq(1)
    end

    it "calculates the offset correctly" do
      expect(@collection.offset).to eq(0)
    end
  end
end
