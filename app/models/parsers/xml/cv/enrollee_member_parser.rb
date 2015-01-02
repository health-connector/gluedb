module Parsers::Xml::Cv

  class EnrolleeMemberParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'member'
    namespace 'cv'

    element :id, String, tag: "id/cv:id"
    element :application_group_id, String, tag: "application_group_id/cv:id"
    element :tax_household_id, String, tag: "tax_household_id/cv:id"
    has_one :person, Parsers::Xml::Cv::PersonParser, tag: 'person'
    has_one :benefit, Parsers::Xml::Cv::EnrolleeBenefitParser, tag: 'benefit'

    def to_hash
      result = {
          id:id,
          hbx_member_id:id,
          application_group_id:application_group_id,
          tax_household_id:tax_household_id,
          person:person.to_hash,
      }

      result[:benefit] = benefit.to_hash if benefit

      result
    end
  end
end