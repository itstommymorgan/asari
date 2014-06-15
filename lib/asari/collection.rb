class Asari
  # Public: The Asari::Collection object represents a page of data returned from
  # CloudSearch. It very closely delegates to an array containing the intended
  # results, but provides a few extra methods containing metadata about the
  # current pagination state: current_page, page_size, total_entries, offset, and
  # total_pages.
  #
  # Asari::Collection is compatible with will_paginate collections, and the two
  # can be used interchangeably for the purposes of pagination.
  #
  class Collection < BasicObject
    attr_reader :current_page
    attr_reader :page_size
    attr_reader :total_entries
    attr_reader :total_pages

    # Internal: method for returning a sandbox-friendly empty search result.
    #
    def self.sandbox_fake
      Collection.new(::OpenStruct.new(:parsed_response => {"hits" => { "found" => 0, "start" => 0, "hit" => []}}), 10)
    end

    # Internal: This object should really only ever be instantiated from within
    # Asari code. The Asari Collection knows how to build itself from an
    # HTTParty::Response object representing a search query result from
    # CloudSearch.
    #
    # We also have to pass the page size in directly, because the CloudSearch
    # response doesn't have any data about page size. It's cool, though. I
    # guess.
    #
    def initialize(httparty_response, page_size)
      resp = httparty_response.parsed_response
      @total_entries = resp["hits"]["found"]
      @page_size = page_size

      complete_pages = (@total_entries / @page_size)
      @total_pages = (@total_entries % @page_size > 0) ? complete_pages + 1 : complete_pages
      # There's always one page, even for no results
      @total_pages = 1 if @total_pages == 0

      start = resp["hits"]["start"]
      @current_page = (start / page_size) + 1
      if resp["hits"]["hit"].first && resp["hits"]["hit"].first["data"]
        @data = {}
        resp["hits"]["hit"].each { |hit|  @data[hit["id"]] = hit["data"]}
      elsif resp["hits"]["hit"].first && resp["hits"]["hit"].first["fields"]
        @data = {}
        resp["hits"]["hit"].each { |hit|  @data[hit["id"]] = hit["fields"]}
      else
        @data = resp["hits"]["hit"].map { |hit| hit["id"] }
      end
    end

    def offset
      (@current_page - 1) * @page_size
    end

    # Public: replace the current data collection with a new data collection,
    # without losing pagination information. Useful for mapping results, etc.
    #
    # Examples:
    #
    #   results = @asari.find("test") #=> ["1", "3", "10", "28"]
    #   results.replace(results.map { |id| User.find(id)}) #=> [<User...>,<User...>,<User...>]
    #
    # Returns: self. #replace is a chainable method.
    #
    def replace(array)
      @data = array

      self
    end

    def class
      ::Asari::Collection
    end

    def method_missing(method, *args, &block)
      @data.send(method, *args, &block)
    end
  end
end
