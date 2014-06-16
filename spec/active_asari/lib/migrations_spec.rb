require 'active_asari/active_asari_spec_helper'
require 'active_asari/lib/migrations_spec_data'
include MigrationsSpecData

describe 'migrations' do

  let(:migrations) {ActiveAsari::Migrations.new}

  before :each do
  end

  context 'index_field' do
    context 'literal fields' do
      before :each do
        expected_index_field_request = {:domain_name => 'test-beavis-butthead', :index_field => 
                                        {:index_field_name => 'band_name', :index_field_type => 'literal', :literal_options =>
                                         {:search_enabled => false, :return_enabled => true}}}
        migrations.connection.should_receive(:define_index_field).with(expected_index_field_request).and_return CREATE_LITERAL_INDEX_RESPONSE     
      end

      it 'should add a index to the domain' do
        migrations.create_index_field('BeavisButthead', 'band_name' => { 'index_field_type' => 'literal', 'search_enabled' => false, 'return_enabled' => true})
      end
    end

    it 'should set search enabled to true if it is a string that evaluates to true' do
      expected_index_field_request = {:domain_name => 'test-beavis-butthead', :index_field => 
                                      {:index_field_name => 'band_name', :index_field_type => 'literal', :literal_options =>
                                       {:search_enabled => true, :return_enabled => true}}}
      migrations.connection.should_receive(:define_index_field).with(expected_index_field_request).and_return CREATE_LITERAL_INDEX_RESPONSE     
      migrations.create_index_field('BeavisButthead', 'band_name' => { 'index_field_type' => 'literal', 'search_enabled' => true, 'return_enabled' => true})
    end

    context 'parameteter options' do
      let(:index_type) {'text'}
      shared_examples_for 'code that adds to and indexes the domain' do    
        it 'should add a index to the domain with options' do
          expected_index_field_request = {domain_name: 'test-beavis', index_field: 
                                          {index_field_name: 'tv_location', index_field_type: index_type, "#{index_type}_options".tr('-','_').to_sym =>
                                           {return_enabled: true}}}
          migrations.connection.should_receive(:define_index_field).with(expected_index_field_request).and_return CREATE_TEXT_INDEX_RESPONSE 
          migrations.create_index_field('beavis', 'tv_location' => { 'index_field_type' => index_type, 'return_enabled' => true})
        end

        it 'should add a index to the domain with default options' do
          expected_index_field_request = {domain_name: 'test-beavis', index_field: 
                                          {index_field_name: 'tv_location', index_field_type: index_type}}
          migrations.connection.should_receive(:define_index_field).with(expected_index_field_request).and_return CREATE_TEXT_INDEX_RESPONSE 
          migrations.create_index_field('beavis', 'tv_location' => { 'index_field_type' => index_type})
        end
      end

      context 'text index' do
        let(:index_type) {'text'}
        it_behaves_like 'code that adds to and indexes the domain'
      end

      context 'date-array index' do
        let(:index_type) {'date-array'}
        it_behaves_like 'code that adds to and indexes the domain'
      end

      context 'double index' do
        let(:index_type) {'double'}
        it_behaves_like 'code that adds to and indexes the domain'
      end

      context 'double-array index' do
        let(:index_type) {'double-array'}
        it_behaves_like 'code that adds to and indexes the domain'
      end

      context 'int index' do
        let(:index_type) {'int'}
        it_behaves_like 'code that adds to and indexes the domain'
      end

      context 'int-array index' do
        let(:index_type) {'int-array'}
        it_behaves_like 'code that adds to and indexes the domain'
      end

      context 'latlon index' do
        let(:index_type) {'latlon'}
        it_behaves_like 'code that adds to and indexes the domain'
      end

      context 'literal index' do
        let(:index_type) {'literal'}
        it_behaves_like 'code that adds to and indexes the domain'
      end

      context 'literal-array index' do
        let(:index_type) {'literal-array'}
        it_behaves_like 'code that adds to and indexes the domain'
      end

      context 'text-array index' do
        let(:index_type) {'text-array'}
        it_behaves_like 'code that adds to and indexes the domain'
      end
    end
  end

  context 'domain' do

    it 'should create indexes for all items in the domain' do
      migrations.should_receive(:create_index_field).once.with('TestModel', 
                                                               'name' => { 'index_field_type' => 'text', 
                                                                           'search_enabled' => true})
      migrations.should_receive(:create_index_field).once.with('TestModel', 
                                                               'amount' => { 'index_field_type' => 'int', 
                                                                             'search_enabled' => true})
      migrations.should_receive(:create_index_field).once.with('TestModel', 
                                                               'last_updated' => { 'index_field_type' => 'int', 
                                                                                   'search_enabled' => false})
      migrations.should_receive(:create_index_field).once.with('TestModel', 
                                                               'bee_larvae_type' => { 'index_field_type' => 'literal'})
      migrations.should_receive(:create_index_field).once.with('TestModel', 
                                                               'active_asari_id' => { 'index_field_type' => 'int', 'return_enabled' => true})
      ActiveAsari.should_receive(:amazon_safe_domain_name).at_least(:once).with('TestModel').and_return 'test-model-666'
      migrations.connection.should_receive(:index_documents).with(:domain_name => 'test-model-666')
      migrations.migrate_domain 'TestModel'
    end
  end

  context 'migrate_all' do
    it 'should migrate all of the domains' do
      migrations.should_receive(:migrate_domain).once.with 'TestModel'
      migrations.should_receive(:migrate_domain).once.with 'HoneyBadger'
      migrations.migrate_all
    end
  end

end
