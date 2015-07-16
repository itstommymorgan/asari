require_relative '../asari_spec_helper'

describe Asari do
  describe Asari::Collection do
    let(:facets) do
      { "facet_group" => { "buckets" => [{ "value" => "facet1", "count" => "1" }] } }
    end
    before :each do
      response = OpenStruct.new(:parsed_response => {
        "hits" => { "found" => 10, "start" => 0, "hit" => [{ "id" => "1" }, { "id" => "2" }] },
        "facets" => facets
      })
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

    it "correctly parses response" do
      expect(@collection.size).to eq(2)
      expect(@collection.first.class).to eq(String)
      expect(@collection.first).to eq("1")
    end

    context "parse facets" do
      it "correctly parses facets" do
        expect(@collection.facets.class).to eq(Hash)
        expect(@collection.facets).to eq(facets)
      end

      context "when factes are not present" do
        let(:facets) { nil }

        it "correctly parses facets" do
          expect(@collection.facets).to be_nil
        end
      end
    end
  end
end
