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
