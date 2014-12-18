module Parsers
  module Cv
    class PersonAddress
      include Namespaces

      def initialize(node)
        @xml = node
      end

      def address_1
        @address_1 ||= Maybe.new(@xml.at_xpath("cv:address_line_1",namespaces)).content.strip.value
      end

      def address_2
        @address_2 ||= Maybe.new(@xml.at_xpath("cv:address_line_2",namespaces)).content.strip.value
      end

      def address_3
        @address_3 ||= Maybe.new(@xml.at_xpath("cv:address_line_3",namespaces)).content.strip.value
      end

      def address_type
        @address_type ||= Maybe.new(@xml.at_xpath("cv:type",namespaces)).content.split("#").last.value
      end

      def city
        @city ||= Maybe.new(@xml.at_xpath("cv:location_city_name",namespaces)).content.strip.value
      end

      def zip
        @zip ||= Maybe.new(@xml.at_xpath("cv:postal_code",namespaces)).content.strip.value
      end

      def state
        @state ||= Maybe.new(@xml.at_xpath("cv:location_state_code",namespaces)).content.strip.upcase.value
      end

      def to_hash
        {
          :address_type => address_type,
          :address_1 => address_1,
          :address_2 => address_2,
          :address_3 => address_3,
          :city => city,
          :state => state,
          :zip => zip
        }
      end
    end
  end
end
