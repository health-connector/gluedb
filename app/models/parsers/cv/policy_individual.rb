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

      def name_first
        @name_first ||= Maybe.new(@xml.at_xpath("cv:member/cv:person/cv:person_name/cv:person_given_name",namespaces)).content.value
      end

      def name_last
        @name_last ||= Maybe.new(@xml.at_xpath("cv:member/cv:person/cv:person_name/cv:person_surname",namespaces)).content.value
      end

      def name_middle
        @name_middle ||= Maybe.new(@xml.at_xpath("cv:member/cv:person/cv:person_name/cv:person_middle_name",namespaces)).content.value
      end

      def name_pfx
        @name_pfx ||= Maybe.new(@xml.at_xpath("cv:member/cv:person/cv:person_name/cv:person_name_prefix_text",namespaces)).content.value
      end

      def name_sfx
        @name_sfx ||= Maybe.new(@xml.at_xpath("cv:member/cv:person/cv:person_name/cv:person_name_suffix_text",namespaces)).content.value
      end

      def addresses
        @addresses ||= @xml.xpath("cv:member/cv:person/cv:addresses/cv:address", namespaces).map do |node|
          ::Parsers::Cv::PersonAddress.new(node)
        end
      end

      def emails
        @emails ||= @xml.xpath("cv:member/cv:person/cv:emails/cv:email", namespaces).map do |node|
          ::Parsers::Cv::PersonEmail.new(node)
        end
      end

      def phones
        @phones ||= @xml.xpath("cv:member/cv:person/cv:phones/cv:phone", namespaces).map do |node|
          ::Parsers::Cv::PersonPhone.new(node)
        end
      end

      def to_hash
        {
          :name_pfx => name_pfx,
          :name_first=> name_first,
          :name_middle => name_middle,
          :name_last => name_last,
          :name_sfx => name_sfx,
          :dob => dob,
          :ssn => ssn,
          :hbx_member_id => hbx_member_id,
          :gender => gender,
          :addresses => addresses.map(&:to_hash),
          :emails => emails.map(&:to_hash),
          :phones => phones.map(&:to_hash)
        }
      end
    end
  end
end
