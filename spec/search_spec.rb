require_relative "../spec_helper"

describe Asari do
  describe "searching" do
    before :each do
      @asari = Asari.new("testdomain")
      stub_const("HTTParty", double())
      HTTParty.stub(:get).and_return(fake_response)
    end

    it "allows you to search." do
      HTTParty.should_receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch")
      @asari.search("testsearch")
    end

    it "escapes dangerous characters in search terms." do
      HTTParty.should_receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch%21")
      @asari.search("testsearch!")
    end

    it "honors the page_size option" do
      HTTParty.should_receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=20")
      @asari.search("testsearch", :page_size => 20)
    end

    it "honors the page option" do
      HTTParty.should_receive(:get).with("http://search-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/search?q=testsearch&size=20&start=41")
      @asari.search("testsearch", :page_size => 20, :page => 3)
    end

    it "returns a list of document IDs for search results." do
      expect(@asari.search("testsearch")).to eq(["123","456"])
    end

    it "returns an empty list when no search results are found." do
      HTTParty.stub(:get).and_return(fake_empty_response)
      expect(@asari.search("testsearch")).to eq([])
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
