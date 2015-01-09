module Parsers::Xml::Cv
  class EligibilityDeterminationParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'eligibility_determination'
    namespace 'cv'

    element :id, String, tag: 'id/cv:id'
    element :household_state, String, tag: "household_state"
    element :maximum_aptc, String, tag: "maximum_aptc"
    element :csr_percent, Integer, tag: "csr_percent", lambda: ->(value) {
        value.to_i
    }
    element :determination_date, String, tag: "determination_date"
    element :benchmark_plan_id, String, tag: 'benchmark_plan_id/cv:id/cv:id'

    def to_hash
      response = {
          id: id,
          household_state: household_state,
          maximum_aptc: maximum_aptc,
          csr_percent_as_integer: csr_percent,
          determination_date: determination_date,
          benchmark_plan_id: benchmark_plan_id
      }

      response[:household_state] = response[:household_state].split('#').last if response[:household_state]

      response
    end

  end
end