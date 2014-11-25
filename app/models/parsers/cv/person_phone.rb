module Parsers
  module Cv
    class PersonPhone
      include Namespaces

      def initialize(node)
        @xml = node
      end

      def phone_type
        @phone_type ||= Maybe.new(@xml.at_xpath("cv:type", namespaces)).content.split("#").last.value
      end

      def phone_number
        @phone_number ||= Maybe.new(@xml.at_xpath("cv:full_phone_number", namespaces)).content.strip.value
      end

      def to_hash
        {
          :phone_type => phone_type,
          :phone_number => phone_number
        }
      end
    end
  end
end
