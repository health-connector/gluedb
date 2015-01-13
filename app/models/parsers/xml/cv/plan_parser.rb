module Parsers::Xml::Cv
  class PlanParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'plan'
    namespace 'cv'

    element :coverage_type, String, tag: "coverage_type"
    element :name, String, tag: "name"

  end
end