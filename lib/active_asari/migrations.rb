module ActiveAsari
  class Migrations

    attr_accessor :connection

    def initialize 
      self.connection = AWS::CloudSearch::Client.new
    end

    def migrate_all
      ACTIVE_ASARI_CONFIG.keys.each do |domain|
        migrate_domain domain
      end
    end

    def migrate_domain(domain)
      create_domain domain
      ACTIVE_ASARI_CONFIG[domain].each do |field|
        create_index_field domain, field.first => field.last
      end
      create_index_field domain, 'active_asari_id' => {'index_field_type' => 'uint'}
      connection.index_documents :domain_name => ActiveAsari.amazon_safe_domain_name(domain)
      update_service_access_policies ActiveAsari.amazon_safe_domain_name(domain)
    end

    def update_service_access_policies(domain)
      policy_array = []
      asari_env = ENV['RAILS_ENV'] ? ENV['RAILS_ENV'] : ENV['RACK_ENV'] 
      ACTIVE_ASARI_ENV[asari_env]['access_permissions'].each do |permission|
        policy_array << {:Effect => :Allow, :Action => '*', :Resource => '*', :Condition => {:IpAddress => {'aws:SourceIp' => [permission['ip_address']]}}} 
      end
      access_policies = {:Statement => policy_array}
      connection.update_service_access_policies :domain_name => domain, :access_policies => access_policies.to_json
    end

    def create_index_field(domain, field)
      index_field_name = field.keys.first
      index_field_type = field[index_field_name]['index_field_type']
      search_enabled = field[index_field_name]['search_enabled']
      if search_enabled == nil or search_enabled.blank?
        search_enabled = false
      end
      

      request = {:domain_name => ActiveAsari.amazon_safe_domain_name(domain), :index_field => {:index_field_name => index_field_name,
      :index_field_type => index_field_type}}
      case index_field_type 
      when 'literal'
        request[:index_field][:literal_options] = {:search_enabled => search_enabled, :result_enabled => true}
      when 'text'
        request[:index_field][:text_options] = {:result_enabled => true}
      end
      connection.define_index_field request
    end

    def create_domain(domain)
      connection.create_domain :domain_name => ActiveAsari.amazon_safe_domain_name(domain)        
    end

  end
end
