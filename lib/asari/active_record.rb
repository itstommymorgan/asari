class Asari
  module ActiveRecord
    def self.included(base)
      base.extend(ClassMethods)

      base.before_delete :asari_remove_from_index
      base.after_create :asari_add_to_index
      base.after_update :asari_update_in_index
    end

    def asari_remove_from_index
      self.class.asari_remove_item(self)
    end

    def asari_add_to_index
      self.class.asari_add_item(self)
    end

    def asari_update_in_index
      self.class.asari_update_item(self)
    end

    module ClassMethods
      def asari_index(search_domain, fields)
        @asari = Asari.new(search_domain)
        @fields = fields
      end

      def asari_add_item(obj)
        data = {}
        @fields.each do |field|
          data[field] = obj.send(field)
        end
        @asari.add_item(obj.send(:id), data)
      rescue Asari::DocumentUpdateException => e
        asari_on_error(e)
      end

      def asari_update_item(obj)
        data = {}
        @fields.each do |field|
          data[field] = obj.send(field)
        end
        @asari.update_item(obj.send(:id), data)
      rescue Asari::DocumentUpdateException => e
        asari_on_error(e)
      end

      def asari_remove_item(obj)
        @asari.remove_item(obj.send(:id))
      rescue Asari::DocumentUpdateException => e
        asari_on_error(e)
      end

      def asari_find(term)
        ids = @asari.search(term).map { |id| id.to_i }
        begin
          self.find(*ids)
        rescue ::ActiveRecord::RecordNotFound
          []
        end
      end

      def asari_on_error(exception)
        raise exception
      end
    end
  end
end
