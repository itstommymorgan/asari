require_relative '../asari_spec_helper'

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

    it "allows you to set a specific API version via a constant." do
      ENV['CLOUDSEARCH_API_VERSION'] = '2013-01-01'
      expect(@asari.api_version).to eq "2013-01-01"
      ENV['CLOUDSEARCH_API_VERSION'] = nil
    end

    it "allows you to set a specific aws region." do
      @asari.aws_region = "us-west-1"
      expect(@asari.aws_region).to eq("us-west-1")
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
