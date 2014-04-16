class ActiveAsari::ResultObject
  attr_accessor :raw_result

  def method_missing(method_sym, *arguments, &block) 
    base_method = method_sym.to_s.end_with?('_array') ? method_sym.to_s.chomp('_array') : method_sym.to_s
    if raw_result.has_key? base_method
      method_sym.to_s.end_with?('_array') ? raw_result[base_method] : raw_result[base_method].first
    else
      super
    end    
  end 

  def respond_to?(method_sym, include_private = false)
    base_method = method_sym.to_s.end_with?('_array') ? method_sym.to_s.chomp('_array') : method_sym.to_s
    if raw_result.has_key? base_method
      true
    else
      super
    end    
  end
end
