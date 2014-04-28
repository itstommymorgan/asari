require_relative '../active_asari_spec_helper'

describe Hasher do
  context 'get_domain_instance' do

    it 'should set a class variable for the domain' do
      ActiveAsari.should_receive(:asari_domain_name).and_return 'foo'
      Hasher.class_variable_defined?(:@@asari_domain_foo).should eql false
      instance = Hasher.get_domain_instance('foo')
      instance.should eql Hasher.class_variable_get(:@@asari_domain_foo)
    end

    it 'should not set a class variable for the domain if one already exists' do
      ActiveAsari.should_receive(:asari_domain_name).never
      Hasher.class_variable_set(:@@asari_domain_foo, 'beavis')
      instance = Hasher.get_domain_instance('foo')
      instance.should eql Hasher.class_variable_get(:@@asari_domain_foo)
    end
  end

  context 'create_active_asari_hash' do
    let(:original_hash) {{ active_asari_id: 88,
      name: 'honey badger',
      amount: 33,
      nachos: false}}

    subject {Hasher.create_active_asari_hash 'TestModel', original_hash}
    its([:active_asari_id]) {should eql 88}
    its([:name]) {should eql 'honey badger'}
    its([:amount]) {should eql 33}
    its([:nachos]) {should eql nil}
  end 

  context 'add/update/delete_index' do
    let(:original_hash) {{ active_asari_id: 88,
      name: 'honey badger',
      amount: 33,
      nachos: false}}
    let(:asari_hash) {{ active_asari_id: 88,
      name: 'honey badger',
      amount: 33,
      last_updated: nil,
      bee_larvae_type: nil}}
    let(:domain_instance) {double 'domain_instance'}

    before :each do
      Hasher.should_receive(:get_domain_instance).with('TestModel').and_return domain_instance
    end

    it 'should send a request to add an item to Cloud Search' do
      domain_instance.should_receive(:add_item).with(88, asari_hash).and_return nil
      Hasher.add_to_index('TestModel', original_hash).should eql nil
    end

    it 'should send a request to update an item to Cloud Search' do
      domain_instance.should_receive(:update_item).with(88, asari_hash).and_return nil
      Hasher.update_index('TestModel', original_hash).should eql nil
    end

    it 'should send a request to delete an item to Cloud Search' do
      domain_instance.should_receive(:delete_item).with(88).and_return nil
      Hasher.delete_item('TestModel', 88).should eql nil
    end
  end 
end
