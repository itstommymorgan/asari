require "asari/version"

require "asari/collection"
require "asari/exceptions"
require "asari/geography"

require "httparty"

require "ostruct"
require "json"
require "cgi"

class Asari
  # CloudSearch requires bucket size, so we provide fixed number
  # we need all facets, so we guess it's big enough
  MAX_FACETS_SIZE = 999

  def self.mode
    @@mode
  end

  def self.mode=(mode)
    @@mode = mode
  end

  attr_writer :api_version
  attr_writer :search_domain
  attr_writer :aws_region

  def initialize(search_domain=nil, aws_region=nil)
    @search_domain = search_domain
    @aws_region = aws_region
  end

  # Public: returns the current search_domain, or raises a
  # MissingSearchDomainException.
  #
  def search_domain
    @search_domain || raise(MissingSearchDomainException.new)
  end

  # Public: returns the current api_version, or the sensible default of
  # "2011-02-01" (at the time of writing, the current version of the
  # CloudSearch API).
  #
  def api_version
    @api_version || ENV['CLOUDSEARCH_API_VERSION'] || "2011-02-01"
  end

  # Public: returns the current aws_region, or the sensible default of
  # "us-east-1."
  def aws_region
    @aws_region || "us-east-1"
  end

  # Public: Search for the specified term.
  #
  # Examples:
  #
  #     @asari.search("fritters") #=> ["13","28"]
  #     @asari.search(filter: { and: { type: 'donuts' }}) #=> ["13,"28","35","50"]
  #     @asari.search("fritters", filter: { and: { type: 'donuts' }}) #=> ["13"]
  #
  # Returns: An Asari::Collection containing all document IDs in the system that match the
  #   specified search term. If no results are found, an empty Asari::Collection is
  #   returned.
  #
  # Raises: SearchException if there's an issue communicating the request to
  #   the server.
  def search(term, options = {})
    return Asari::Collection.sandbox_fake if self.class.mode == :sandbox
    term,options = "",term if term.is_a?(Hash) and options.empty?

    page_size = page_size_options(options)

    url = "http://search-#{search_domain}.#{aws_region}.cloudsearch.amazonaws.com/#{api_version}/search"
    url += build_query(term, options)
    url += "&size=#{page_size}"
    url += return_fields_options(options)
    url += page_options(options)
    url += rank_options(options)
    url += field_weights_options(options)

    begin
      response = HTTParty.get(url)
    rescue Exception => e
      ae = Asari::SearchException.new("#{e.class}: #{e.message} (#{url})")
      ae.set_backtrace e.backtrace
      raise ae
    end

    unless response.response.code == "200"
      raise Asari::SearchException.new("#{response.response.code}: #{response.response.msg} (#{url})")
    end

    Asari::Collection.new(response, page_size)
  end

  # Public: Add an item to the index with the given ID.
  #
  #     id - the ID to associate with this document
  #     fields - a hash of the data to associate with this document. This
  #       needs to match the search fields defined in your CloudSearch domain.
  #
  # Examples:
  #
  #     @asari.update_item("4", { :name => "Party Pooper", :email => ..., ... }) #=> nil
  #
  # Returns: nil if the request is successful.
  #
  # Raises: DocumentUpdateException if there's an issue communicating the
  #   request to the server.
  #
  def add_item(id, fields)
    return nil if self.class.mode == :sandbox
    query = create_item_query id, fields
    doc_request(query)
  end

  # Public: Update an item in the index based on its document ID.
  #   Note: As of right now, this is the same method call in CloudSearch
  #   that's utilized for adding items. This method is here to provide a
  #   consistent interface in case that changes.
  #
  # Examples:
  #
  #     @asari.update_item("4", { :name => "Party Pooper", :email => ..., ... }) #=> nil
  #
  # Returns: nil if the request is successful.
  #
  # Raises: DocumentUpdateException if there's an issue communicating the
  #   request to the server.
  #
  def update_item(id, fields)
    add_item(id, fields)
  end

  # Public: Remove an item from the index based on its document ID.
  #
  # Examples:
  #
  #     @asari.search("fritters") #=> ["13","28"]
  #     @asari.remove_item("13") #=> nil
  #     @asari.search("fritters") #=> ["28"]
  #     @asari.remove_item("13") #=> nil
  #
  # Returns: nil if the request is successful (note that asking the index to
  #   delete an item that's not present in the index is still a successful
  #   request).
  # Raises: DocumentUpdateException if there's an issue communicating the
  #   request to the server.
  def remove_item(id)
    return nil if self.class.mode == :sandbox

    query = remove_item_query id
    doc_request query
  end

  # Internal: helper method: common logic for queries against the doc endpoint.
  #
  def doc_request(query)
    request_query = query.class.name == 'Array' ? query : [query]
    endpoint = "http://doc-#{search_domain}.#{aws_region}.cloudsearch.amazonaws.com/#{api_version}/documents/batch"

    options = { :body => request_query.to_json, :headers => { "Content-Type" => "application/json"} }

    begin
      response = HTTParty.post(endpoint, options)
    rescue Exception => e
      ae = Asari::DocumentUpdateException.new("#{e.class}: #{e.message}")
      ae.set_backtrace e.backtrace
      raise ae
    end

    unless response.response.code == "200"
      raise Asari::DocumentUpdateException.new("#{response.response.code}: #{response.response.msg}")
    end

    nil
  end

  def create_item_query(id, fields)
    return nil if self.class.mode == :sandbox
    query = { "type" => "add", "id" => id.to_s, "version" => Time.now.to_i, "lang" => "en" }
    fields.each do |k,v|
      fields[k] = convert_date_or_time(fields[k])
      fields[k] = "" if v.nil?
    end

    query["fields"] = fields
    query
  end

  def remove_item_query(id)
    { "type" => "delete", "id" => id.to_s, "version" => Time.now.to_i }
  end

  protected

  # Private: Builds the query from a passed hash
  #
  #     terms - a hash of the search query. %w(and or not) are reserved hash keys
  #             that build the logic of the query
  def boolean_query(terms = {}, options = {})
    reduce = lambda { |hash|
      hash.reduce("") do |memo, (key, value)|
        if %w(and or not).include?(key.to_s) && value.is_a?(Hash)
          sub_query = reduce.call(value)
          memo += "(#{key}#{sub_query})" unless sub_query.empty?
        elsif key.to_s.match(/.*_or/) && value.is_a?(Hash)
          sub_query = value.map do |or_key, or_value|
            Array(or_value).map { |v| " #{or_key}:'#{v}'" }.join
          end.join
          memo += " " unless memo.empty?
          memo += "(or#{sub_query})" unless sub_query.empty?
        else
          if value.is_a?(Range) || value.is_a?(Integer)
            memo += " #{key}:#{value}"
          elsif value.is_a?(Array)
            memo += " " unless memo.empty?
            memo += "#{key}:#{value}".gsub('"',"'")
          else
            memo += " #{key}:'#{value}'" unless value.to_s.empty?
          end
        end
        memo
      end
    }
    reduce.call(terms)
  end

  def normalize_rank(rank)
    rank = Array(rank)
    rank << :asc if rank.size < 2

    if api_version == '2013-01-01'
      "#{rank[0]} #{rank[1]}"
    else
      rank[1] == :desc ? "-#{rank[0]}" : rank[0]
    end
  end

  def convert_date_or_time(obj)
    return obj unless [Time, Date, DateTime].include?(obj.class)
    obj.to_time.to_i
  end

  def build_query(term, options)
    bq = boolean_query(options[:filter]) if options[:filter]
    fs = build_facet_string(options[:facets]) if options[:facets]

    query = ""
    if api_version == '2013-01-01'
      if options[:filter] and term != ""
        query += "?q=#{CGI.escape("(and '#{term.to_s}' #{bq})")}"
        query += "&q.parser=structured"
      elsif options[:filter]
        query += "?q=#{CGI.escape(bq)}"
        query += "&q.parser=structured"
      else
        query += "?q=#{CGI.escape(term.to_s)}"
      end
      query += "&#{fs}" if options[:facets]
    else
      query = "?q=#{CGI.escape(term.to_s)}"
      query += "&bq=#{CGI.escape(bq)}" if options[:filter]
    end
    query
  end

  def build_facet_string(facets)
    escaped_braces = CGI.escape("{sort:'bucket',size:#{MAX_FACETS_SIZE}}")
    facets.map { |f| "facet.#{f}=#{escaped_braces}" }.join("&")
  end

  def field_weights_options(options)
    return "" unless options[:field_weights]

    weights = options[:field_weights].map { |key, value| "\'#{key}^#{value}\'" }.join(",")
    weights_string = CGI.escape("{fields:[#{weights}]}")
    "&q.options=#{weights_string}"
  end

  def page_options(options)
    return "" unless options[:page]

    start = (options[:page].to_i - 1) * page_size_options(options)
    "&start=#{start}"
  end

  def page_size_options(options)
    return 10 unless options[:page_size]

    options[:page_size].to_i
  end

  def rank_options(options)
    return "" unless options[:rank]

    rank = normalize_rank(options[:rank])
    rank_or_sort = api_version == '2013-01-01' ? 'sort' : 'rank'
    "&#{rank_or_sort}=#{CGI.escape(rank)}"
  end

  def return_fields_options(options)
    return ""  unless options[:return_fields]

    return_statement = api_version == '2013-01-01' ? 'return' : 'return-fields'
    "&#{return_statement}=#{options[:return_fields].join ','}"
  end

end

Asari.mode = :sandbox # default to sandbox
