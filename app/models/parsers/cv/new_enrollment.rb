module Parsers
  module Cv
    class NewEnrollment
      include Namespaces

      def initialize(doc)
        @xml = doc
      end

      def policies
        @policies ||= @xml.xpath("//cv:policy", namespaces).map do |node|
          NewPolicy.new(node)
        end
      end

      def to_hash
        { 
          :policies => policies.map(&:to_hash),
          :individuals => []
        }
      end
    end
  end
end
