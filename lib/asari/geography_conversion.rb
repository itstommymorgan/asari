class Asari
  # Public: This module contains helper methods that serialize and deserialize
  # latitudes and longitudes to store on Cloudsearch. For more information, see:
  #
  # http://docs.aws.amazon.com/cloudsearch/latest/developerguide/geosearch.html
  #
  module GeographyConversion
    EARTH_RADIUS = 6367444
    METERS_PER_DEGREE_OF_LATITUDE = 111133 # (2π * EARTH_RADIUS) / 360
    class << self

      # Public: Converts coordinates to unsigned integers that store up to three
      # place values.
      #
      #     options - the options hash requires:
      #       lat - a Float
      #       lng - a Float
      #
      # Examples:
      #
      #     Asari::GeographyConversion.degrees_to_int(45.52, 122.6819)
      #     #=> {:lat=>25062714160, :lng=>1112993466}
      #
      # Returns: a Hash containing :lat and :lng keys with Integer values
      #
      def degrees_to_int(options)
        latitude = latitude_to_int(options[:lat])
        longitude = longitude_to_int(options[:lng], options[:lat])
        { lat: latitude, lng: longitude }
      end

      # Public: Converts unsigned integers created with `degrees_to_int` back to
      # the standard Geographic Coordinate System.
      #
      #     options - the options hash requires:
      #       lat - an Integer
      #       lng - an Integer
      #
      # Examples:
      #
      #     Asari::GeographyConversion.int_to_degrees(lat: 25062714160, lng: 1112993466)
      #     #=> {:lat=>45.52, :lng=>-122.682}
      #
      # Returns: a Hash containing :lat and :lng keys with Float values
      #
      def int_to_degrees(options)
        latitude = latitude_to_degrees(options[:lat])
        longitude = longitude_to_degrees(options[:lng], latitude)
        { lat: latitude, lng: longitude }
      end

      private
      def latitude_to_int(degrees)
        ((degrees + 180) * METERS_PER_DEGREE_OF_LATITUDE * 1000).round
      end

      def latitude_to_degrees(int)
        ((int / METERS_PER_DEGREE_OF_LATITUDE / 1000.0) - 180).round(3)
      end

      def longitude_to_int(degrees, latitude)
        meters_per_degree_of_longitude = METERS_PER_DEGREE_OF_LATITUDE * Math.cos(latitude)
        ((degrees + 180) * meters_per_degree_of_longitude * 1000).round
      end

      def longitude_to_degrees(int, latitude_in_degrees)
        meters_per_degree_of_longitude = METERS_PER_DEGREE_OF_LATITUDE * Math.cos(latitude_in_degrees)
        ((int / meters_per_degree_of_longitude / 1000.0) - 180).round(3)
      end
    end
  end
end