class Asari
  # Public: This module contains helper methods that serialize and deserialize
  # latitudes and longitudes to store on Cloudsearch. For more information, see:
  #
  # http://docs.aws.amazon.com/cloudsearch/latest/developerguide/geosearch.html
  #
  module Geography
    EARTH_RADIUS = 6367444
    METERS_PER_DEGREE_OF_LATITUDE = 111133

    class << self

      # Public: Converts coordinates to unsigned integers that store up to three
      # place values.
      #
      #     options - the options hash requires:
      #       lat: a Float
      #       lng: a Float
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
      #       lat: an Integer
      #       lng: an Integer
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

      # Public: Calculates a range of integers to search within from a point
      # and a distance in meters. This is used to search a certain distance from
      # a point in Cloudsearch.
      #
      #     options - the options hash requires:
      #       meters: an Integer
      #       lat: a Float
      #       lng: a Float
      #
      # Examples:
      #
      #     Asari::GeographyConversion.coordinate_box(lat: 25062714160, lng: 1112993466, miles: 5)
      #     #=> {:lat=>25062714160, :lng=>1112993466}
      #
      # Returns: a Hash containing :lat and :lng keys with Range values
      #
      def coordinate_box(options)
        latitude = options[:lat]
        longitude = options[:lng]

        earth_radius_at_latitude = EARTH_RADIUS * Math.cos(latitude * ( Math::PI / 180 ))

        change_in_latitude = ( options[:meters].to_f / EARTH_RADIUS ) * ( 180 / Math::PI )
        change_in_longitude = ( options[:meters].to_f / earth_radius_at_latitude ) * ( 180 / Math::PI )

        bottom = latitude_to_int(latitude - change_in_latitude)
        top = latitude_to_int(latitude + change_in_latitude)

        left = longitude_to_int(longitude - change_in_longitude, latitude)
        right = longitude_to_int(longitude + change_in_longitude, latitude)

        { lat: (bottom.round..top.round), lng: (left.round..right.round) }
      end


      private
      def latitude_to_int(degrees)
        ((degrees + 180) * METERS_PER_DEGREE_OF_LATITUDE * 100).round
      end

      def latitude_to_degrees(int)
        ((int / METERS_PER_DEGREE_OF_LATITUDE / 100.0) - 180).round(3)
      end

      def longitude_to_int(degrees, latitude)
        meters = meters_per_degree_of_longitude(latitude)
        ((degrees + 180) * meters * 100).round
      end

      def longitude_to_degrees(int, latitude_in_degrees)
        meters = meters_per_degree_of_longitude(latitude_in_degrees)
        ((int / meters / 100.0) - 180).round(3)
      end

      def meters_per_degree_of_longitude(latitude)
        METERS_PER_DEGREE_OF_LATITUDE * Math.cos(latitude)
      end
    end
  end
end
