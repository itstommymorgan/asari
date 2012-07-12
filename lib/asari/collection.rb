class Asari
  class Collection < BasicObject
    attr_reader :current_page
    attr_reader :page_size
    attr_reader :total_entries
    attr_reader :total_pages

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
      @total_pages = (@total_entries / @page_size) + 1

      start = resp["hits"]["start"]
      @current_page = (start / page_size) + 1

      @data = resp["hits"]["hit"].map { |h| h["id"] }
    end

    def offset
      (@current_page - 1) * @page_size
    end

    def replace(array)
      @data = array

      self
    end

    def method_missing(method, *args, &block)
      @data.send(method, *args, &block)
    end
  end
end
