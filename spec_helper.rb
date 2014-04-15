require 'asari'
require 'asari/active_record'
require 'ostruct'
require 'simplecov'
SimpleCov.start

# Fake production mode to test.
Asari.mode = :production

RSpec.configuration.expect_with(:rspec) { |c| c.syntax = :expect }

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

module ActiveRecord
  class RecordNotFound < StandardError
  end
end

class ActiveRecordFake

  class << self
    def before_destroy(sym)
      @before_destroy = sym
    end

    def after_create(sym)
      @after_create = sym
    end

    def after_update(sym)
      @after_update = sym
    end

    def where(query, ids)
      if ids.size > 0
        [ActiveRecordFake.new]
      else
        []
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
  def self.asari_on_error(exception)
    false
  end
end

class ARConditionalsSpy
  attr_accessor :be_indexable
  attr_accessor :was_asked

  class << self
    def before_destroy(sym)
      @before_destroy = sym
    end

    def after_create(sym)
      @after_create = sym
    end

    def after_update(sym)
      @after_update = sym
    end

    def find(*args)
      if args.size > 0
        return [ARConditionalsSpy.new]
      else
        raise ActiveRecord::RecordNotFound
      end
    end
  end

  include Asari::ActiveRecord

  asari_index("test-domain", [:name, :email], :when => :indexable)
  
  def initialize
    @was_asked = false
  end

  def id
    1
  end

  def name
    "Tommy"
  end

  def email
    "some@email.com"
  end

  def indexable
    @was_asked = true
    @be_indexable
  end
end
