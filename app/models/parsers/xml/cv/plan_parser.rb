module Parsers::Xml::Cv
  class PlanParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'plan'
    namespace 'cv'

    element :id, String, tag: "id/cv:id"
    element :coverage_type, String, tag: "coverage_type"
    element :name, String, tag: "name"
    element :plan_year, String, tag: "plan_year"
    element :is_dental_only, String, tag: "is_dental_only"

    def to_hash
      {
          id:id,
          coverage_type:coverage_type,
          name:name,
          plan_year:plan_year,
          is_dental_only:is_dental_only
      }
    end
  end
end