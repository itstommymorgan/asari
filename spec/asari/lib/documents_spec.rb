require_relative "../asari_spec_helper"

describe Asari do
  describe "updating the index" do
    before :each do
      @asari = Asari.new("testdomain")
      stub_const("HTTParty", double())
      HTTParty.stub(:post).and_return(fake_post_success)
      Time.should_receive(:now).and_return(1)
    end

    context "when region is not specified" do
      it "allows you to add an item to the index using default region." do
        HTTParty.should_receive(:post).with("http://doc-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/documents/batch", { :body => [{ "type" => "add", "id" => "1", "version" => 1, "lang" => "en", "fields" => { :name => "fritters"}}].to_json, :headers => { "Content-Type" => "application/json"}})

        expect(@asari.add_item("1", {:name => "fritters"})).to eq(nil)
      end
    end

    context "when region is specified" do
      before(:each) do
        @asari.aws_region = 'my-region'
      end
      it "allows you to add an item to the index using specified region." do
        HTTParty.should_receive(:post).with("http://doc-testdomain.my-region.cloudsearch.amazonaws.com/2011-02-01/documents/batch", { :body => [{ "type" => "add", "id" => "1", "version" => 1, "lang" => "en", "fields" => { :name => "fritters"}}].to_json, :headers => { "Content-Type" => "application/json"}})

        expect(@asari.add_item("1", {:name => "fritters"})).to eq(nil)
      end
    end

    it "converts Time, DateTime, and Date fields to timestamp integers for rankability" do
      date = Date.new(2012, 4, 1)
      HTTParty.should_receive(:post).with("http://doc-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/documents/batch", { :body => [{ "type" => "add", "id" => "1", "version" => 1, "lang" => "en", "fields" => { :time => 1333263600, :datetime => 1333238400, :date => date.to_time.to_i }}].to_json, :headers => { "Content-Type" => "application/json"}})

      expect(@asari.add_item("1", {:time => Time.at(1333263600), :datetime => DateTime.new(2012, 4, 1), :date => date})).to eq(nil)
    end

    it "allows you to update an item to the index." do
      HTTParty.should_receive(:post).with("http://doc-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/documents/batch", { :body => [{ "type" => "add", "id" => "1", "version" => 1, "lang" => "en", "fields" => { :name => "fritters"}}].to_json, :headers => { "Content-Type" => "application/json"}})

      expect(@asari.update_item("1", {:name => "fritters"})).to eq(nil)
    end

    it "converts Time, DateTime, and Date fields to timestamp integers for rankability on update as well" do
      date = Date.new(2012, 4, 1)
      HTTParty.should_receive(:post).with("http://doc-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/documents/batch", { :body => [{ "type" => "add", "id" => "1", "version" => 1, "lang" => "en", "fields" => { :time => 1333263600, :datetime => 1333238400, :date => date.to_time.to_i }}].to_json, :headers => { "Content-Type" => "application/json"}})

      expect(@asari.update_item("1", {:time => Time.at(1333263600), :datetime => DateTime.new(2012, 4, 1), :date => date})).to eq(nil)
    end

    it "allows you to delete an item from the index." do
      HTTParty.should_receive(:post).with("http://doc-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/documents/batch", { :body => [{ "type" => "delete", "id" => "1", "version" => 1}].to_json, :headers => { "Content-Type" => "application/json"}})

      expect(@asari.remove_item("1")).to eq(nil)
    end

    describe "when there are internet issues" do
      before :each do
        HTTParty.stub(:post).and_raise(SocketError.new)
      end

      it "raises an exception when you try to add an item to the index" do
        expect { @asari.add_item("1", {})}.to raise_error(Asari::DocumentUpdateException)
      end

      it "raises an exception when you try to update an item in the index" do
        expect { @asari.update_item("1", {})}.to raise_error(Asari::DocumentUpdateException)
      end

      it "raises an exception when you try to remove an item from the index" do
        expect { @asari.remove_item("1")}.to raise_error(Asari::DocumentUpdateException)
      end
    end

    describe "when there are CloudSearch issues" do
      before :each do
        HTTParty.stub(:post).and_return(fake_error_response)
      end

      it "raises an exception when you try to add an item to the index" do
        expect { @asari.add_item("1", {})}.to raise_error(Asari::DocumentUpdateException)
      end

      it "raises an exception when you try to update an item in the index" do
        expect { @asari.update_item("1", {})}.to raise_error(Asari::DocumentUpdateException)
      end

      it "raises an exception when you try to remove an item from the index" do
        expect { @asari.remove_item("1")}.to raise_error(Asari::DocumentUpdateException)
      end

    end
  end
end
