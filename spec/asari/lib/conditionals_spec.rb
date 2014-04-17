require_relative '../asari_spec_helper'

describe Asari do
  describe Asari::ActiveRecord do
    describe "conditional indexing" do
      describe "when a :when option is provided" do
        before :each do
          @arcs = ARConditionalsSpy.new
          @arcs.be_indexable = false
          @asari = double()
          ARConditionalsSpy.class_variable_set(:@@asari_instance, @asari)
        end

        it "doesn't add to the index if the :when option returns false" do
          expect(@arcs.was_asked).to eq(false)
          @arcs.asari_add_to_index
          expect(@arcs.was_asked).to eq(true)
        end

        it "doesn't add to the index if the :when option returns false" do
          expect(@arcs.was_asked).to eq(false)
          @arcs.asari_add_to_index
          expect(@arcs.was_asked).to eq(true)
        end

        it "does add to the index if the :when option returns true" do
          expect(@arcs.was_asked).to eq(false)
          @arcs.be_indexable = true
          @asari.should_receive(:add_item).with(1, { :name => "Tommy", :email => "some@email.com"})
          @arcs.asari_add_to_index
          expect(@arcs.was_asked).to eq(true)
        end

        it "deletes the item from the index if the :when option returns false when the item is updated" do
          expect(@arcs.was_asked).to eq(false)
          @asari.should_receive(:remove_item).with(1)
          @arcs.asari_update_in_index
          expect(@arcs.was_asked).to eq(true)
        end

        it "updates the item in the index if the :when option returns true when the item is updated" do
          expect(@arcs.was_asked).to eq(false)
          @arcs.be_indexable = true
          @asari.should_receive(:update_item).with(1, { :name => "Tommy", :email => "some@email.com"})
          @arcs.asari_update_in_index
          expect(@arcs.was_asked).to eq(true)
        end
      end
    end
  end
end
