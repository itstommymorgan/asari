require_relative '../spec_helper'

describe "Asari" do
  before :each do
    # reset defaults
    Asari.search_domain = nil
    Asari.api_version = nil
  end

  describe "configuration" do
    it "defaults to the first CloudSearch API version." do
      expect(Asari.api_version).to eq "2011-02-01"
    end

    it "allows you to set a specific API version." do
      Asari.api_version = "2015-10-21" # WE'VE GOT TO GO BACK
      expect(Asari.api_version).to eq "2015-10-21"
    end

    it "raises an exeception if no search domain is provided." do
      expect { Asari.search_domain }.to raise_error Asari::MissingSearchDomainException
    end

    it "allows you to set a search domain." do
      Asari.search_domain = "theroyaldomainofawesome"
      expect(Asari.search_domain).to eq "theroyaldomainofawesome"
    end
  end

end
