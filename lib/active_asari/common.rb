module ActiveAsari

  def self.amazon_safe_domain_name(domain)
    environment = ENV['RAILS_ENV'] ? ENV['RAILS_ENV'] : ENV['RACK_ENV'] 
    "#{ACTIVE_ASARI_ENV[environment]['domain_prefix']}-#{domain.underscore.sub(/_/, '-')}" 
  end

  def self.aws_client
    AWS::CloudSearch::Client::V20130101.new
  end

  def self.asari_domain_name(domain)
    $domains = {} if !$domains
    amazon_domain = amazon_safe_domain_name domain
    if !$domains[amazon_domain]
      domain_data = aws_client.describe_domains[:domain_status_list].select { |domain_data|  
        domain_data[:domain_name] == amazon_domain}
      $domains[amazon_domain] = domain_data.first[:search_service][:endpoint].split('.').first[7..-1]
    end
    $domains[amazon_domain] 
  end

  def self.active_asari_raw_search(domain, query, search_options = {})
    asari = Asari.new asari_domain_name(domain)
    fields = ACTIVE_ASARI_CONFIG[domain].map {|field| field.first.to_sym}
    fields = fields.concat([:active_asari_id])
    search_options[:return_fields] = fields
    asari.search query, search_options
  end

  def self.objectify_results(hash_results)
    results = {}
    hash_results.each do |key, value|
      results[key] = ResultObject.new
      results[key].raw_result = value
    end
    results
  end

  def self.active_asari_search(domain, query, search_options = {})
    raw_result = active_asari_raw_search domain, query, search_options
    objectify_results raw_result
  end

  def self.configure(yaml_file_dir)
    active_asari_config = YAML.load_file(File.expand_path(yaml_file_dir) + '/active_asari_config.yml')
    active_asari_env = YAML.load_file(File.expand_path(yaml_file_dir) + '/active_asari_env.yml') 
    return active_asari_config, active_asari_env
  end
end 
