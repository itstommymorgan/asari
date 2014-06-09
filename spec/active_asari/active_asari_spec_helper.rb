ENV['RACK_ENV'] = 'test'
require 'spec_helper'
require 'active_record'
require 'factory_girl'
db_config = YAML.load_file(File.expand_path(File.dirname(__FILE__)) + '/database.yml')
ActiveRecord::Base.establish_connection db_config['test']

ActiveRecord::Base.connection

ACTIVE_ASARI_SEARCH_DOMAIN = 'my_great_domain'
Dir[File.dirname(__FILE__) + "/../lib/active_asari/*.rb"].each {|file| require file }
require 'active_asari'
ACTIVE_ASARI_CONFIG, ACTIVE_ASARI_ENV = ActiveAsari.configure(File.dirname(__FILE__))
require 'active_asari/active_record'
require 'aws'
require 'active_asari/model/test_model'
require 'active_asari/model/create_test_model'
require 'active_asari/hasher'

