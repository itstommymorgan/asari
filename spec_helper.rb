require 'asari'
require 'ostruct'

RSpec.configuration.expect_with(:rspec) { |c| c.syntax = :expect }

def fake_response
  OpenStruct.new(:parsed_response => { "hits" => {"hit" => [{"id" => "123"}, {"id" => "456"}]}},
                 :response => OpenStruct.new(:code => "200"))
end

def fake_empty_response
  OpenStruct.new(:parsed_response => { "hits" => {"hit" => []}},
                 :response => OpenStruct.new(:code => "200"))
end

def fake_error_response
  OpenStruct.new(:response => OpenStruct.new(:code => "404"))
end

def fake_post_success
  OpenStruct.new(:response => OpenStruct.new(:code => "200"))
end
