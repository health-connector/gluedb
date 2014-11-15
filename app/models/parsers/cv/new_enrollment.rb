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

      def individuals
        @individuals ||= extract_unique_people.map do |p_node|
           PolicyIndividual.new(p_node)
        end
      end

      def extract_unique_people
        people = []
        people_ids = []
        @xml.xpath("//cv:policy/cv:enrollees/cv:enrollee", namespaces).each do |p_node|
          member_id = Maybe.new(p_node.at_xpath("cv:member/cv:id/cv:id", namespaces)).content.split("#").last.value
          unless member_id.blank?
            unless people_ids.include?(member_id)
              people_ids << member_id
              people << p_node
            end
          end
        end
        people
      end

      def to_hash
        { 
          :policies => policies.map(&:to_hash),
          :individuals => individuals.map(&:to_hash)
        }
      end
    end
  end
end
