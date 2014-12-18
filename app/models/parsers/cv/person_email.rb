module Parsers
  module Cv
    class PersonEmail
      include Namespaces

      def initialize(node)
        @xml = node
      end

      def email_type
        @email_type ||= Maybe.new(@xml.at_xpath("cv:type", namespaces)).content.split("#").last.value
      end

      def email_address
        @email_address ||= Maybe.new(@xml.at_xpath("cv:email_address", namespaces)).content.strip.value
      end

      def to_hash
        {
          :email_type => email_type,
          :email_address => email_address
        }
      end
    end
  end
end
