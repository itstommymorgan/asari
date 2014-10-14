require_relative '../spec_helper'

describe Asari do
  describe Asari::ActiveRecord do
    describe "when CloudSearch is responding without error" do
      before :each do
        @asari = double()
        ActiveRecordFake.class_variable_set(:@@asari_instance, @asari)
      end

      it "correctly sets up a before_destroy listener" do
        expect(ActiveRecordFake.instance_variable_get(:@before_destroy)).to eq(:asari_remove_from_index)
      end

      it "correctly sets up an after_create listener" do
        expect(ActiveRecordFake.instance_variable_get(:@after_create)).to eq(:asari_add_to_index)
      end

      it "correctly sets up an after_update listener" do
        expect(ActiveRecordFake.instance_variable_get(:@after_update)).to eq(:asari_update_in_index)
      end

      it "will automatically attempt to remove itself from the index" do
        expect(@asari).to receive(:remove_item).with(1)
        ActiveRecordFake.new.asari_remove_from_index
      end

      it "will automatically add itself to the index" do
        expect(@asari).to receive(:add_item).with(1, {:name => "Fritters", :email => "fritters@aredelicious.com"})
        ActiveRecordFake.new.asari_add_to_index
      end

      it "will automatically update itself in the index" do
        expect(@asari).to receive(:update_item).with(1, {:name => "Fritters", :email => "fritters@aredelicious.com"})
        ActiveRecordFake.new.asari_update_in_index
      end

      it "will allow you to search for items with the index" do
        expect(@asari).to receive(:search).with("fritters", {}).and_return(["1"])

        ActiveRecordFake.asari_find("fritters")
      end

      it "will return a list of model objects when you search" do
        expect(@asari).to receive(:search).with("fritters", {}).and_return(["1"])

        results = ActiveRecordFake.asari_find("fritters")
        expect(results.class).to eq(Array)
        expect(results[0].class).to eq(ActiveRecordFake)
      end

      it "will return an empty list when you search for a term that isn't in the index" do
        expect(@asari).to receive(:search).with("veggie burgers", {}).and_return([])

        results = ActiveRecordFake.asari_find("veggie burgers")
        expect(results.class).to eq(Array)
        expect(results.size).to eq(0)
      end
    end

    describe "When CloudSearch is being a problem" do
      before :each do
        ActiveRecordFake.class_variable_set(:@@asari_instance, Asari.new("test-domain"))
        stub_const("HTTParty", double())
        allow(HTTParty).to receive(:post).and_return(fake_error_response)
        allow(HTTParty).to receive(:get).and_return(fake_error_response)
      end

      it "will raise the Asari exception by default when adding to the index." do
        expect { ActiveRecordFake.new.asari_add_to_index }.to raise_error(Asari::DocumentUpdateException)
      end

      it "will raise the Asari exception by default when updating the index." do
        expect { ActiveRecordFake.new.asari_update_in_index }.to raise_error(Asari::DocumentUpdateException)
      end

      it "will raise the Asari exception by default when removing from index." do
        expect { ActiveRecordFake.new.asari_remove_from_index }.to raise_error(Asari::DocumentUpdateException)
      end

      it "will always raise the Asari exception when searching in the index." do
        expect { ActiveRecordFake.asari_find("fritters") }.to raise_error(Asari::SearchException)
      end

      describe "when we've overridden asari_on_error" do
        it "honors asari_on_error when adding to the index." do
          expect(ActiveRecordFakeWithErrorOverride.new.asari_add_to_index).to eq(false)
        end

        it "honors asari_on_error when updating in the index." do
          expect(ActiveRecordFakeWithErrorOverride.new.asari_update_in_index).to eq(false)
        end

        it "honors asari_on_error when removing from the index." do
          expect(ActiveRecordFakeWithErrorOverride.new.asari_remove_from_index).to eq(false)
        end

        it "still raises the Asari exception when searching." do
          expect { ActiveRecordFakeWithErrorOverride.asari_find("fritters") }.to raise_error(Asari::SearchException)
        end
      end

    end
  end
end
