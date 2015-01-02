module Parsers::Xml::Cv

  class EnrolleeBenefitParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'benefit'
    namespace 'cv'

    element :premium_amount, String, tag: "premium_amount"
    element :begin_date, String, tag: "begin_date"
    element :end_date, String, tag: "end_date"
    element :carrier_assigned_policy_id, String, tag: "carrier_assigned_policy_id"
    element :carrier_assigned_enrollee_id, String, tag: "carrier_assigned_enrollee_id"
    element :coverage_level, String, xpaths: "cv:coverage_level"

    def to_hash
      {
          premium_amount:premium_amount,
          begin_date:begin_date,
          end_date:end_date,
          carrier_assigned_policy_id:carrier_assigned_policy_id,
          carrier_assigned_enrollee_id:carrier_assigned_enrollee_id,
          coverage_level:coverage_level
      }
    end
  end
end