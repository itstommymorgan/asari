class Asari
  module ActiveRecord
    DELAYED_ASARI_INDEX = true
  end
end

class ActiveRecordFakeNoAutoIndex

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
        [ActiveRecordFakeNoAutoIndex.new]
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

