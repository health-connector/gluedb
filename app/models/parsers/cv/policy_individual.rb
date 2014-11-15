module Parsers
  module Cv
    class PolicyIndividual
      include Namespaces

      def initialize(node)
        @xml = node
      end

      def gender
        @gender ||= Maybe.new(@xml.at_xpath("cv:member/cv:person_demographics/cv:sex",namespaces)).content.split("#").last.value
      end

      def ssn
        @ssn ||= Maybe.new(@xml.at_xpath("cv:member/cv:person_demographics/cv:ssn",namespaces)).content.split("#").last.value
      end

      def dob
        @dob ||= Maybe.new(@xml.at_xpath("cv:member/cv:person_demographics/cv:birth_date",namespaces)).content.split("#").last.value
      end

      def hbx_member_id
        @hbx_member_id ||= Maybe.new(@xml.at_xpath("cv:member/cv:id/cv:id",namespaces)).content.split("#").last.value
      end

      def to_hash
        {
          :name_pfx => "a",
          :name_first=> "a",
          :name_middle => "a",
          :name_first => "a",
          :name_sfx => "a",
          :dob => dob,
          :ssn => ssn,
          :hbx_member_id => hbx_member_id,
          :gender => gender
        }
      end
    end
  end
end
