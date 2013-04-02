require_relative "../spec_helper"

describe Asari do
  describe "searching" do
    before :each do
      @asari = Asari.new("testdomain")
      stub_const("HTTParty", double())
      HTTParty.stub(:get).and_return(fake_response)
    end

    it "allows you to search." do
      HTTParty.should_receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=10")
      @asari.search("testsearch")
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
        @asari.search("testsearch", rank: "some_field")
      end

      it "takes an array with :asc" do
        HTTParty.should_receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=10&rank=some_field")
        @asari.search("testsearch", rank: ["some_field", :asc])
      end

      it "takes an array with :desc" do
        HTTParty.should_receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=10&rank=-some_field")
        @asari.search("testsearch", rank: ["some_field", :desc])
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
