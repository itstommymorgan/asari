require 'asari/active_record'
require 'ostruct'
require 'spec_helper'

# Fake production mode to test.
Asari.mode = :production

def fake_response
  OpenStruct.new(:parsed_response => { "hits" => {
                      "found" => 2,
                      "start" => 0,
                      "hit" => [{"id" => "123"}, {"id" => "456"}]}},
                 :response => OpenStruct.new(:code => "200"))
end

def fake_empty_response
  OpenStruct.new(:parsed_response => { "hits" => { "found" => 0, "start" => 0, "hit" => []}},
                 :response => OpenStruct.new(:code => "200"))
end

def fake_error_response
  OpenStruct.new(:response => OpenStruct.new(:code => "404"))
end

def fake_post_success
  OpenStruct.new(:response => OpenStruct.new(:code => "200"))
end

require 'asari/helpers/active_record_fake'

class ActiveRecordFakeWithErrorOverride < ActiveRecordFake
  def self.asari_on_error(exception)
    false
  end
end

require 'asari/helpers/ar_conditionals_spy'

