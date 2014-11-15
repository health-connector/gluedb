module Parsers
  module Cv
    class PolicyIndividual
      include Namespaces

      def initialize(node)
        @xml = node
      end

      def to_hash
        {
        }
      end
    end
  end
end
