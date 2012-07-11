require 'asari'
require 'asari/active_record'
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

module ActiveRecord
  class RecordNotFound < StandardError
  end
end

class ActiveRecordFake
  class << self
    def before_delete(sym)
      @before_delete = sym
    end

    def after_create(sym)
      @after_create = sym
    end

    def after_update(sym)
      @after_update = sym
    end

    def find(*args)
      if args.size > 0
        return [ActiveRecordFake.new]
      else
        raise ActiveRecord::RecordNotFound
      end
    end
  end

  include Asari::ActiveRecord

  asari_index("test-domain", [:name, :email])

  def id
    1
  end

  def name
    "Fritters"
  end

  def email
    "fritters@aredelicious.com"
  end
end

class ActiveRecordFakeWithErrorOverride < ActiveRecordFake
  include Asari::ActiveRecord

  asari_index("test-domain", [:name, :email])

  def self.asari_on_error(exception)
    false
  end
end
