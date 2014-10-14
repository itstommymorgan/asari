require_relative "../spec_helper"

describe Asari do
  before :each do
    @asari = Asari.new("testdomain")
    stub_const("HTTParty", double())
    allow(HTTParty).to receive(:get).and_return(fake_response)
  end

  describe "searching" do
    context "when region is not specified" do
      it "allows you to search using default region." do
        expect(HTTParty).to receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=10")
        @asari.search("testsearch")
      end
    end

    context "when region is not specified" do
      before(:each) do
        @asari.aws_region = 'my-region'
      end
      it "allows you to search using specified region." do
        expect(HTTParty).to receive(:get).with("http://search-testdomain.my-region.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=10")
        @asari.search("testsearch")
      end
    end

    it "escapes dangerous characters in search terms." do
      expect(HTTParty).to receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch%21&size=10")
      @asari.search("testsearch!")
    end

    it "honors the page_size option" do
      expect(HTTParty).to receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=20")
      @asari.search("testsearch", :page_size => 20)
    end

    it "honors the page option" do
      expect(HTTParty).to receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=20&start=40")
      @asari.search("testsearch", :page_size => 20, :page => 3)
    end

    describe "the rank option" do
      it "takes a plain string" do
        expect(HTTParty).to receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=10&rank=some_field")
        @asari.search("testsearch", :rank => "some_field")
      end

      it "takes an array with :asc" do
        expect(HTTParty).to receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=10&rank=some_field")
        @asari.search("testsearch", :rank => ["some_field", :asc])
      end

      it "takes an array with :desc" do
        expect(HTTParty).to receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=10&rank=-some_field")
        @asari.search("testsearch", :rank => ["some_field", :desc])
      end
    end

    it "returns a list of document IDs for search results." do
      result = @asari.search("testsearch")

      expect(result.size).to eq(2)
      expect(result[0]).to eq("123")
      expect(result[1]).to eq("456")
      expect(result.total_pages).to eq(1)
      expect(result.current_page).to eq(1)
      expect(result.page_size).to eq(10)
      expect(result.total_entries).to eq(2)
    end

    it "returns an empty list when no search results are found." do
      allow(HTTParty).to receive(:get).and_return(fake_empty_response)
      result = @asari.search("testsearch")
      expect(result.size).to eq(0)
      expect(result.total_pages).to eq(1)
      expect(result.current_page).to eq(1)
      expect(result.total_entries).to eq(0)
    end

    context 'return_fields option' do
      let(:response_with_field_data) {  OpenStruct.new(:parsed_response => { "hits" => {
        "found" => 2,
        "start" => 0,
        "hit" => [{"id" => "123",
          "data" => {"name" => "Beavis", "address" => "arizona"}},
          {"id" => "456",
            "data" => {"name" => "Honey Badger", "address" => "africa"}}]}},
            :response => OpenStruct.new(:code => "200"))
      }
      let(:return_struct) {{"123" => {"name" => "Beavis", "address" => "arizona"},
                           "456" => {"name" => "Honey Badger", "address" => "africa"}}}

      before :each do
        expect(HTTParty).to receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=10&return-fields=name,address").and_return response_with_field_data
      end

      subject { @asari.search("testsearch", :return_fields => [:name, :address])}
      it {should eql return_struct}
    end

    it "raises an exception if the service errors out." do
      allow(HTTParty).to receive(:get).and_return(fake_error_response)
      expect { @asari.search("testsearch)") }.to raise_error Asari::SearchException
    end

    it "raises an exception if there are internet issues." do
      allow(HTTParty).to receive(:get).and_raise(SocketError.new)
      expect { @asari.search("testsearch)") }.to raise_error Asari::SearchException
    end

  end

  describe "boolean searching" do
    it "builds a query string from a passed hash" do
      expect(HTTParty).to receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=&bq=+%28and+foo%3A%27bar%27+baz%3A%27bug%27%29&size=10")
      @asari.search(filter: { and: { foo: "bar", baz: "bug" }})
    end

    it "honors the logic types" do
      expect(HTTParty).to receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=&bq=+%28or+foo%3A%27bar%27+baz%3A%27bug%27%29&size=10")
      @asari.search(filter: { or: { foo: "bar", baz: "bug" }})
    end

    it "supports nested logic" do
      expect(HTTParty).to receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=&bq=+%28or+is_donut%3A%27true%27+%28and+round%3A%27true%27+frosting%3A%27true%27+fried%3A%27true%27%29%29&size=10")
      @asari.search(filter: { or: { is_donut: true, and:
                            { round: true, frosting: true, fried: true }}
      })
    end

    it "fails gracefully with empty params" do
      expect(HTTParty).to receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=&bq=+%28or+is_donut%3A%27true%27%29&size=10")
      @asari.search(filter: { or: { is_donut: true, and:
                            { round: "", frosting: nil, fried: nil }}
      })
    end

    it "supports full text search and boolean searching" do
      expect(HTTParty).to receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=nom&bq=+%28or+is_donut%3A%27true%27+%28and+fried%3A%27true%27%29%29&size=10")
      @asari.search("nom", filter: { or: { is_donut: true, and:
                                   { round: "", frosting: nil, fried: true }}
      })
    end
  end

  describe "geography searching" do
    it "builds a proper query string" do
      expect(HTTParty).to receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=&bq=+%28and+lat%3A2505771415..2506771417+lng%3A2358260777..2359261578%29&size=10")
      @asari.search filter: { and: Asari::Geography.coordinate_box(meters: 5000, lat: 45.52, lng: 122.6819) }
    end
  end

  describe "facet information" do
    it "builds a proper query string" do
      expect(HTTParty).to receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=test-query&facet=test_facet&size=10")
      @asari.search 'test-query', facet: 'test_facet'
    end
  end
end
