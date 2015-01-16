module Parsers
  module Cv
    class Enrollee
      include Namespaces

      def initialize(doc)
        @xml = doc
      end

      def m_id
        @m_id ||= Maybe.new(@xml.at_xpath("cv:member/cv:id/cv:id",namespaces)).content.split("#").last.value
      end

      def subscriber?
        @is_subscriber = "true" == Maybe.new(@xml.at_xpath("cv:is_subscriber",namespaces)).content.strip.downcase.value
      end

      def rel_code
        return "self" if subscriber?
        @rel_code ||= Maybe.new(@xml.at_xpath("cv:member/cv:person_relationships/cv:person_relationship/cv:relationship_uri",namespaces)).content.split("#").last.value
      end

      def pre_amt
        @pre_amt ||= Maybe.new(@xml.at_xpath("cv:benefit/cv:premium_amount",namespaces)).content.strip.value
      end

      def coverage_start
        @coverage_start ||= Maybe.new(@xml.at_xpath("cv:benefit/cv:begin_date",namespaces)).content.strip.value
      end

      def member_dob
        @member_dob ||= Maybe.new(@xml.at_xpath("cv:member/cv:person_demographics/cv:birth_date", namespaces)).content.strip.fmap { |val| Date.parse(val) rescue nil }.value
      end

      def to_hash
        { 
          :m_id => m_id,
          :rel_code => rel_code,
          :ben_stat => "active",
          :emp_stat => "active",
          :pre_amt => pre_amt,
          :coverage_start => coverage_start,
          :member => { :dob => member_dob }
        }
      end
    end
  end
end
