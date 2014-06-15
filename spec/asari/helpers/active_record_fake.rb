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
  attr_accessor :id, :name, :email

  def initialize(params = {}) 
    @id = params[:id] || 1
    @name = params[:name] || "Fritters"
    @email = params[:email] || "fritters@aredelicious.com"
  end

end

