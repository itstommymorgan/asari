require "asari/version"

require "asari/collection"
require "asari/exceptions"
require "asari/geography"

require "httparty"

require "ostruct"
require "json"
require "cgi"

class Asari
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
    if term.is_a?(Hash) and options.empty?
      term,options = '',term 
    elsif term.nil?
      term = ''
    end

    bq = boolean_query(options[:filter]) if options[:filter]
    gq = geo_query(options[:geo]) if options[:geo]
    page_size = options[:page_size].nil? ? 10 : options[:page_size].to_i

    url = "http://search-#{search_domain}.#{aws_region}.cloudsearch.amazonaws.com/#{api_version}/search"

    if api_version == '2013-01-01'
      if !bq.nil? && !bq.empty?
        # structured boolean query -- may be augmented by geo query later
        if !term.empty?
          # include text query
          bq = "(and '#{term.to_s}' #{bq})"
        elsif options[:filter].count > 1
          # implicit AND at the top level, when there is more than one term
          bq = "(and #{bq})"
        end
        url += "?q=#{CGI.escape(bq)}"
        url += "&q.parser=structured"
      elsif !gq.nil? && !gq.empty? && term.empty?
        # geo query will sort relative to latlon, or select latlon tagged docs within a radius, but we need a set of docs to sort or filter, and there is no boolean query.   so, if no term either, then :matchall
        url += "?q=matchall"
        url += "&q.parser=structured"
      else
        url += "?q=#{CGI.escape(term.to_s)}"
      end
      gq.each do |arg,value|
        # aws does not like if if you repeat q.parser=structured, for example
        next if url.include?( "#{arg}=")
        url += "&#{arg}=#{CGI.escape(value)}"
      end unless gq.nil?
    else
      url += "?q=#{CGI.escape(term.to_s)}"
      url += "&bq=#{CGI.escape(bq)}" if options[:filter]
    end

    return_statement = api_version == '2013-01-01' ? 'return' : 'return-fields'
    url += "&size=#{page_size}"
    url += "&#{return_statement}=#{options[:return_fields].join ','}" if options[:return_fields]

    if options[:page]
      start = (options[:page].to_i - 1) * page_size
      url << "&start=#{start}"
    end

    if options[:rank]
      rank = normalize_rank(options[:rank])
      rank_or_sort = api_version == '2013-01-01' ? 'sort' : 'rank'
      url << "&#{rank_or_sort}=#{CGI.escape(rank)}"
    end

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
      # skip fields that do not have a specified value, so that the AWS Cloudsearch default value will kick in
      fields.delete( k) if fields[k].nil?
    end

    query["fields"] = fields
    query
  end

  def remove_item_query(id)
    { "type" => "delete", "id" => id.to_s, "version" => Time.now.to_i }
  end

  protected

  def convert_date_or_time(obj)
    return obj unless [Time, Date, DateTime].include?(obj.class)
    obj.to_time.to_i
  end

  # Private: Builds the boolean query from a passed hash
  #
  #     terms - a hash of the search query. %w(and or not) are reserved hash keys
  #             that build the logic of the query
  def boolean_query(terms = {})
    reduce = lambda { |hash|
      hash.reduce("") do |memo, (key, value)|
        if %w(and or not).include?(key.to_s) && value.is_a?(Hash)
          sub_query = reduce.call(value)
          memo += " (#{key}#{sub_query})" unless sub_query.empty?
        else
          sub_query = normalize_sub_query(key,value)
          memo += " #{sub_query}" unless sub_query.nil?
        end
        memo
      end
    }
    reduce.call(terms)
  end

  def normalize_sub_query(key,value)
    if value.is_a?(Array)
      case value.count
      when 0
        return nil
      when 1
        return normalize_sub_query( key, value.first)
      else
        # implicit OR of several values
        sub_queries = value.reduce('') do |memo,v|
          sub_query = normalize_sub_query( key, v)
          memo += " #{sub_query}" unless sub_query.nil?
          memo
        end
        return sub_queries.empty? ? nil : "(or #{sub_queries})"
      end
    elsif value.is_a?(Range)
      return normalize_range_query(key,value)
    elsif value.is_a?(Integer)
      return normalize_integer_query(key,value)
    else
      return value.to_s.empty? ? nil : normalize_term_query(key,value)
    end
  end

  def normalize_integer_query(field,value)
    if api_version == '2013-01-01'
      "(term field=#{field} #{value})"
    else
      "#{field}:#{value}"
    end
  end

  def normalize_term_query(field,value)
    if api_version == '2013-01-01'
      "(term field=#{field} '#{value}')"
    else
      "#{field}:#{value}"
    end
  end

  def normalize_range_query(field,range)
    if api_version == '2013-01-01'
      "(range field=#{field} #{normalize_range_begin(range)},#{normalize_range_end(range)})"
    else
      "#{field}:#{normalize_range_begin(range)}..#{normalize_range_end(range)}"
    end
  end

  def normalize_range_begin(range)
    if range.begin.nil? || (range.begin.is_a?( Numeric) && range.begin.to_f.infinite?)
      # lower end of range is open
      return api_version == '2013-01-01' ? '{' : ''
    else
      # lower end of range is fixed
      return api_version == '2013-01-01' ? "[#{normalize_range_value(range.begin)}" : "#{normalize_range_value(range.begin)}"
    end
  end

  def normalize_range_end(range)
    if range.end.nil? || (range.end.is_a?( Numeric) && range.end.to_f.infinite?)
      # upper end of range is open
      return api_version == '2013-01-01' ? '}' : ''
    else
      # upper end of range is fixed
      return api_version == '2013-01-01' ? "#{normalize_range_value(range.end)}#{range.exclude_end? ? '}' : ']'}" : "#{normalize_range_value(range.end)}"
    end    
  end

  def normalize_range_value(value)
    if value.is_a?( Date)
      # '2013-01-01T00:00:00Z'
      "'#{value.strftime('%FT%TZ')}'"
    else
      value.to_s
    end
  end

  # Private: Builds the geographic query from a passed hash
  #   options - a hash of data required to build the geo query
  #
  #   Use case #1:   Just sort by distance from a given point...
  #   {
  #     field:     :location
  #     latitude:  43.7,
  #     longitude: -105.2
  #   }
  #   shorthand version -- {location: [43.7, -105.2]}
  #
  #   Use case #2:   If radius is specified, then determine the area by center and radius (default unit is :km).   and, optionally, sort if requested
  #   {
  #     field:     :location
  #     latitude:  43.7,
  #     longitude: -105.2
  #     radius:    10
  #     sort:      true
  #   }
  #   shorthand version -- {location: [43.7, -105.2], radius: 10, sort: true}
  #
  #   Use case #3:   If a bounding box is given, then just use what is given. (and, sort, if requested)
  #   {
  #     field:     :location
  #     latitude:  (43.7...44.2)           # range: bottom to top
  #     longitude: (-105.2...-104.8)       # range: left to right
  #   }
  #   long version -- {field: :location, top: 44.2, right: -104.8, bottom: 43.7, left: -105.2}
  #   shorthand version -- {location: {lat: (43.7...44.2), lng: (-105.2...-104.8)}}
  #
  def geo_query(options = {})
    field     = nil
    latitude  = nil
    longitude = nil
    radius    = nil
    unit      = :kilometers
    top       = nil
    right     = nil
    bottom    = nil
    left      = nil
    sort      = nil

    options.each do |key,value|
      case key.to_sym
      when :field
        field = value.to_s
      when :lat, :latitude
        if value.is_a?( Range)
          bottom = value.begin.to_f
          top    = value.end.to_f
        elsif value.is_a?( Numeric)
          latitude = value.to_f
        end
      when :lng, :long, :longitude
        if value.is_a?( Range)
          left  = value.begin.to_f
          right = value.end.to_f
        elsif value.is_a?( Numeric)
          longitude = value.to_f
        end
      when :radius
        radius = value
      when :sort
        sort = value
      when :unit
        unit = value.to_sym
      else
        # key is not a known keyword -- probably shorthand -- field: <value>
        if value.is_a?( Array) && value.length == 2
          # shorthand -- field: [lat, lng]
          field     = key.to_s
          latitude  = value[0]
          longitude = value[1]
        elsif value.is_a?( Hash)
          # shorthand -- field: {latitude: <latitude-exp>, longitude: <longitude-exp>}, or field: {top: <top>, right: <right>, bottom: <bottom>, left: <left>}
          field = key.to_s
          latitude_exp  = value[:latitude] || value[:lat]
          longitude_exp = value[:longitude] || value[:long] || value[:lng]
          if latitude_exp && longitude_exp
            if latitude_exp.is_a?( Range)
              bottom = latitude_exp.begin.to_f
              top    = latitude_exp.end.to_f
            elsif latitude_exp.is_a?( Numeric)
              latitude = latitude_exp.to_f
            end
            if longitude_exp.is_a?( Range)
              left  = longitude_exp.begin.to_f
              right = longitude_exp.end.to_f
            elsif longitude_exp.is_a?( Numeric)
              longitude = longitude_exp.to_f
            end
          end
          # anything that is specified explicitly, wins
          top    ||= value[:top]
          right  ||= value[:right]
          bottom ||= value[:bottom]
          lef    ||= value[:bottom]
        end
      end
    end

    # require basic info (NB: should we throw exception? if something is missing?    should we do more type / error checking?)
    return nil unless field && ((top && right && bottom && left) || (latitude && longitude))

    gq = {}

    if top && right && bottom && left
      # full bounding box is specified
      gq['fq'] = "#{field}:['#{top},#{left}','#{bottom},#{right}']"    # range query on the specified latlon field
      gq['q.parser'] = 'structured'
      if sort
        # when sorting is enabled, we need to sort from the center (unless lat/long was given separately in options)
        latitude ||= ( top + bottom) / 2.0
        longitude ||= ( left + right) / 2.0
      end
    elsif radius && radius.kind_of?( Numeric)
      # radius is given convert to kilometers (the default)
      case unit
      when :degree, :degrees
        # the distance between longitudinal arcs decreases as latitude approaches the poles
        radius = ( radius * Asari::Geography.meters_per_degree_of_longitude( latitude)) / 1000.0
      when :mile, :miles
        # kilometers per mile
        radius *= 1.609344
      when :meters, :meter
        # convert to kilometers
        radius /= 1000.0
      else
        # when :kilometers, :kilometer, :km, :kms
        # nothing to do - this is the default unit
      end

      # ok - we have our radius in km.   compute the bounding box 
      box = Asari::Geography.coordinate_box( lat: latitude, lng: longitude, meters: (radius * 1000).to_i)

      # coordinate box gives us Lower Left and Upper Right...
      lower_left  = Asari::Geography.int_to_degrees( lat: box[:lat].begin, lng: box[:lng].begin)
      upper_right = Asari::Geography.int_to_degrees( lat: box[:lat].end,   lng: box[:lng].end)

      # but Cloudsearch wants Upper Left and Lower Right
      upper_left  = {lat: upper_right[:lat], lng: lower_left[:lng]}
      lower_right = {lat: lower_left[:lat],  lng: upper_right[:lng]}

      gq['fq'] = "#{field}:['#{upper_left[:lat]},#{upper_left[:lng]}','#{lower_right[:lat]},#{lower_right[:lng]}']"    # range query on the specified latlon field
      gq['q.parser'] = 'structured'
    else
      # no radius specified, sort based on distance from the given lat/lng
      sort = true if sort.nil?
    end

    if sort
      gq['expr.distance'] = "haversin(#{latitude},#{longitude},#{field}.latitude,#{field}.longitude)"
      gq['sort'] = 'distance asc'
    end

    gq
  end

  # sorting/ranking parameter

  def normalize_rank(rank)
    rank = Array(rank)
    rank << :asc if rank.size < 2
    
    if api_version == '2013-01-01'
      "#{rank[0]} #{rank[1]}"
    else
      rank[1] == :desc ? "-#{rank[0]}" : rank[0]
    end
  end

end

Asari.mode = :sandbox # default to sandbox
