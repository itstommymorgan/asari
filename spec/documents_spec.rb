require_relative "../spec_helper"

describe Asari do
  describe "updating the index" do
    before :each do
      Asari.search_domain = "testdomain"
      stub_const("HTTParty", double())
      HTTParty.stub(:post).and_return(fake_post_success)
    end

    it "allows you to add an item to the index." do
      HTTParty.should_receive(:post).with("http://doc-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/documents/batch", { :body => [{ "type" => "add", "id" => "1", "version" => 1, "lang" => "en", "fields" => { :name => "fritters"}}].to_json, :headers => { "Content-Type" => "application/json"}})

      expect(Asari.add_item("1", {:name => "fritters"})).to eq(nil)
    end

    it "allows you to update an item to the index." do
      HTTParty.should_receive(:post).with("http://doc-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/documents/batch", { :body => [{ "type" => "add", "id" => "1", "version" => 1, "lang" => "en", "fields" => { :name => "fritters"}}].to_json, :headers => { "Content-Type" => "application/json"}})

      expect(Asari.update_item("1", {:name => "fritters"})).to eq(nil)
    end

    it "allows you to delete an item from the index." do
      HTTParty.should_receive(:post).with("http://doc-testdomain.us-east-1.cloudsearch.amazonaws.com/2011-02-01/documents/batch", { :body => [{ "type" => "delete", "id" => "1", "version" => 2}].to_json, :headers => { "Content-Type" => "application/json"}})

      expect(Asari.remove_item("1")).to eq(nil)
    end

    describe "when there are issues" do
      before :each do
        HTTParty.stub(:post).and_return(fake_error_response)
      end

      it "raises an exception when you try to add an item to the index" do
        expect { Asari.add_item("1", {})}.to raise_error(Asari::DocumentUpdateException)
      end

      it "raises an exception when you try to update an item in the index" do
        expect { Asari.update_item("1", {})}.to raise_error(Asari::DocumentUpdateException)
      end

      it "raises an exception when you try to remove an item from the index" do
        expect { Asari.remove_item("1")}.to raise_error(Asari::DocumentUpdateException)
      end

    end
  end
end
