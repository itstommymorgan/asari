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
            {:search_enabled => false, :result_enabled => true}}}
            migrations.connection.should_receive(:define_index_field).with(expected_index_field_request).and_return CREATE_LITERAL_INDEX_RESPONSE     
      end

      it 'should add a index to the domain' do
        migrations.create_index_field('BeavisButthead', 'band_name' => { 'index_field_type' => 'literal', 'search_enabled' => false})
      end

      it 'should default search enabled to false if it is not specified' do
        migrations.create_index_field('BeavisButthead', 'band_name' => { 'index_field_type' => 'literal'})
      end

      it 'should default search enabled to false if it is not specified as a blank string' do
        migrations.create_index_field('BeavisButthead', 'band_name' => { 'index_field_type' => 'literal', 'search_enabled' => ''})
      end

    end

    it 'should set search enabled to true if it is a string that evaluates to true' do
      expected_index_field_request = {:domain_name => 'test-beavis-butthead', :index_field => 
        {:index_field_name => 'band_name', :index_field_type => 'literal', :literal_options =>
          {:search_enabled => true, :result_enabled => true}}}
          migrations.connection.should_receive(:define_index_field).with(expected_index_field_request).and_return CREATE_LITERAL_INDEX_RESPONSE     
          migrations.create_index_field('BeavisButthead', 'band_name' => { 'index_field_type' => 'literal', 'search_enabled' => true})
    end

    it 'should add a text index to the domain' do
      expected_index_field_request = {:domain_name => 'test-beavis', :index_field => 
        {:index_field_name => 'tv_location', :index_field_type => 'text', :text_options =>
          {:result_enabled => true}}}
          migrations.connection.should_receive(:define_index_field).with(expected_index_field_request).and_return CREATE_TEXT_INDEX_RESPONSE 
          migrations.create_index_field('beavis', 'tv_location' => { 'index_field_type' => 'text'})
    end

    it 'should add a uint index to the domain' do
      expected_index_field_request = {:domain_name => 'test-beavis', :index_field => 
        {:index_field_name => 'num_tvs', :index_field_type => 'uint'}}
        migrations.connection.should_receive(:define_index_field).with(expected_index_field_request).and_return CREATE_UINT_INDEX_RESPONSE 
        migrations.create_index_field('beavis', 'num_tvs' => { 'index_field_type' => 'uint'})
    end
  end

  context 'update_service_access_policies' do
    it 'should allow all access for ip addresses specified in the configuration file' do
      access_policies = "{\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"*\",\"Resource\":\"*\",\"Condition\":{\"IpAddress\":{\"aws:SourceIp\":[\"192.168.66.23/32\"]}}},{\"Effect\":\"Allow\",\"Action\":\"*\",\"Resource\":\"*\",\"Condition\":{\"IpAddress\":{\"aws:SourceIp\":[\"23.44.23.25/32\"]}}}]}"
      migrations.connection.should_receive(:update_service_access_policies).with(:domain_name => 'beavis',
                                                                                 :access_policies => access_policies)
      ENV['RAILS_ENV'] = nil
      ENV['RACK_ENV'] = 'test'
      migrations.update_service_access_policies 'beavis'
    end
  end

  context 'domain' do

    it 'should create a domain if one doesnt exist' do
      migrations.connection.should_receive(:create_domain).with({:domain_name => 'test-beavis-butthead'}).and_return CREATE_DOMAIN_RESPONSE    
      migrations.create_domain 'BeavisButthead'
    end

    it 'should create indexes for all items in the domain and create the domain' do
      migrations.should_receive(:create_domain).once.with 'TestModel'
      migrations.should_receive(:create_index_field).once.with('TestModel', 
                                                               'name' => { 'index_field_type' => 'text', 
                                                                 'search_enabled' => true})
      migrations.should_receive(:create_index_field).once.with('TestModel', 
                                                               'amount' => { 'index_field_type' => 'uint', 
                                                                 'search_enabled' => true})
      migrations.should_receive(:create_index_field).once.with('TestModel', 
                                                               'last_updated' => { 'index_field_type' => 'uint', 
                                                                 'search_enabled' => false})
      migrations.should_receive(:create_index_field).once.with('TestModel', 
                                                               'bee_larvae_type' => { 'index_field_type' => 'literal'})
      migrations.should_receive(:create_index_field).once.with('TestModel', 
                                                               'active_asari_id' => { 'index_field_type' => 'uint'})
      ActiveAsari.should_receive(:amazon_safe_domain_name).twice.with('TestModel').and_return 'test-model-666'
      migrations.should_receive(:update_service_access_policies).once.with('test-model-666')
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
