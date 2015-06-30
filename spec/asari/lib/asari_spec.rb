require_relative '../asari_spec_helper'

describe "Asari" do
  let(:api_version) { nil }
  let(:aws_region) { nil }
  let(:search_domain) { nil }

  before { @asari = Asari.new(search_domain, aws_region, api_version) }

  describe "configuration" do
    it "defaults to the first CloudSearch API version." do
      expect(@asari.api_version).to eq "2011-02-01"
    end

    it "allows you to set a specific API version." do
      @asari.api_version = "2015-10-21"
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

    context "allows you to set search_domain via parameter" do
      let(:search_domain) { "ultimatedomain" }
      it { expect(@asari.search_domain).to eq(search_domain) }

      context "allows you to set aws_region via parameter" do
        let(:aws_region) { "eu-east-1" }
        it { expect(@asari.aws_region).to eq(aws_region) }

        context "allows you to set api_version via parameter" do
          let(:api_version) { "2014-01-01" }
          it { expect(@asari.api_version).to eq(api_version) }
        end
      end
    end
  end
end
