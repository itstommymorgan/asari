require_relative '../spec_helper'

describe "Asari" do
  before :each do
    @asari = Asari.new
  end

  describe "configuration" do
    it "defaults to the first CloudSearch API version." do
      expect(@asari.api_version).to eq "2011-02-01"
    end

    it "allows you to set a specific API version." do
      @asari.api_version = "2015-10-21" # WE'VE GOT TO GO BACK
      expect(@asari.api_version).to eq "2015-10-21"
    end

    it "allows you to set a specific aws region." do
      @asari.aws_region = "us-west-1"
      expect(@asari.aws_region).to eq("us-west-1")
    end

    describe "initialize using hash" do
      it "sets search_domain" do
        @asari = Asari.new(search_domain: "test_search_domain")
        expect(@asari.search_domain).to eq("test_search_domain")
      end
      it "sets aws_url" do
        @asari = Asari.new(search_domain: "test_search_domain", aws_url: "localhost")
        expect(@asari.search_url).to eq("http://search-test_search_domain.us-east-1.localhost/2011-02-01/search")
      end
    end

    it "raises an exeception if no search domain is provided." do
      expect { @asari.search_domain }.to raise_error Asari::MissingSearchDomainException
    end

    it "allows you to set a search domain." do
      @asari.search_domain = "theroyaldomainofawesome"
      expect(@asari.search_domain).to eq "theroyaldomainofawesome"
    end
  end

end
