module ActiveAsari
  class Migrations

    attr_accessor :connection

    def initialize 
      self.connection = AWS::CloudSearch::Client::V20130101.new
    end

    def migrate_all
      ACTIVE_ASARI_CONFIG.keys.each do |domain|
        migrate_domain domain
      end
    end

    def migrate_domain(domain)
      ACTIVE_ASARI_CONFIG[domain].each do |field|
        create_index_field domain, field.first => field.last
      end
      create_index_field domain, 'active_asari_id' => {'index_field_type' => 'int', 'return_enabled' => true}
      connection.index_documents :domain_name => ActiveAsari.amazon_safe_domain_name(domain)
    end

    def update_service_access_policies(domain)
      policy_array = []
      asari_env = ENV['RAILS_ENV'] ? ENV['RAILS_ENV'] : ENV['RACK_ENV'] 
      resource = "arn:aws:cloudsearch:us-east-1:#{ACTIVE_ASARI_ENV[asari_env]['account']}:domain/*"
      ACTIVE_ASARI_ENV[asari_env]['access_permissions'].each do |permission|
        policy_array << {:Effect => :Allow, :Action => 'cloudsearch:*', :Resource => resource, :Condition => {:IpAddress => {'aws:SourceIp' => [permission['ip_address']]}}} 
      end
      access_policies = {:Statement => policy_array}
      connection.update_service_access_policies :domain_name => domain, :access_policies => access_policies.to_json
    end

    def create_index_field(domain, field)
      index_field_name = field.keys.first
      index_field_type = field[index_field_name]['index_field_type']

      request = {:domain_name => ActiveAsari.amazon_safe_domain_name(domain), :index_field => {:index_field_name => index_field_name,
                                                                                               :index_field_type => index_field_type}}

      field[index_field_name].delete 'index_field_type'
      request[:index_field]["#{index_field_type.tr('-', '_')}_options".to_sym] = field[index_field_name].symbolize_keys! if !field[index_field_name].empty?

      connection.define_index_field request
    end

  end
end
