require_relative "../spec_helper"

describe Asari do
  describe "searching" do
    before :each do
      @asari = Asari.new("testdomain")
      stub_const("HTTParty", double())
      HTTParty.stub(:get).and_return(fake_response)
    end

    context "when region is not specified" do
      it "allows you to search using default region." do
        HTTParty.should_receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=10")
        @asari.search("testsearch")
      end
    end

    context "when region is not specified" do
      before(:each) do
        @asari.aws_region = 'my-region'
      end
      it "allows you to search using specified region." do
        HTTParty.should_receive(:get).with("http://search-testdomain.my-region.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=10")
        @asari.search("testsearch")
      end
    end

    it "escapes dangerous characters in search terms." do
      HTTParty.should_receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch%21&size=10")
      @asari.search("testsearch!")
    end

    it "honors the page_size option" do
      HTTParty.should_receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=20")
      @asari.search("testsearch", :page_size => 20)
    end

    it "honors the page option" do
      HTTParty.should_receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=20&start=40")
      @asari.search("testsearch", :page_size => 20, :page => 3)
    end

    describe "the rank option" do
      it "takes a plain string" do
        HTTParty.should_receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=10&rank=some_field")
        @asari.search("testsearch", :rank => "some_field")
      end

      it "takes an array with :asc" do
        HTTParty.should_receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=10&rank=some_field")
        @asari.search("testsearch", :rank => ["some_field", :asc])
      end

      it "takes an array with :desc" do
        HTTParty.should_receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=10&rank=-some_field")
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
      HTTParty.stub(:get).and_return(fake_empty_response)
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
        HTTParty.should_receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=10&return-fields=name,address").and_return response_with_field_data
      end

      subject { @asari.search("testsearch", :return_fields => [:name, :address])}
      it {should eql return_struct}
    end 

    it "raises an exception if the service errors out." do
      HTTParty.stub(:get).and_return(fake_error_response)
      expect { @asari.search("testsearch)") }.to raise_error Asari::SearchException
    end

    it "raises an exception if there are internet issues." do
      HTTParty.stub(:get).and_raise(SocketError.new)
      expect { @asari.search("testsearch)") }.to raise_error Asari::SearchException
    end

  end

end
