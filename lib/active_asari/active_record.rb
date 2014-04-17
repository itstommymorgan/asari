module ActiveAsari
  module ActiveRecord

    alias_attribute :active_asari_id, :id

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def env_test?
        (ENV['RAILS_ENV'] == 'test' or ENV['RACK_ENV'] == 'test')
      end

      def active_asari_index(class_name)
        active_asari_index_array = ACTIVE_ASARI_CONFIG[class_name].symbolize_keys.keys.concat [:active_asari_id] 
        asari_index ActiveAsari.asari_domain_name(class_name),  active_asari_index_array if !env_test?
      end
    end
  end
end
